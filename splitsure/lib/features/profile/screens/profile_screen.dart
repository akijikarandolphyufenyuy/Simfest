import 'package:flutter/material.dart';
import '../../../shared/widgets/logout_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../auth/providers/profile_provider.dart';
import '../../notifications/screens/notification_prefs_screen.dart';
import '../../subscription/models/subscription.dart';
import '../../subscription/screens/subscription_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const ProfileScreen({super.key, this.onBack});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingAvatar = false;
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _changeAvatar() async {
    setState(() => _uploadingAvatar = true);
    try {
      final url = await uploadAvatar();
      if (url != null) {
        final uid = Supabase.instance.client.auth.currentUser!.id;
        await Supabase.instance.client.from('profiles').update({'avatar_url': url}).eq('id', uid);
        ref.invalidate(profileProvider);
        if (mounted) showSuccess(context, l10n.profileUpdated);
      }
    } catch (e) {
      if (mounted) showError(context, l10n.uploadError(friendlyError(e)));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _openEdit() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
    ref.invalidate(profileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).whenOrNull(data: (p) => p);
    final sub = ref.watch(entitlementProvider).whenOrNull(data: (e) => e) ?? Entitlement.free;
    final locale = ref.watch(localeProvider);
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    final displayName = profile?.displayName ?? l10n.defaultArtistName;
    final roles = profile?.musicRoles ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(entitlementProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppSliverHeader(
              gradient: kHeroGradient,
              title: displayName,
              subtitle: [
                if (profile?.username != null && profile!.username!.isNotEmpty) '@${profile.username}',
                ...roles.take(3).map((r) => musicRoleLabel(l10n, r)),
              ].join(' · '),
              leading: _Avatar(
                initials: profile?.initials ?? 'A',
                url: profile?.avatarUrl,
                uploading: _uploadingAvatar,
                onTap: _changeAvatar,
              ),
              showBack: widget.onBack != null,
              onBackOverride: widget.onBack,
              actions: [
                IconButton(
                  tooltip: l10n.settings,
                  icon: const Icon(Icons.settings_outlined, color: AppColors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                IconButton(
                  tooltip: l10n.editProfile,
                  icon: const Icon(Icons.edit_outlined, color: AppColors.white),
                  onPressed: _openEdit,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeSlideIn(
                    child: _Section(
                      title: l10n.musicRoles,
                      trailing: TextButton(onPressed: _openEdit, child: Text(l10n.edit)),
                      child: roles.isEmpty
                          ? Text(l10n.noRolesYet, style: const TextStyle(color: AppColors.mutedText, fontSize: 13))
                          : Wrap(spacing: 8, runSpacing: 8, children: [
                              for (final r in roles)
                                Chip(
                                  label: Text(musicRoleLabel(l10n, r)),
                                  labelStyle: const TextStyle(
                                      color: AppColors.deepNavy, fontSize: 12.5, fontWeight: FontWeight.w600),
                                  backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                                  side: BorderSide.none,
                                  visualDensity: VisualDensity.compact,
                                ),
                            ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: stagger(1),
                    child: _Section(
                      title: l10n.personalInformation,
                      child: Column(children: [
                        _InfoRow(Icons.email_outlined, l10n.emailShort, email),
                        if (profile?.phone != null && profile!.phone!.isNotEmpty)
                          _InfoRow(Icons.phone_outlined, l10n.phone, profile.phone!),
                        if (profile?.bio != null && profile!.bio!.isNotEmpty)
                          _InfoRow(Icons.info_outline, l10n.bio, profile.bio!),
                        if (profile?.country != null)
                          _InfoRow(Icons.location_on_outlined, l10n.country, countryLabel(l10n, profile!.country!)),
                        if (profile?.city != null && profile!.city!.isNotEmpty)
                          _InfoRow(Icons.location_city_outlined, l10n.city, profile.city!),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(delay: stagger(2), child: _PlanCard(sub: sub)),
                  const SizedBox(height: 16),
                  FadeSlideIn(delay: stagger(3), child: _SocialCard(profile: profile)),
                  const SizedBox(height: 16),
                  _Section(
                    title: l10n.preferences,
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      _Tile(
                        icon: Icons.language_outlined,
                        title: l10n.language,
                        trailing: _Badge(locale.languageCode == 'fr' ? l10n.french : l10n.english),
                        onTap: () => _pickLanguage(context),
                      ),
                      _Tile(
                        icon: Icons.tune_rounded,
                        title: l10n.notificationPreferences,
                        onTap: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const NotificationPrefsScreen())),
                      ),
                      _Tile(
                        icon: Icons.workspace_premium_outlined,
                        title: l10n.subscriptionStatus,
                        onTap: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                      ),
                      _Tile(
                        icon: Icons.settings_outlined,
                        title: l10n.settings,
                        onTap: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: l10n.about,
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      _Tile(icon: Icons.info_outline, title: l10n.aboutSplitSure, onTap: () => _showAbout(context)),
                      _Tile(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.privacyPolicy,
                        onTap: () => _showInfo(context, l10n.privacyPolicy, l10n.privacyPolicyBody),
                      ),
                      _Tile(
                        icon: Icons.description_outlined,
                        title: l10n.termsAndConditions,
                        onTap: () => _showInfo(context, l10n.termsAndConditions, l10n.termsBody),
                      ),
                      _Tile(
                        icon: Icons.help_outline,
                        title: l10n.helpAndSupport,
                        onTap: () => _showInfo(context, l10n.helpAndSupport, l10n.helpBody),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: Text(l10n.logout, style: const TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                      backgroundColor: Colors.red.withValues(alpha: 0.04),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickLanguage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.selectLanguageTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
          const SizedBox(height: 16),
          for (final (code, label) in [('en', l10n.english), ('fr', l10n.french)])
            ListTile(
              title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: ref.read(localeProvider).languageCode == code
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.teal)
                  : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(Locale(code));
                Navigator.pop(ctx);
              },
            ),
        ]),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('SplitSure', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.appVersion, style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
          const SizedBox(height: 12),
          Text(l10n.pdfTaglineOneLine, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
          const SizedBox(height: 10),
          Text(l10n.aboutDescription, style: const TextStyle(color: AppColors.mutedText, fontSize: 13, height: 1.5)),
          const SizedBox(height: 10),
          Text(l10n.aboutCommunity, style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close))],
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body, style: const TextStyle(height: 1.6)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close))],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showLogoutConfirm(context, ref);
  }
}

// ── Pieces ─────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String initials;
  final String? url;
  final bool uploading;
  final VoidCallback onTap;
  const _Avatar({required this.initials, required this.url, required this.uploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white54, width: 1.5)),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.teal,
            backgroundImage: url != null ? NetworkImage(url!) : null,
            child: uploading
                ? const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                : (url == null
                    ? Text(initials,
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 17))
                    : null),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.teal,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 1.5),
            ),
            child: const Icon(Icons.camera_alt_rounded, size: 11, color: AppColors.white),
          ),
        ),
      ]),
    );
  }
}

