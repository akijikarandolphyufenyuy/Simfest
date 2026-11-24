import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/chip_inputs.dart';
import '../../passport/models/passport.dart';
import '../../subscription/models/subscription.dart';
import '../models/opportunity.dart';
import '../widgets/opportunity_card.dart';
import 'opportunity_detail_screen.dart';
import 'opportunity_form_screen.dart';
import '../../dealflow/models/workspace.dart';
import '../../dealflow/screens/workspace_screen.dart';

class _Filters {
  String? role, category, compensation;
  String genre = '', location = '';
  int? days;

  bool get active => role != null || category != null || compensation != null || genre.isNotEmpty || location.isNotEmpty || days != null;

  bool matches(Opportunity o) {
    if (role != null && !o.requiredRoles.contains(role)) return false;
    if (category != null && o.category != category) return false;
    if (compensation != null && o.collaborationType != compensation) return false;
    if (genre.isNotEmpty && !o.genres.any((g) => g.toLowerCase().contains(genre.toLowerCase()))) return false;
    if (location.isNotEmpty &&
        !(o.location ?? '').toLowerCase().contains(location.toLowerCase()) &&
        !(location.toLowerCase() == 'remote' && o.isRemote)) {
      return false;
    }
    if (days != null && o.createdAt.isBefore(DateTime.now().subtract(Duration(days: days!)))) return false;
    return true;
  }
}

/// Opportunity Hub: discover, my posts, my applications.
class HubScreen extends ConsumerStatefulWidget {
  final bool showBack;
  final VoidCallback? onBack;
  const HubScreen({super.key, this.showBack = false, this.onBack});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  int _tab = 0;
  String _query = '';
  final _filters = _Filters();

  void _refresh() {
    ref.invalidate(openOpportunitiesProvider);
    ref.invalidate(myOpportunitiesProvider);
    ref.invalidate(myApplicationsProvider);
    ref.invalidate(myPassportProvider);
    ref.invalidate(myWorkspacesProvider);
  }

