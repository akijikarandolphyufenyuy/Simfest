import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n/app_localizations.dart';
import '../../core/localization/l10n_helpers.dart';
import '../../features/auth/providers/profile_provider.dart';
import '../../features/auth/services/email_verification.dart';
import '../../features/dashboard/screens/home_tab.dart';
import '../../features/protect/screens/protect_screen.dart';
import '../../features/reach/screens/reach_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/models/notification.dart';
import '../../core/services/session_prefs.dart';
import '../../features/protect/providers/agreements_provider.dart';
import '../../features/protect/screens/agreement_detail_screen.dart';
import '../../features/subscription/models/subscription.dart';
import '../../features/subscription/screens/plan_selection_screen.dart';
import '../../features/hub/screens/hub_screen.dart';
import '../../features/passport/screens/passport_screen.dart';
import '../../features/projects/screens/projects_screen.dart';
import 'app_header.dart';
import 'form_widgets.dart';
import 'welcome_banner.dart';

/// Width above which the app uses a side navigation instead of the bottom bar.
const kDesktopBreakpoint = 900.0;

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  WelcomeKind? _welcome;

  @override
  void initState() {
    super.initState();
    // Pick up the one-shot welcome request left by the login / register screen.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // New accounts confirm their e-mail with a 6-digit code before anything else.
      if (!await isEmailVerified()) {
        _blocked = true;
        final email = Supabase.instance.client.auth.currentUser?.email ?? '';
        if (mounted) context.go('/verify-email?email=${Uri.encodeComponent(email)}');
        return;
      }
      if (!mounted) return;
      _verifiedChecked = true;
      final pending = ref.read(pendingWelcomeProvider);
      if (pending != null && mounted) {
        setState(() => _welcome = pending);
        ref.read(pendingWelcomeProvider.notifier).state = null;
      }
      // The plan may already be loaded (e.g. returning from "Continue with Google"),
      // in which case the listener in build() never sees a change: check it now too.
      if (mounted) ref.read(entitlementProvider).whenData(_maybeAskForPlan);
      _openPendingInvite();
    });
  }

  /// If the user arrived through an invitation link, link it and open the agreement.
  Future<void> _openPendingInvite() async {
    final token = await takePendingInvite();
    if (token == null) return;
    try {
      final id = await claimInvite(token);
      ref.invalidate(agreementsProvider);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AgreementDetailScreen(agreementId: id)));
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    }
  }

  bool _planPromptShown = false;
  bool _blocked = false; // e-mail not verified yet: leaving for /verify-email
  bool _verifiedChecked = false; // plan prompt waits for the e-mail check

  /// New accounts (and accounts from before plans existed) pick Free or Pro once.
  void _maybeAskForPlan(Entitlement e) {
    if (!_verifiedChecked || _blocked || _planPromptShown || e.hasChosenPlan) return;
    _planPromptShown = true;
    Future.delayed(Duration(milliseconds: _welcome != null ? 2600 : 400), () {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const PlanSelectionScreen()));
    });
  }

  void _select(int i) => setState(() => _index = i);

  String _firstName(AppLocalizations l10n) {
    final p = ref.watch(profileProvider).whenOrNull(data: (p) => p);
    final fromProfile = p?.firstName?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return capitalizeName(fromProfile.split(' ').first);
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata?['first_name'] as String?;
    if (meta != null && meta.trim().isNotEmpty) return capitalizeName(meta.trim().split(' ').first);
    return l10n.defaultArtistName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unread = ref.watch(unreadCountProvider);
    final isDesktop = MediaQuery.of(context).size.width >= kDesktopBreakpoint;
    ref.listen<AsyncValue<Entitlement>>(entitlementProvider, (_, next) => next.whenData(_maybeAskForPlan));
    ref.watch(entitlementProvider);

    // Tab indexes are stable (see [ShellTab]); the order differs per layout.
    final tabs = [
      HomeTab(onTabSwitch: _select),
      ProtectScreen(onBack: () => _select(0)),
      HubScreen(onBack: () => _select(0)),
      ReachScreen(onBack: () => _select(0)),
      NotificationsScreen(onBack: () => _select(0)),
      ProfileScreen(onBack: () => _select(0)),
      PassportScreen(showBack: false, onBack: () => _select(0)),
      const ProjectsScreen(),
    ];

    final items = [
      _NavSpec(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, l10n.navHome),
      _NavSpec(Icons.shield_outlined, Icons.shield_rounded, l10n.protect),
      _NavSpec(Icons.hub_outlined, Icons.hub_rounded, l10n.navHub),
      _NavSpec(Icons.campaign_outlined, Icons.campaign_rounded, l10n.reach),
      _NavSpec(Icons.notifications_outlined, Icons.notifications_rounded, l10n.notifications, badge: unread),
      _NavSpec(Icons.person_outline_rounded, Icons.person_rounded, l10n.profile,
          iconOverride: const _ProfileNavAvatar()),
      _NavSpec(Icons.badge_outlined, Icons.badge_rounded, l10n.musicPassport),
      _NavSpec(Icons.library_music_outlined, Icons.library_music_rounded, l10n.myProjects),
    ];
    // Desktop sidebar: Overview, My Projects, Protect, Reach, Hub, Passport, Notifications, Profile.
    const desktopOrder = [ShellTab.home, ShellTab.projects, ShellTab.protect, ShellTab.reach, ShellTab.hub,
      ShellTab.passport, ShellTab.notifications, ShellTab.profile];
    // Mobile: four tabs + "More".
    const mobileTabs = [ShellTab.home, ShellTab.protect, ShellTab.hub, ShellTab.reach];
    const moreTabs = [ShellTab.passport, ShellTab.projects, ShellTab.profile];
    final moreBadge = unread;
    final mobileItems = [
      for (final t in mobileTabs) items[t],
      _NavSpec(Icons.menu_rounded, Icons.menu_open_rounded, l10n.more, badge: moreBadge),
    ];
    final mobileIndex = mobileTabs.contains(_index) ? mobileTabs.indexOf(_index) : mobileTabs.length;

    // Keep every tab alive but only paint the active one.
    final body = Stack(
      children: [
        for (var i = 0; i < tabs.length; i++)
          Visibility(
            visible: _index == i,
            maintainState: true,
            child: TickerMode(
              enabled: _index == i,
              child: tabs[i],
            ),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Stack(
        children: [
          if (isDesktop)
            Row(
              children: [
                _SideNav(
                  items: [for (final t in desktopOrder) items[t]],
                  index: desktopOrder.indexOf(_index),
                  onTap: (i) => _select(desktopOrder[i]),
                ),
                Expanded(child: body),
              ],
            )
          else
            body,
          if (_welcome != null)
            WelcomeBanner(
              kind: _welcome!,
              firstName: _firstName(l10n),
              onDone: () => setState(() => _welcome = null),
            ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _FloatingNavBar(
              items: mobileItems,
              index: mobileIndex,
              onTap: (i) => i < mobileTabs.length
                  ? _select(mobileTabs[i])
                  : _showMore([for (final t in moreTabs) (t, items[t])]),
            ),
    );
  }

  void _showMore(List<(int, _NavSpec)> entries) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _MoreSheet(entries: entries, currentIndex: _index, onSelect: (tab) {
        Navigator.pop(ctx);
        _select(tab);
      }),
    );
  }
}

/// Stable indexes of the shell's sections.
abstract final class ShellTab {
  static const home = 0, protect = 1, hub = 2, reach = 3, notifications = 4, profile = 5, passport = 6, projects = 7;
}

class _NavSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
  final Widget? iconOverride;
  const _NavSpec(this.icon, this.activeIcon, this.label, {this.badge = 0, this.iconOverride});
}

// ── Mobile: floating bottom bar ──────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final List<_NavSpec> items;
  final int index;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: kNavyGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepNavy.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _NavItem(spec: items[i], active: index == i, onTap: () => onTap(i))),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavSpec spec;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.spec, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.teal : Colors.white.withValues(alpha: 0.55);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(colors: [AppColors.teal.withValues(alpha: 0.30), AppColors.teal.withValues(alpha: 0.12)])
                : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 250),
                scale: active ? 1.12 : 1,
                child: spec.iconOverride != null
                    ? _ActiveRing(active: active, child: spec.iconOverride!)
                    : _BadgeIcon(icon: active ? spec.activeIcon : spec.icon, color: color, badge: spec.badge),
              ),
              const SizedBox(height: 2),
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveRing extends StatelessWidget {
  final bool active;
  final Widget child;
  const _ActiveRing({required this.active, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppColors.teal : Colors.transparent,
            width: 2,
          ),
        ),
        child: child,
      );
}

