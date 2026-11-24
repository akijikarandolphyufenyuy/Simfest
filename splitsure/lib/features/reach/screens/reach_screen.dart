import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../models/campaign.dart';
import '../providers/campaigns_provider.dart';
import 'create_campaign_screen.dart';
import 'campaign_detail_screen.dart';
import 'content_studio_screen.dart';
import '../../subscription/models/subscription.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../../shared/widgets/animations.dart';

class ReachScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const ReachScreen({super.key, this.onBack});
  @override
  ConsumerState<ReachScreen> createState() => _ReachScreenState();
}

class _ReachScreenState extends ConsumerState<ReachScreen> {
  String _filter = 'all';
  static const _filters = ['all', 'draft', 'content_generated', 'ready_to_share', 'completed'];

  List<Campaign> _apply(List<Campaign> l) => _filter == 'all' ? l : l.where((c) => c.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Reach is Pro-only (the database also refuses campaign inserts for Free accounts).
    final ent = ref.watch(entitlementProvider);
    if (!ent.hasValue && ent.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.lightBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }
    if (!(ent.valueOrNull?.isPro ?? false)) return ReachUpgradeGate(onBack: widget.onBack);
    final campaigns = ref.watch(campaignsProvider);
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(slivers: [
        AppSliverHeader(
          title: l10n.reachModuleTitle,
          subtitle: l10n.promotionCampaigns,
          gradient: kTealGradient,
          leading: const HeaderIcon(Icons.campaign_rounded),
          showBack: widget.onBack != null,
          onBackOverride: widget.onBack,
          actions: [
            IconButton(
              tooltip: l10n.contentStudio,
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentStudioScreen())),
            ),
            _HeaderAddButton(label: l10n.newShort, onPressed: () => _openCreate(context)),
          ],
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: _filters.map((f) {
                final sel = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f == 'all' ? l10n.filterAll : campaignStatusLabel(l10n, f)),
                    selected: sel,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.teal,
                    labelStyle: TextStyle(
                        color: sel ? AppColors.white : AppColors.deepNavy, fontSize: 12, fontWeight: FontWeight.w600),
                    backgroundColor: AppColors.white,
                    side: BorderSide(color: sel ? AppColors.teal : AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        campaigns.when(
          loading: () =>
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.teal))),
          error: (e, _) => SliverFillRemaining(child: Center(child: Text(l10n.errorWithDetails('$e')))),
          data: (list) {
            final filtered = _apply(list);
            if (filtered.isEmpty) return SliverFillRemaining(child: _empty(l10n));
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _CampaignCard(
                    campaign: filtered[i],
                    onTap: () => _openDetail(context, filtered[i]),
                    onDelete: () async {
                      await deleteCampaign(filtered[i].id);
                      ref.invalidate(campaignsProvider);
                    },
                  ),
                  childCount: filtered.length,
                ),
              ),
            );
          },
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-reach',
        backgroundColor: AppColors.teal,
        foregroundColor: AppColors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(l10n.newCampaign, style: const TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _openCreate(context),
      ),
    );
  }

  void _openCreate(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCampaignScreen()));
    ref.invalidate(campaignsProvider);
  }

  void _openDetail(BuildContext context, Campaign c) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CampaignDetailScreen(campaign: c)));
    ref.invalidate(campaignsProvider);
  }

  Widget _empty(AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.campaign_outlined, size: 40, color: AppColors.teal),
            ),
            const SizedBox(height: 20),
            Text(l10n.noCampaignsYet,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            const SizedBox(height: 8),
            Text(l10n.noCampaignsHint,
                style: const TextStyle(color: AppColors.mutedText, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _CampaignCard({required this.campaign, required this.onTap, required this.onDelete});

  Color get _color => switch (campaign.status) {
        'completed' => const Color(0xFF38A169),
        'ready_to_share' || 'active' => AppColors.teal,
        'content_generated' => Colors.blue,
        _ => AppColors.mutedText,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.music_note_rounded, color: AppColors.teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(campaign.campaignName ?? campaign.songTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.deepNavy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(campaign.songTitle,
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration:
                    BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(campaignStatusLabel(l10n, campaign.status),
                    style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  onPressed: onDelete,
                  splashRadius: 20),
            ]),
            if (campaign.generatedCaptions != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.teal),
                const SizedBox(width: 6),
                Text(l10n.contentGeneratedLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

class _HeaderAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _HeaderAddButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}

/// Shown instead of Reach for Free accounts.
class ReachUpgradeGate extends ConsumerWidget {
  final VoidCallback? onBack;
  const ReachUpgradeGate({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final price = l10n.amountFcfa('${ref.watch(proPriceProvider)}');
    final benefits = [
      (Icons.campaign_rounded, l10n.reachBenefitCampaigns),
      (Icons.movie_creation_outlined, l10n.reachBenefitVideo),
      (Icons.tag_rounded, l10n.reachBenefitCaptions),
      (Icons.badge_outlined, l10n.reachBenefitBio),
    ];
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(slivers: [
        AppSliverHeader(
          title: l10n.reachModuleTitle,
          subtitle: l10n.promotionCampaigns,
          gradient: kTealGradient,
          leading: const HeaderIcon(Icons.campaign_rounded),
          showBack: onBack != null,
          onBackOverride: onBack,
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                child: FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: kTealGradient),
                          child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.reachProOnlyTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.deepNavy)),
                      const SizedBox(height: 8),
                      Text(l10n.reachProOnlyBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.mutedText, height: 1.45)),
                      const SizedBox(height: 18),
                      for (var i = 0; i < benefits.length; i++)
                        FadeSlideIn(
                          delay: stagger(i + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Icon(benefits[i].$1, color: AppColors.teal, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(benefits[i].$2,
                                      style: const TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w600))),
                            ]),
                          ),
                        ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => startProUpgrade(context, ref),
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: Text(l10n.upgradeNowFor(price), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.oneTimePayment,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
