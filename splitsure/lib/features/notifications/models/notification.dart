import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/current_user.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';

SupabaseClient get _client => Supabase.instance.client;

class AppNotification {
  final String id;
  final String title;
  final String? body;
  final String type;
  final String? kind;
  final Map<String, dynamic> params;
  final bool isRead;
  final String? relatedId;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    this.body,
    required this.type,
    this.kind,
    this.params = const {},
    required this.isRead,
    this.relatedId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        type: json['type'] ?? 'general',
        kind: json['kind'],
        params: Map<String, dynamic>.from(json['params'] ?? {}),
        isRead: json['is_read'] ?? false,
        relatedId: json['related_id'],
        createdAt: DateTime.parse(json['created_at']),
      );

  /// Title and body in the user's language (falls back to the stored text).
  (String, String?) localized(AppLocalizations l10n) {
    String p(String k) => '${params[k] ?? ''}';
    return switch (kind) {
      'agreement_invited' => (l10n.notifInvitedTitle, l10n.notifInvitedBody(p('song'))),
      'agreement_new_version' => (l10n.notifNewVersionTitle, l10n.notifNewVersionBody(p('version'), p('song'))),
      'agreement_accepted' => (l10n.notifAcceptedTitle, l10n.notifAcceptedBody(p('name'), p('song'))),
      'agreement_changes_requested' => (l10n.notifChangesTitle, l10n.notifChangesBody(p('name'), p('song'))),
      'agreement_declined' => (l10n.notifDeclinedTitle, l10n.notifDeclinedBody(p('name'), p('song'))),
      'agreement_witness_invited' => (l10n.notifWitnessInvitedTitle, l10n.notifWitnessInvitedBody(p('song'))),
      'agreement_witness_confirmed' => (l10n.notifWitnessConfirmedTitle, l10n.notifWitnessConfirmedBody(p('name'), p('song'))),
      'agreement_witness_declined' => (l10n.notifWitnessDeclinedTitle, l10n.notifWitnessDeclinedBody(p('name'), p('song'))),
      'agreement_fully_accepted' => (l10n.notifFinalTitle, l10n.notifFinalBody(p('song'))),
      'campaign_completed' => (l10n.notifCampaignTitle, l10n.notifCampaignBody(p('campaign'))),
      'subscription_expiring' => (l10n.notifExpiringTitle, l10n.notifExpiringBody(formatDate(p('date')))),
      'subscription_expired' => (l10n.notifExpiredTitle, l10n.notifExpiredBody),
      'opportunity_recommended' => (l10n.notifOppRecommendedTitle, l10n.notifOppRecommendedBody(p('title'))),
      'application_received' => (l10n.notifAppReceivedTitle, l10n.notifAppReceivedBody(p('name'), p('title'))),
      'application_under_review' => (l10n.notifAppUnderReviewTitle, l10n.notifAppStatusBody(p('title'))),
      'application_shortlisted' => (l10n.notifAppShortlistedTitle, l10n.notifAppStatusBody(p('title'))),
      'application_accepted' => (l10n.notifAppAcceptedTitle, l10n.notifAppStatusBody(p('title'))),
      'application_rejected' => (l10n.notifAppRejectedTitle, l10n.notifAppRejectedBody(p('title'))),
      'workspace_created' => (l10n.notifWorkspaceTitle, l10n.notifWorkspaceBody(p('title'))),
      'member_added' => (l10n.notifMemberAddedTitle, l10n.notifWorkspaceBody(p('title'))),
      'terms_updated' => (l10n.notifTermsUpdatedTitle, l10n.notifTermsUpdatedBody(p('title'))),
      'payment_success' => (l10n.notifPaymentSuccessTitle, l10n.notifPaymentSuccessBody(p('amount'))),
      'payment_failed' => (l10n.notifPaymentFailedTitle, l10n.notifPaymentFailedBody(p('amount'))),
      'pro_activated' => (l10n.notifProActivatedTitle, l10n.notifProActivatedBody),
      _ => (title, body),
    };
  }
}

/// Reloads automatically when a notification row changes (Supabase Realtime).
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) async* {
  ref.watch(currentUserIdProvider);
  final user = _client.auth.currentUser;
  if (user == null) {
    yield [];
    return;
  }
  Future<List<AppNotification>> load() async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  yield await load();
  final channel = _client.channel('notifications:${user.id}');
  final controller = StreamController<void>();
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: user.id),
        callback: (_) => controller.add(null),
      )
      .subscribe();
  ref.onDispose(() {
    _client.removeChannel(channel);
    controller.close();
  });
  await for (final _ in controller.stream) {
    yield await load();
  }
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).whenOrNull(data: (list) => list.where((n) => !n.isRead).length) ?? 0;
});

Future<void> markAllRead() async {
  final user = _client.auth.currentUser;
  if (user == null) return;
  await _client.from('notifications').update({'is_read': true}).eq('user_id', user.id).eq('is_read', false);
}

Future<void> markNotificationRead(String id) async {
  await _client.from('notifications').update({'is_read': true}).eq('id', id);
}

// ── Notification preferences (stored on the profile; enforced server-side) ──

const kNotificationCategories = ['agreement', 'campaign', 'subscription'];

Future<Map<String, bool>> loadNotificationPrefs() async {
  final uid = _client.auth.currentUser?.id;
  if (uid == null) return {};
  try {
    final row = await _client.from('profiles').select('notification_prefs').eq('id', uid).maybeSingle();
    final m = Map<String, dynamic>.from(row?['notification_prefs'] ?? {});
    return {for (final c in kNotificationCategories) c: m[c] != false};
  } catch (_) {
    return {for (final c in kNotificationCategories) c: true};
  }
}

Future<void> saveNotificationPrefs(Map<String, bool> prefs) async {
  final uid = _client.auth.currentUser?.id;
  if (uid == null) return;
  await _client.from('profiles').update({'notification_prefs': prefs}).eq('id', uid);
}
