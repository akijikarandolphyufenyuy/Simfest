import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/logout_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../legal/terms_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../auth/providers/profile_provider.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/screens/notification_prefs_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileProvider);
    final displayName = profile.whenOrNull(data: (p) => p?.displayName) ?? l10n.defaultArtistName;
    final initials = profile.whenOrNull(data: (p) => p?.initials) ?? 'A';

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(slivers: [
        AppSliverHeader(
          title: displayName,
          subtitle: l10n.manageYourAccount,
          showBack: true,
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.teal,
            child: Text(initials,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
          ),
          actions: [
            IconButton(
              tooltip: l10n.editProfile,
              icon: const Icon(Icons.edit_outlined, color: AppColors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _group(l10n.account, [
                _tile(
                  icon: Icons.person_outline,
                  title: l10n.editProfile,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                _tile(
                  icon: Icons.lock_outline,
                  title: l10n.changePassword,
                  onTap: () => _changePassword(context),
                ),
                _tile(
                  icon: Icons.language_outlined,
                  title: l10n.changeLanguage,
                  trailing: _langBadge(ref),
                  onTap: () => _changeLanguage(context, ref),
                ),
              ]),
              const SizedBox(height: 16),
              _group(l10n.notificationsAndSubscription, [
                _tile(
                  icon: Icons.notifications_outlined,
                  title: l10n.notifications,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
                _tile(
                  icon: Icons.tune_rounded,
                  title: l10n.notificationPreferences,
                  onTap: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPrefsScreen())),
                ),
                _tile(
                  icon: Icons.workspace_premium_outlined,
                  title: l10n.subscriptionStatus,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                ),
              ]),
              const SizedBox(height: 16),
              _group(l10n.legal, [
                _tile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacyPolicy,
                  onTap: () => _showInfo(context, l10n.privacyPolicy, l10n.privacyPolicyBody),
                ),
                _tile(
                  icon: Icons.description_outlined,
                  title: l10n.termsAndConditions,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                ),
                _tile(
                  icon: Icons.help_outline,
                  title: l10n.helpAndSupport,
                  onTap: () => _showInfo(context, l10n.helpAndSupport, l10n.helpBody),
                ),
                _tile(
                  icon: Icons.info_outline_rounded,
                  title: l10n.aboutSplitSure,
                  onTap: () => context.push('/about'),
                ),
              ]),
              const SizedBox(height: 16),
              _group(l10n.session, [
                _tile(
                  icon: Icons.logout_rounded,
                  title: l10n.logout,
                  color: Colors.redAccent,
                  onTap: () => _logout(context, ref),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _group(String title, List<Widget> tiles) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mutedText, letterSpacing: 0.5)),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(children: tiles),
      ),
    ]);
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: color ?? AppColors.deepNavy, size: 20),
          const SizedBox(width: 14),
          Expanded(
              child: Text(title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color ?? AppColors.deepNavy))),
          trailing ?? const Icon(Icons.chevron_right, color: AppColors.mutedText, size: 18),
        ]),
      ),
    );
  }

  Widget _langBadge(WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(locale.languageCode.toUpperCase(),
          style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  void _changeLanguage(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(l10n.selectLanguageTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 20),
          _LangOption(label: l10n.english, code: 'en', ref: ref),
          const SizedBox(height: 10),
          _LangOption(label: l10n.french, code: 'fr', ref: ref),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _changePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _showInfo(BuildContext context, String title, String content) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content, style: const TextStyle(height: 1.6)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close))],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showLogoutConfirm(context, ref);
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String code;
  final WidgetRef ref;
  const _LangOption({required this.label, required this.code, required this.ref});

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(localeProvider).languageCode;
    final selected = current == code;
    return GestureDetector(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepNavy : AppColors.lightBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.deepNavy : AppColors.cardBorder),
        ),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: selected ? AppColors.white : AppColors.deepNavy,
              )),
          const Spacer(),
          if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.teal),
        ]),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordTooShort), backgroundColor: Colors.red),
      );
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordsDoNotMatch), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newCtrl.text),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.passwordUpdated), backgroundColor: AppColors.teal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithDetails('$e')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(l10n.changePassword,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 20),
          TextField(
            controller: _newCtrl,
            obscureText: _obscure1,
            decoration: InputDecoration(
              labelText: l10n.newPassword,
              suffixIcon: IconButton(
                icon: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscure2,
            decoration: InputDecoration(
              labelText: l10n.confirmNewPassword,
              suffixIcon: IconButton(
                icon: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepNavy, minimumSize: const Size(double.infinity, 50)),
            child: _loading
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                : Text(l10n.updatePassword, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }
}
