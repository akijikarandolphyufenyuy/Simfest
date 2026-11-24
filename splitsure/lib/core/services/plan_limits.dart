import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../localization/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../../features/subscription/models/subscription.dart';
import '../../features/subscription/screens/subscription_screen.dart';

/// Limits come from the admin-editable `plan_features` table, keyed by the
/// server-managed plan in `user_entitlements`. These checks are only for a
/// friendly UX: the database RLS policies enforce the same limits.
enum PlanLimit {
  agreements('max_agreements', 'agreements'),
  campaigns('max_campaigns', 'campaigns'),
  projects('max_projects', 'projects');

  final String featureKey;
  final String table;
  const PlanLimit(this.featureKey, this.table);
}

SupabaseClient get _client => Supabase.instance.client;

/// The user's current plan id: 'pro' or 'free'.
Future<String> currentPlanId() async => (await fetchEntitlement()).planId;

Future<PlanFeature?> _feature(String plan, String key) async {
  final f = await _client
      .from('plan_features')
      .select('enabled, limit_value')
      .eq('plan_id', plan)
      .eq('feature_key', key)
      .maybeSingle();
  return f == null ? null : PlanFeature(f['enabled'] == true, f['limit_value'] as int?);
}

/// Returns true when the user may create one more item; otherwise explains the
/// limit and offers the Pro upgrade.
Future<bool> checkPlanLimit(BuildContext context, PlanLimit limit) async {
  try {
    final plan = await currentPlanId();
    final feature = await _feature(plan, limit.featureKey);
    if (feature == null) return true;
    final max = feature.limit;
    if (feature.enabled && max == null) return true;
    if (feature.enabled) {
      final uid = _client.auth.currentUser!.id;
      final rows = await _client.from(limit.table).select('id').eq('user_id', uid);
      if ((rows as List).length < max!) return true;
    }
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      await showUpgradeDialog(context,
          body: limit == PlanLimit.agreements ? l10n.planAgreementLimitBody : l10n.planLimitReachedBody(max ?? 0));
    }
    return false;
  } catch (_) {
    return true; // the server still enforces the limit
  }
}

/// Whether a boolean feature (e.g. reach, promo_video) is enabled on the user's plan.
Future<bool> planAllows(String featureKey) async {
  try {
    final f = await _feature(await currentPlanId(), featureKey);
    return f == null || f.enabled;
  } catch (_) {
    return true;
  }
}

/// "This needs Pro" dialog with a direct upgrade button.
Future<void> showUpgradeDialog(BuildContext context, {String? title, required String body}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF5B301), size: 44),
      title: Text(title ?? l10n.planLimitReachedTitle, textAlign: TextAlign.center),
      content: Text(body, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.notNow)),
        Consumer(
          builder: (_, ref, __) => FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () {
              Navigator.pop(ctx);
              startProUpgrade(context, ref);
            },
            child: Text(l10n.upgradeToPro),
          ),
        ),
      ],
    ),
  );
}