/// The user's photo, or their initials in green when there is no photo.
class _ProfileNavAvatar extends ConsumerWidget {
  final double radius;
  const _ProfileNavAvatar({this.radius = 11});

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).whenOrNull(data: (p) => p);
    final url = profile?.avatarUrl;
    final hasPhoto = url != null && url.trim().isNotEmpty;
    final initials = profile?.initials ?? 'A';
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _green, width: 1.5)),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFDCFCE7),
        backgroundImage: hasPhoto ? NetworkImage(url) : null,
        child: hasPhoto
            ? null
            : Text(initials,
                style: TextStyle(color: _green, fontSize: radius * 0.82, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int badge;
  const _BadgeIcon({required this.icon, required this.color, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: 22),
        if (badge > 0)
          Positioned(
            top: -4,
            right: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.deepNavy, width: 1.5),
              ),
              child: Center(
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── More sheet ───────────────────────────────────────────────────────────────

class _MoreSheet extends StatefulWidget {
  final List<(int, _NavSpec)> entries;
  final int currentIndex;
  final void Function(int tab) onSelect;
  const _MoreSheet({required this.entries, required this.currentIndex, required this.onSelect});

  @override
  State<_MoreSheet> createState() => _MoreSheetState();
}

class _MoreSheetState extends State<_MoreSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380))..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        decoration: BoxDecoration(
          gradient: kNavyGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.entries.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  _AnimatedMoreItem(
                    ctrl: _ctrl,
                    delay: i * 0.12,
                    tab: widget.entries[i].$1,
                    spec: widget.entries[i].$2,
                    active: widget.currentIndex == widget.entries[i].$1,
                    onTap: () => widget.onSelect(widget.entries[i].$1),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMoreItem extends StatelessWidget {
  final AnimationController ctrl;
  final double delay;
  final int tab;
  final _NavSpec spec;
  final bool active;
  final VoidCallback onTap;

  const _AnimatedMoreItem({
    required this.ctrl,
    required this.delay,
    required this.tab,
    required this.spec,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: ctrl,
      curve: Interval(delay, (delay + 0.55).clamp(0.0, 1.0), curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) => Opacity(
        opacity: curved.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 88,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.teal.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppColors.teal.withValues(alpha: 0.5) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spec.iconOverride != null)
                const _ProfileNavAvatar(radius: 13)
              else
                _BadgeIcon(
                  icon: active ? spec.activeIcon : spec.icon,
                  color: active ? AppColors.teal : Colors.white70,
                  badge: spec.badge,
                ),
              const SizedBox(height: 8),
              Text(
                spec.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  color: active ? AppColors.teal : Colors.white,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Desktop: side navigation ─────────────────────────────────────────────────

class _SideNav extends StatelessWidget {
  final List<_NavSpec> items;
  final int index;
  final ValueChanged<int> onTap;

  const _SideNav({required this.items, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF142B4A), Color(0xFF173A5E), Color(0xFF0F5E63)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/images/app_icon.png', width: 36, height: 36),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'Split', style: TextStyle(color: AppColors.white)),
                        TextSpan(text: 'Sure', style: TextStyle(color: AppColors.teal)),
                      ]),
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => onTap(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: index == i ? AppColors.teal.withValues(alpha: 0.16) : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  if (items[i].iconOverride != null)
                                    const _ProfileNavAvatar(radius: 11)
                                  else
                                    _BadgeIcon(
                                      icon: index == i ? items[i].activeIcon : items[i].icon,
                                      color: index == i ? AppColors.teal : Colors.white70,
                                      badge: items[i].badge,
                                    ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      items[i].label,
                                      style: TextStyle(
                                        color: index == i ? AppColors.white : Colors.white70,
                                        fontWeight: index == i ? FontWeight.w700 : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
