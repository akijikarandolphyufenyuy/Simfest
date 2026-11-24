import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../models/notification.dart';
import '../../protect/screens/agreement_detail_screen.dart';
import '../../reach/providers/campaigns_provider.dart';
import '../../reach/screens/campaign_detail_screen.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../hub/screens/opportunity_detail_screen.dart';
import '../../dealflow/screens/workspace_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  final VoidCallback? onBack;
  const NotificationsScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifications = ref.watch(notificationsProvider);

    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppSliverHeader(
              title: l10n.notifications,
              subtitle: l10n.unreadCount(unread),
              leading: const HeaderIcon(Icons.notifications_rounded),
              showBack: onBack != null,
              onBackOverride: onBack,
              actions: [
                if (unread > 0)
                  TextButton(
                    onPressed: () async {
                      await markAllRead();
                      ref.invalidate(notificationsProvider);
                    },
                    child: Text(l10n.markAllRead,
                        style: const TextStyle(color: AppColors.teal, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            ...notifications.when(
              loading: () => [
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.teal))),
              ],
              error: (e, _) => [SliverFillRemaining(child: Center(child: Text(l10n.errorWithDetails('$e'))))],
              data: (list) => list.isEmpty
                  ? [SliverFillRemaining(hasScrollBody: false, child: _empty(l10n))]
                  : [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                        sliver: SliverList.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => FadeSlideIn(
                            delay: stagger(i.clamp(0, 8), 45),
                            child: _NotificationTile(
                              notification: list[i],
                              onTap: () async {
                                final n = list[i];
                                if (!n.isRead) {
                                  await markNotificationRead(n.id);
                                  ref.invalidate(notificationsProvider);
                                }
                                if (!context.mounted || n.relatedId == null) return;
                                if (n.type == 'agreement') {
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => AgreementDetailScreen(agreementId: n.relatedId)));
                                } else if (n.type == 'campaign') {
                                  final c = await fetchCampaign(n.relatedId!);
                                  if (c != null && context.mounted) {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => CampaignDetailScreen(campaign: c)));
                                  }
                                } else if (n.type == 'subscription' || n.type == 'payment') {
                                  Navigator.push(
                                      context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                                } else if (n.type == 'opportunity') {
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => OpportunityDetailScreen(opportunityId: n.relatedId!)));
                                } else if (n.type == 'workspace') {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => WorkspaceScreen(workspaceId: n.relatedId!)));
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(AppLocalizations l10n) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: AppColors.deepNavy.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.notifications_none_outlined, size: 40, color: AppColors.deepNavy),
      ),
      const SizedBox(height: 20),
      Text(l10n.noNotificationsYet,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
      const SizedBox(height: 8),
      Text(l10n.noNotificationsHint,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 13), textAlign: TextAlign.center),
    ]),
  );
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  const _NotificationTile({required this.notification, required this.onTap});

  IconData get _icon => switch (notification.type) {
    'agreement' => Icons.shield_outlined,
    'campaign' => Icons.campaign_outlined,
    'subscription' => Icons.workspace_premium_outlined,
    _ => Icons.notifications_outlined,
  };

  Color get _color => switch (notification.type) {
    'agreement' => AppColors.deepNavy,
    'campaign' => AppColors.teal,
    'subscription' => Colors.orange,
    _ => AppColors.mutedText,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.white : AppColors.teal.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead ? AppColors.cardBorder : AppColors.teal.withValues(alpha: 0.3),
          ),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(notification.localized(AppLocalizations.of(context)!).$1,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                  fontSize: 14, color: AppColors.deepNavy,
                )),
            if (notification.localized(AppLocalizations.of(context)!).$2 != null) ...[
              const SizedBox(height: 2),
              Text(notification.localized(AppLocalizations.of(context)!).$2!,
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Text(timeAgo(AppLocalizations.of(context)!, notification.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
          ])),
          if (!notification.isRead)
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
            ),
        ]),
      ),
    );
  }
}
