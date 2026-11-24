import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/current_user.dart';

SupabaseClient get _client => Supabase.instance.client;

/// The user's plan, read from `user_entitlements` (server-written only; see migration 004).
/// The app never grants Pro itself — it only displays what the database says.
class Entitlement {
  final String planType; // free | pro
  final String subscriptionStatus; // active | inactive | expired
  final DateTime? proActivatedAt;
  final DateTime? proExpiresAt;
  final String paymentStatus; // none | pending | paid | failed
  final int freePostsUsed;
  final DateTime? planChosenAt;

  const Entitlement({
    this.planType = 'free',
    this.subscriptionStatus = 'active',
    this.proActivatedAt,
    this.proExpiresAt,
    this.paymentStatus = 'none',
    this.freePostsUsed = 0,
    this.planChosenAt,
  });

  static const free = Entitlement();

  bool get isPro =>
      planType == 'pro' &&
      subscriptionStatus == 'active' &&
      (proExpiresAt == null || proExpiresAt!.isAfter(DateTime.now()));

  /// The id used for labels and `plan_features` lookups.
  String get planId => isPro ? 'pro' : 'free';

  bool get hasChosenPlan => planChosenAt != null || isPro;

  factory Entitlement.fromJson(Map<String, dynamic> j) => Entitlement(
        planType: j['plan_type'] ?? 'free',
        subscriptionStatus: j['subscription_status'] ?? 'active',
        proActivatedAt: j['pro_activated_at'] != null ? DateTime.parse(j['pro_activated_at']) : null,
        proExpiresAt: j['pro_expires_at'] != null ? DateTime.parse(j['pro_expires_at']) : null,
        paymentStatus: j['payment_status'] ?? 'none',
        freePostsUsed: j['free_posts_used'] ?? 0,
        planChosenAt: j['plan_chosen_at'] != null ? DateTime.parse(j['plan_chosen_at']) : null,
      );
}

/// Live entitlement (Realtime), so the plan badge updates the moment a payment is applied.
final entitlementProvider = StreamProvider<Entitlement>((ref) {
  ref.watch(currentUserIdProvider);
  final uid = _client.auth.currentUser?.id;
  if (uid == null) return Stream.value(Entitlement.free);
  return _client
      .from('user_entitlements')
      .stream(primaryKey: ['user_id'])
      .eq('user_id', uid)
      .map((rows) => rows.isEmpty ? Entitlement.free : Entitlement.fromJson(rows.first));
});

/// One-shot read for non-widget code (limits, gates).
Future<Entitlement> fetchEntitlement() async {
  final uid = _client.auth.currentUser?.id;
  if (uid == null) return Entitlement.free;
  final row = await _client.from('user_entitlements').select().eq('user_id', uid).maybeSingle();
  return row == null ? Entitlement.free : Entitlement.fromJson(row);
}

/// A plan definition. Prices are FCFA, read from the `plans` table.
class Plan {
  final String id;
  final int priceFcfa;
  final int? durationDays; // null = one-time / lifetime
  final Map<String, PlanFeature> features;

  const Plan({required this.id, required this.priceFcfa, this.durationDays, this.features = const {}});
}

class PlanFeature {
  final bool enabled;
  final int? limit;
  const PlanFeature(this.enabled, this.limit);
}

/// Used only if the config tables can't be read (offline); the server enforces the real rules.
const kDefaultPlans = [Plan(id: 'free', priceFcfa: 0), Plan(id: 'pro', priceFcfa: 100)];

final plansProvider = FutureProvider<List<Plan>>((ref) async {
  try {
    final rows = await _client.from('plans').select().eq('is_active', true).order('sort_order');
    final feats = await _client.from('plan_features').select();
    final byPlan = <String, Map<String, PlanFeature>>{};
    for (final f in feats as List) {
      byPlan.putIfAbsent(f['plan_id'], () => {})[f['feature_key']] =
          PlanFeature(f['enabled'] == true, f['limit_value'] as int?);
    }
    final plans = (rows as List)
        .map((r) => Plan(
              id: r['id'],
              priceFcfa: r['price_fcfa'],
              durationDays: r['duration_days'],
              features: byPlan[r['id']] ?? const {},
            ))
        .toList();
    return plans.isEmpty ? kDefaultPlans : plans;
  } catch (_) {
    return kDefaultPlans;
  }
});

final proPriceProvider = Provider<int>((ref) {
  final plans = ref.watch(plansProvider).whenOrNull(data: (p) => p) ?? kDefaultPlans;
  return plans.where((p) => p.id == 'pro').firstOrNull?.priceFcfa ?? 100;
});

/// A mobile-money payment recorded by the payments Edge Function.
class PaymentTransaction {
  final String id;
  final String reference;
  final String type; // PRO_UPGRADE | AGREEMENT_GENERATION
  final int amountFcfa;
  final String provider; // MTN | ORANGE
  final String phone;
  final String status; // pending | success | failed | cancelled
  final String? targetId;
  final String? message;
  final DateTime createdAt;

  /// MeSomb's transaction id (shown on receipts).
  final String? providerTxId;
  final DateTime? completedAt;

  const PaymentTransaction({
    required this.id,
    required this.reference,
    required this.type,
    required this.amountFcfa,
    required this.provider,
    required this.phone,
    required this.status,
    this.targetId,
    this.message,
    required this.createdAt,
    this.providerTxId,
    this.completedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> j) => PaymentTransaction(
        id: j['id'],
        reference: j['reference'],
        type: j['type'],
        amountFcfa: j['amount_fcfa'],
        provider: j['provider'],
        phone: j['phone'],
        status: j['status'],
        targetId: j['target_id'],
        message: j['message'],
        createdAt: DateTime.parse(j['created_at']),
        providerTxId: j['provider_tx_id']?.toString(),
        completedAt: j['completed_at'] != null ? DateTime.parse(j['completed_at']) : null,
      );
}

final paymentHistoryProvider = FutureProvider<List<PaymentTransaction>>((ref) async {
  ref.watch(currentUserIdProvider);
  final uid = _client.auth.currentUser?.id;
  if (uid == null) return [];
  final rows = await _client
      .from('payment_transactions')
      .select()
      .eq('user_id', uid)
      .order('created_at', ascending: false)
      .limit(50);
  return (rows as List).map((e) => PaymentTransaction.fromJson(e)).toList();
});

/// One transaction by its SplitSure reference (RLS: own payments only).
Future<PaymentTransaction?> fetchPaymentTransaction(String reference) async {
  final row = await _client.from('payment_transactions').select().eq('reference', reference).maybeSingle();
  return row == null ? null : PaymentTransaction.fromJson(row);
}
