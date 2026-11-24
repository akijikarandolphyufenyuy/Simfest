import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/services/fcm_service.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../models/notification.dart';

class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  State<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  Map<String, bool>? _prefs;
  bool _enablingPush = false;

  @override
  void initState() {
    super.initState();
    loadNotificationPrefs().then((p) {
      if (mounted) setState(() => _prefs = p);
    });
  }

  Future<void> _toggle(String key, bool value) async {
    final l10n = AppLocalizations.of(context)!;
    final next = {...?_prefs, key: value};
    setState(() => _prefs = next);
    try {
      await saveNotificationPrefs(next);
    } catch (e) {
      if (mounted) showError(context, l10n.errorWithDetails(friendlyError(e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = {
      'agreement': (Icons.shield_outlined, l10n.notifCatAgreements, l10n.notifCatAgreementsHint),
      'campaign': (Icons.campaign_outlined, l10n.notifCatCampaigns, l10n.notifCatCampaignsHint),
      'subscription': (Icons.workspace_premium_outlined, l10n.notifCatSubscription, l10n.notifCatSubscriptionHint),
    };
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(slivers: [
        AppSliverHeader(
          title: l10n.notificationPreferences,
          leading: const HeaderIcon(Icons.tune_rounded),
          showBack: true,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: _prefs == null
                    ? const Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
                      )
                    : Column(children: [
                        for (final e in items.entries)
                          SwitchListTile(
                            value: _prefs![e.key] ?? true,
                            onChanged: (v) => _toggle(e.key, v),
                            activeThumbColor: AppColors.teal,
                            secondary: Icon(e.value.$1, color: AppColors.deepNavy),
                            title: Text(e.value.$2,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
                            subtitle: Text(e.value.$3, style: const TextStyle(fontSize: 12)),
                          ),
                      ]),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _enablingPush
                    ? null
                    : () async {
                        setState(() => _enablingPush = true);
                        try {
                          await FcmService.init();
                          if (context.mounted) showSuccess(context, l10n.pushEnabled);
                        } catch (e) {
                          if (context.mounted) showError(context, l10n.pushUnavailable);
                        } finally {
                          if (mounted) setState(() => _enablingPush = false);
                        }
                      },
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(l10n.enablePush),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 10),
              Text(l10n.pushExplain,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
            ]),
          ),
        ),
      ]),
    );
  }
}