  void _open(String id) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => OpportunityDetailScreen(opportunityId: id)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ent = ref.watch(entitlementProvider).whenOrNull(data: (e) => e) ?? Entitlement.free;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-hub',
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        onPressed: () => openOpportunityForm(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.postOpportunity),
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async => _refresh(),
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          AppSliverHeader(
            title: l10n.opportunityHub,
            subtitle: ent.isPro ? l10n.hubTagline : l10n.freePostsRemaining((1 - ent.freePostsUsed).clamp(0, 1)),
            leading: const HeaderIcon(Icons.hub_rounded),
            showBack: widget.showBack || widget.onBack != null,
            onBackOverride: widget.onBack,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _HubTabBar(
                selected: _tab,
                labels: [l10n.hubDiscover, l10n.hubMyPosts, l10n.hubMyApplications, l10n.dealflow],
                icons: const [Icons.explore_rounded, Icons.campaign_rounded, Icons.send_rounded, Icons.handshake_rounded],
                onTap: (i) => setState(() => _tab = i),
              ),
            ),
          ),
          ...switch (_tab) {
            0 => _discover(l10n),
            1 => _myPosts(l10n),
            3 => _workspaces(l10n),
            _ => _myApplications(l10n),
          },
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ]),
      ),
    );
  }

  Widget _wrap(Widget child) => SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child),
          ),
        ),
      );

  List<Widget> _discover(AppLocalizations l10n) {
    final async = ref.watch(openOpportunitiesProvider);
    final myRoles = ref.watch(myRolesProvider);
    final all = (async.whenOrNull(data: (l) => l) ?? const <Opportunity>[])
        .where((o) => !o.isMine)
        .where((o) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return o.title.toLowerCase().contains(q) ||
              o.description.toLowerCase().contains(q) ||
              o.skills.any((s) => s.toLowerCase().contains(q)) ||
              o.genres.any((s) => s.toLowerCase().contains(q));
        })
        .where(_filters.matches)
        .toList();
    final recommended = myRoles.isEmpty
        ? <Opportunity>[]
        : (all.where((o) => o.matchScore(myRoles) > 0).toList()
          ..sort((a, b) => b.matchScore(myRoles).compareTo(a.matchScore(myRoles))));
    final rest = all.where((o) => !recommended.contains(o)).toList();

    return [
      _wrap(Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: l10n.searchOpportunities,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.cardBorder)),
                enabledBorder:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.cardBorder)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Badge(
            isLabelVisible: _filters.active,
            backgroundColor: AppColors.teal,
            smallSize: 10,
            child: IconButton.filledTonal(
              tooltip: l10n.filters,
              onPressed: () => _showFilters(l10n),
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ]),
      )),
      if (async.isLoading && all.isEmpty)
        _wrap(const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.teal)))),
      if (!async.isLoading && all.isEmpty)
        _wrap(_Empty(icon: Icons.travel_explore_rounded, title: l10n.noOpportunities, body: l10n.noOpportunitiesHint)),
      if (recommended.isNotEmpty) ...[
        _wrap(_SectionTitle(l10n.recommendedForYou, icon: Icons.auto_awesome_rounded)),
        for (var i = 0; i < recommended.length; i++)
          _wrap(FadeSlideIn(
            delay: stagger(i),
            child: OpportunityCard(opportunity: recommended[i], onTap: () => _open(recommended[i].id)),
          )),
      ],
      if (rest.isNotEmpty) ...[
        if (recommended.isNotEmpty) _wrap(_SectionTitle(l10n.allOpportunities)),
        for (var i = 0; i < rest.length; i++)
          _wrap(FadeSlideIn(delay: stagger(i), child: OpportunityCard(opportunity: rest[i], onTap: () => _open(rest[i].id)))),
      ],
    ];
  }

  List<Widget> _myPosts(AppLocalizations l10n) {
    final list = ref.watch(myOpportunitiesProvider).whenOrNull(data: (l) => l) ?? const <Opportunity>[];
    return [
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      if (list.isEmpty) _wrap(_Empty(icon: Icons.campaign_outlined, title: l10n.noMyPosts, body: l10n.noOpportunitiesHint)),
      for (var i = 0; i < list.length; i++)
        _wrap(FadeSlideIn(delay: stagger(i), child: OpportunityCard(opportunity: list[i], onTap: () => _open(list[i].id)))),
    ];
  }

  List<Widget> _workspaces(AppLocalizations l10n) {
    final list = ref.watch(myWorkspacesProvider).whenOrNull(data: (l) => l) ?? const <Workspace>[];
    return [
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      if (list.isEmpty) _wrap(_Empty(icon: Icons.handshake_outlined, title: l10n.dealflow, body: l10n.noWorkspaces)),
      for (var i = 0; i < list.length; i++)
        _wrap(FadeSlideIn(
          delay: stagger(i),
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.cardBorder)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: const CircleAvatar(backgroundColor: Color(0x1A12B8A6), child: Icon(Icons.handshake_rounded, color: AppColors.teal)),
              title: Text(list[i].title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
              subtitle: Text(workspaceStatusLabel(l10n, list[i].status)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkspaceScreen(workspaceId: list[i].id))),
            ),
          ),
        )),
    ];
  }

  List<Widget> _myApplications(AppLocalizations l10n) {
    final apps = ref.watch(myApplicationsProvider).whenOrNull(data: (l) => l) ?? const <Application>[];
    return [
      const SliverToBoxAdapter(child: SizedBox(height: 14)),
      if (apps.isEmpty) _wrap(_Empty(icon: Icons.send_outlined, title: l10n.noMyApplications, body: l10n.noOpportunitiesHint)),
      for (var i = 0; i < apps.length; i++)
        _wrap(FadeSlideIn(
          delay: stagger(i),
          child: Consumer(builder: (context, ref, _) {
            final o = ref.watch(opportunityProvider(apps[i].opportunityId)).whenOrNull(data: (o) => o);
            if (o == null) return const SizedBox.shrink();
            return OpportunityCard(opportunity: o, onTap: () => _open(o.id), badge: StatusPill(apps[i].status));
          }),
        )),
    ];
  }

  Future<void> _showFilters(AppLocalizations l10n) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        void upd(VoidCallback f) {
          setSheet(f);
          setState(() {});
        }

        Widget title(String t) => Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            );
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(l10n.filters, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.deepNavy))),
                TextButton(
                  onPressed: () => upd(() {
                    _filters
                      ..role = null
                      ..category = null
                      ..compensation = null
                      ..genre = ''
                      ..location = ''
                      ..days = null;
                  }),
                  child: Text(l10n.clearFilters),
                ),
              ]),
              title(l10n.filterRole),
              DropdownButtonFormField<String?>(
                initialValue: _filters.role,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allOpportunities)),
                  for (final r in kPassportRoles) DropdownMenuItem(value: r, child: Text(passportRoleLabel(l10n, r))),
                ],
                onChanged: (v) => upd(() => _filters.role = v),
              ),
              title(l10n.filterCategory),
              SingleChoiceChips<String?>(
                options: const [null, ...kOpportunityCategories],
                value: _filters.category,
                label: (c) => c == null ? l10n.allOpportunities : opportunityCategoryLabel(l10n, c),
                onChanged: (v) => upd(() => _filters.category = v),
              ),
              title(l10n.filterCompensation),
              SingleChoiceChips<String?>(
                options: const [null, ...kArrangements],
                value: _filters.compensation,
                label: (c) => c == null ? l10n.allOpportunities : arrangementLabel(l10n, c),
                onChanged: (v) => upd(() => _filters.compensation = v),
              ),
              title(l10n.filterGenre),
              TextFormField(initialValue: _filters.genre, onChanged: (v) => upd(() => _filters.genre = v.trim())),
              title(l10n.filterLocation),
              TextFormField(initialValue: _filters.location, onChanged: (v) => upd(() => _filters.location = v.trim())),
              title(l10n.filterDate),
              SingleChoiceChips<int?>(
                options: const [null, 1, 7, 30],
                value: _filters.days,
                label: (d) => switch (d) {
                  1 => l10n.last24h,
                  7 => l10n.lastWeek,
                  30 => l10n.lastMonth,
                  _ => l10n.anyTime,
                },
                onChanged: (v) => upd(() => _filters.days = v),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.done),
              ),
            ]),
          ),
        );
      }),
    );
  }
}

class _HubTabBar extends StatelessWidget {
  final int selected;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onTap;

  const _HubTabBar({required this.selected, required this.labels, required this.icons, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = selected == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                color: active ? AppColors.deepNavy : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: active ? AppColors.deepNavy : AppColors.cardBorder,
                  width: active ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icons[i], size: 15, color: active ? Colors.white : AppColors.mutedText),
                  const SizedBox(width: 6),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? Colors.white : AppColors.deepNavy,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _SectionTitle(this.text, {this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 10),
        child: Row(children: [
          if (icon != null) ...[Icon(icon, size: 18, color: AppColors.teal), const SizedBox(width: 6)],
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
        ]),
      );
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Empty({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(icon, size: 52, color: AppColors.teal.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.deepNavy)),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
        ]),
      );
}
