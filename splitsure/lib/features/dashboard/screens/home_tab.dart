import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../auth/providers/profile_provider.dart';
import '../../notifications/models/notification.dart';
import '../../protect/providers/agreements_provider.dart';
import '../../protect/screens/agreement_detail_screen.dart';
import '../../reach/providers/campaigns_provider.dart';
import '../../protect/models/agreement.dart';
import '../../reach/models/campaign.dart';
import '../../subscription/models/subscription.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../passport/models/passport.dart';
import '../../projects/models/project.dart';
import '../../projects/screens/project_form_screen.dart';
import '../../projects/screens/projects_screen.dart';
import '../../hub/models/opportunity.dart';
import '../widgets/support_chat_button.dart';
import 'collaborations_screen.dart';

// Callback so HomeTab can switch tabs in MainShell
typedef OnTabSwitch = void Function(int index);

class HomeTab extends ConsumerWidget {
  final OnTabSwitch? onTabSwitch;
  const HomeTab({super.key, this.onTabSwitch});

  String _greeting(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 12) return l10n.greetingMorning;
    if (h < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileProvider).whenOrNull(data: (p) => p);
    final agreementList = ref.watch(agreementsProvider).whenOrNull(data: (l) => l) ?? <Agreement>[];
    final campaignList = ref.watch(campaignsProvider).whenOrNull(data: (l) => l) ?? <Campaign>[];
    final entitlement = ref.watch(entitlementProvider).whenOrNull(data: (e) => e) ?? Entitlement.free;
    final unread = ref.watch(unreadCountProvider);
    final projects = ref.watch(projectsProvider).whenOrNull(data: (l) => l) ?? <Project>[];
    final applications = ref.watch(myApplicationsProvider).whenOrNull(data: (l) => l) ?? <Application>[];
    final successful = successfulCollaborations(agreementList).length;
    final acceptedApps = acceptedApplications(applications).length;

    // Greet with the first name only.
    final metaFirst = Supabase.instance.client.auth.currentUser?.userMetadata?['first_name'] as String?;
    final firstName = capitalizeName([profile?.firstName, metaFirst, profile?.username]
            .firstWhere((s) => s != null && s.trim().isNotEmpty, orElse: () => null)
            ?.trim()
            .split(' ')
            .first ??
        l10n.defaultArtistName);