class _SocialRow extends StatelessWidget {
  final Widget logo;
  final String name;
  final String url;
  const _SocialRow({required this.logo, required this.name, required this.url});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          logo,
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              const SizedBox(height: 2),
              Text(url,
                  style: const TextStyle(fontSize: 13, color: AppColors.deepNavy, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;
  const _Section({required this.title, required this.child, this.trailing, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(children: [
          Expanded(
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.mutedText, letterSpacing: 0.6)),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: child,
      ),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppColors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 14, color: AppColors.deepNavy, fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.title, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.deepNavy, size: 20),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.deepNavy)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.mutedText, size: 18),
      );
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

class _PlanCard extends StatelessWidget {
  final Entitlement sub;
  const _PlanCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paid = sub.isPro;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: kNavyGradient, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.workspace_premium_rounded, color: AppColors.teal, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(planLabel(l10n, sub.planId),
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                if (sub.proActivatedAt != null)
                  Text(l10n.proActiveSince(formatDate(sub.proActivatedAt)),
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ]),
            ),
            _Badge(paid ? l10n.active : l10n.upgrade),
          ]),
        ),
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  final UserProfile? profile;
  const _SocialCard({required this.profile});

  static Widget _logo(String asset) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.asset(asset, width: 18, height: 18, fit: BoxFit.cover),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final links = <(String, String?, Widget)>[
      ('WhatsApp', profile?.whatsappUrl, _logo('assets/images/SocialMedia/whatsapp.jpg')),
      ('TikTok', profile?.tiktokUrl, _logo('assets/images/SocialMedia/tiktok.jpg')),
      ('YouTube', profile?.youtubeUrl, _logo('assets/images/SocialMedia/youtube.jpg')),
      ('Facebook', profile?.facebookUrl, _logo('assets/images/SocialMedia/facebook.jpg')),
    ].where((e) => e.$2 != null && e.$2!.isNotEmpty).toList();
    return _Section(
      title: l10n.connectedAccounts,
      child: links.isEmpty
          ? Text(l10n.noSocialAccounts, style: const TextStyle(color: AppColors.mutedText, fontSize: 13))
          : Column(children: [
              for (final (name, url, logo) in links) _SocialRow(logo: logo, name: name, url: url!),
            ]),
    );
  }
}