    final pending = agreementList.where((a) => a.status == 'pending' || a.status == 'changes_requested').toList();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Stack(children: [
        RefreshIndicator(
          color: AppColors.teal,
          onRefresh: () async {
            ref.invalidate(agreementsProvider);
            ref.invalidate(campaignsProvider);
            ref.invalidate(entitlementProvider);
            ref.invalidate(notificationsProvider);
            ref.invalidate(profileProvider);
            ref.invalidate(projectsProvider);
            ref.invalidate(myApplicationsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              AppSliverHeader(
                gradient: kHeroGradient,
                title: '${l10n.greetingWithComma(_greeting(l10n))} $firstName',
                subtitle: '${l10n.agreementCount(agreementList.length)} · ${l10n.campaignCount(campaignList.length)}',
                actions: [
                  // Account type, always visible: BASIC or PRO.
                  _PlanBadge(
                    isPro: entitlement.isPro,
                    onTap: () => entitlement.isPro
                        ? Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()))
                        : startProUpgrade(context, ref),
                  ),
                  _BellButton(unread: unread, onTap: () => onTabSwitch?.call(4)),
                  Padding(
                    padding: const EdgeInsets.only(left: 2, right: 6, bottom: 4),
                    child: GestureDetector(
                      onTap: () => onTabSwitch?.call(5),
                      child: _Avatar(
                        initials: profile?.initials ?? firstName.characters.first.toUpperCase(),
                        avatarUrl: profile?.avatarUrl,
                        radius: 18,
                      ),
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Current plan, always visible at the top of the dashboard.
                    FadeSlideIn(
                      child: _SubscriptionBanner(
                        entitlement: entitlement,
                        onTap: () => entitlement.isPro
                            ? Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()))
                            : startProUpgrade(context, ref),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: stagger(1),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.shield_rounded,
                              label: l10n.agreementsLabel,
                              count: agreementList.length,
                              color: AppColors.deepNavy,
                              onTap: () => onTabSwitch?.call(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.campaign_rounded,
                              label: l10n.campaignsLabel,
                              count: campaignList.length,
                              color: AppColors.teal,
                              onTap: () => onTabSwitch?.call(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: stagger(2),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.handshake_rounded,
                              label: l10n.successfulCollaborations,
                              count: successful,
                              color: AppColors.success,
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const SuccessfulCollaborationsScreen())),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.verified_rounded,
                              label: l10n.acceptedCollaborations,
                              count: acceptedApps,
                              color: const Color(0xFF7C3AED),
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const AcceptedCollaborationsScreen())),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delay: stagger(2),
                      child: _QuickActions(
                        onProtect: () => onTabSwitch?.call(1),
                        onReach: () => onTabSwitch?.call(3),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: stagger(2),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final p = await Navigator.push<Project>(
                              context, MaterialPageRoute(builder: (_) => const ProjectFormScreen()));
                          ref.invalidate(projectsProvider);
                          if (p != null && context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p)));
                          }
                        },
                        icon: const Icon(Icons.library_add_rounded, size: 20),
                        label: Text(l10n.createProject),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: AppColors.deepNavy, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    if (projects.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      Row(children: [
                        Expanded(child: _SectionLabel(l10n.recentProjects)),
                        TextButton(
                          onPressed: () =>
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen())),
                          child: Text(l10n.seeAll,
                              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      for (final p in projects.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ProjectCard(
                            project: p,
                            compact: true,
                            agreementCount: agreementList.where((a) => a.projectId == p.id).length,
                            campaignCount: campaignList.where((c) => c.projectId == p.id).length,
                            onTap: () => Navigator.push(
                                context, MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: p))),
                          ),
                        ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen())),
                          icon: const Icon(Icons.library_music_outlined, size: 18, color: AppColors.mutedText),
                          label: Text(l10n.myProjects, style: const TextStyle(color: AppColors.mutedText)),
                        ),
                      ),
                    ],
                    if (pending.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _SectionLabel(l10n.pendingAgreements, count: pending.length),
                      const SizedBox(height: 10),
                      for (final a in pending.take(3))
                        _PendingAgreementTile(
                          agreement: a,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AgreementDetailScreen(agreement: a)),
                            );
                            ref.invalidate(agreementsProvider);
                          },
                        ),
                    ],
                    const SizedBox(height: 26),
                    _SectionLabel(l10n.modules),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delay: stagger(4),
                      child: _ModuleCard(
                        title: l10n.protectModuleTitle,
                        subtitle: l10n.protectModuleSubtitle,
                        icon: Icons.shield_rounded,
                        gradient: kNavyGradient,
                        tag: l10n.agreementCount(agreementList.length),
                        onTap: () => onTabSwitch?.call(1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: stagger(5),
                      child: _ModuleCard(
                        title: l10n.reachModuleTitle,
                        subtitle: l10n.reachModuleSubtitle,
                        icon: Icons.campaign_rounded,
                        gradient: kTealGradient,
                        tag: l10n.campaignCount(campaignList.length),
                        onTap: () => onTabSwitch?.call(3),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: stagger(6),
                      child: _ModuleCard(
                        title: l10n.opportunityHub,
                        subtitle: l10n.hubTagline,
                        icon: Icons.hub_rounded,
                        gradient: kHeroGradient,
                        tag: l10n.hubDiscover,
                        onTap: () => onTabSwitch?.call(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: stagger(7),
                      child: _ModuleCard(
                        title: l10n.musicPassport,
                        subtitle: l10n.passportTagline,
                        icon: Icons.badge_rounded,
                        gradient: kNavyGradient,
                        tag: ref.watch(myPassportProvider).whenOrNull(
                                data: (p) => p == null
                                    ? l10n.createPassport
                                    : (p.isPublished ? l10n.passportLive : l10n.passportDraft)) ??
                            '',
                        onTap: () => onTabSwitch?.call(6),
                      ),
                    ),
                    if (agreementList.isNotEmpty || campaignList.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _SectionLabel(l10n.recentActivity),
                      const SizedBox(height: 10),
                      ..._buildRecentActivity(l10n, agreementList, campaignList),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SupportChatButton(),
      ]),
    );
  }

  List<Widget> _buildRecentActivity(AppLocalizations l10n, List<Agreement> agreements, List<Campaign> campaigns) {
    final items = <_ActivityItem>[
      for (final a in agreements.take(5))
        _ActivityItem(
          icon: Icons.shield_outlined,
          color: AppColors.deepNavy,
          title: a.songTitle,
          subtitle: l10n.activityAgreement(agreementStatusLabel(l10n, a.status)),
          date: a.updatedAt ?? a.createdAt,
        ),
      for (final c in campaigns.take(5))
        _ActivityItem(
          icon: Icons.campaign_outlined,
          color: AppColors.teal,
          title: c.campaignName ?? c.songTitle,
          subtitle: l10n.activityCampaign(campaignStatusLabel(l10n, c.status)),
          date: c.updatedAt ?? c.createdAt,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return items.take(5).map((item) => _ActivityTile(item: item)).toList();
  }
}

// ── Header bits ──────────────────────────────────────────────────────────────

class _BellButton extends StatelessWidget {
  final int unread;
  final VoidCallback onTap;
  const _BellButton({required this.unread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: AppLocalizations.of(context)!.notifications,
      icon: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.teal,
        label: Text(unread > 9 ? '9+' : '$unread', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
        child: const Icon(Icons.notifications_outlined, color: AppColors.white),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final String? avatarUrl;
  final double radius;

  const _Avatar({required this.initials, this.avatarUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white54, width: 1.5)),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.teal,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null
            ? Text(initials,
                style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: radius * 0.6))
            : null,
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({required this.icon, required this.label, required this.count, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: kCardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: count),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) =>
                          Text('$v', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
                    ),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

// ── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final VoidCallback? onProtect;
  final VoidCallback? onReach;

  const _QuickActions({this.onProtect, this.onReach});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
              icon: Icons.shield_rounded, label: l10n.newAgreement, color: AppColors.deepNavy, onTap: onProtect),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              _ActionBtn(icon: Icons.campaign_rounded, label: l10n.newCampaign, color: AppColors.teal, onTap: onReach),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.white, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subscription Banner ──────────────────────────────────────────────────────

class _SubscriptionBanner extends StatelessWidget {
  final Entitlement entitlement;
  final VoidCallback onTap;
  const _SubscriptionBanner({required this.entitlement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPaid = entitlement.isPro;
    final isActive = isPaid;
    final planName = l10n.currentPlanName(planLabel(l10n, entitlement.planId));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF142B4A), Color(0xFF1E3F6F), Color(0xFF0F6E6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))
            ],
          ),
          // Text gets the full width; the action sits on its own line so
          // nothing is truncated on narrow phones.
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: AppColors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(planName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        isPaid && isActive
                            ? (entitlement.proActivatedAt != null
                                ? l10n.proActiveSince(formatDate(entitlement.proActivatedAt))
                                : l10n.fullAccessActive)
                            : l10n.proUnlocksBody,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.teal.withValues(alpha: 0.3) : AppColors.teal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isPaid ? l10n.proActive : l10n.upgradeToPro,
                    style: TextStyle(
                        color: isPaid ? AppColors.teal : AppColors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Pending agreement tile ───────────────────────────────────────────────────

class _PendingAgreementTile extends StatelessWidget {
  final Agreement agreement;
  final VoidCallback onTap;
  const _PendingAgreementTile({required this.agreement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final changes = agreement.status == 'changes_requested';
    final color = changes ? Colors.orange : AppColors.teal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(changes ? Icons.edit_note_rounded : Icons.hourglass_top_rounded, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agreement.songTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.deepNavy)),
                      Text(agreementStatusLabel(l10n, agreement.status),
                          style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Module Card ──────────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String tag;
  final VoidCallback? onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.tag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(tag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final int? count;
  const _SectionLabel(this.text, {this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(10)),
            child: Text('$count',
                style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ],
    );
  }
}

// ── Activity ─────────────────────────────────────────────────────────────────

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime date;

  _ActivityItem(
      {required this.icon, required this.color, required this.title, required this.subtitle, required this.date});
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: kCardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: item.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.deepNavy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(timeAgo(AppLocalizations.of(context)!, item.date),
              style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
        ],
      ),
    );
  }
}

/// Compact account-type badge for the Home header: gold "PRO" or frosted "BASIC".
class _PlanBadge extends StatelessWidget {
  final bool isPro;
  final VoidCallback onTap;
  const _PlanBadge({required this.isPro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: isPro ? l10n.planBadgeTooltipPro : l10n.planBadgeTooltipBasic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.only(right: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isPro
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFF5A623)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isPro ? null : Colors.white.withValues(alpha: 0.16),
              border: Border.all(color: isPro ? const Color(0xFFFFE082) : Colors.white38, width: 1),
              boxShadow: isPro
                  ? [
                      BoxShadow(
                          color: const Color(0xFFF5A623).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ]
                  : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                isPro ? Icons.workspace_premium_rounded : Icons.arrow_circle_up_rounded,
                size: 15,
                color: isPro ? const Color(0xFF5D3A00) : AppColors.white,
              ),
              const SizedBox(width: 4),
              Text(
                isPro ? l10n.planBadgePro : l10n.planBadgeBasic,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isPro ? const Color(0xFF5D3A00) : AppColors.white,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
