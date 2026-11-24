import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../hub/models/opportunity.dart';
import '../../hub/screens/opportunity_detail_screen.dart';
import '../../hub/widgets/opportunity_card.dart';
import '../../protect/models/agreement.dart';
import '../../protect/providers/agreements_provider.dart';
import '../../protect/screens/agreement_detail_screen.dart';

/// Agreements every party approved, where the user is the creator, a collaborator or the witness.
List<Agreement> successfulCollaborations(List<Agreement> all) => all.where((a) => a.status == 'accepted').toList();

/// Hub applications of the user that the poster accepted.
List<Application> acceptedApplications(List<Application> all) => all.where((a) => a.status == 'accepted').toList();

/// "Successful collaborations": every fully approved agreement.
class SuccessfulCollaborationsScreen extends ConsumerWidget {
  const SuccessfulCollaborationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(agreementsProvider);
    final list = successfulCollaborations(async.whenOrNull(data: (l) => l) ?? const <Agreement>[]);
    return _ListScaffold(
      title: l10n.successfulCollaborations,
      subtitle: l10n.successfulCollaborationsHint,
      icon: Icons.handshake_rounded,
      loading: async.isLoading && list.isEmpty,
      onRefresh: () async => ref.invalidate(agreementsProvider),
      emptyIcon: Icons.handshake_outlined,
      emptyText: l10n.noSuccessfulCollaborations,
      children: [
        for (var i = 0; i < list.length; i++)
          FadeSlideIn(
            delay: stagger(i),
            child: _AgreementTile(
              agreement: list[i],
              onTap: () async {
                await Navigator.push(
                    context, MaterialPageRoute(builder: (_) => AgreementDetailScreen(agreement: list[i])));
                ref.invalidate(agreementsProvider);
              },
            ),
          ),
      ],
    );
  }
}

/// "Accepted collaborations": opportunities the user applied to and was taken for.
class AcceptedCollaborationsScreen extends ConsumerWidget {
  const AcceptedCollaborationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(myApplicationsProvider);
    final list = acceptedApplications(async.whenOrNull(data: (l) => l) ?? const <Application>[]);
    return _ListScaffold(
      title: l10n.acceptedCollaborations,
      subtitle: l10n.acceptedCollaborationsHint,
      icon: Icons.verified_rounded,
      loading: async.isLoading && list.isEmpty,
      onRefresh: () async => ref.invalidate(myApplicationsProvider),
      emptyIcon: Icons.send_outlined,
      emptyText: l10n.noAcceptedCollaborations,
      children: [
        for (var i = 0; i < list.length; i++)
          FadeSlideIn(
            delay: stagger(i),
            child: Consumer(builder: (context, ref, _) {
              final o = ref.watch(opportunityProvider(list[i].opportunityId)).whenOrNull(data: (o) => o);
              if (o == null) return const SizedBox.shrink();
              return OpportunityCard(
                opportunity: o,
                badge: StatusPill(list[i].status),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => OpportunityDetailScreen(opportunityId: o.id))),
              );
            }),
          ),
      ],
    );
  }
}

class _ListScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool loading;
  final Future<void> Function() onRefresh;
  final IconData emptyIcon;
  final String emptyText;
  final List<Widget> children;

  const _ListScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.loading,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: onRefresh,
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          AppSliverHeader(title: title, subtitle: subtitle, leading: HeaderIcon(icon), showBack: true),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
                      )
                    else if (children.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                        child: Column(children: [
                          Icon(emptyIcon, size: 54, color: AppColors.mutedText.withValues(alpha: 0.6)),
                          const SizedBox(height: 12),
                          Text(emptyText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.mutedText, fontSize: 14, height: 1.5)),
                        ]),
                      )
                    else
                      ...children,
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AgreementTile extends StatelessWidget {
  final Agreement agreement;
  final VoidCallback onTap;
  const _AgreementTile({required this.agreement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = agreement;
    final names = a.splits.map((s) => s.collaboratorName).where((n) => n.trim().isNotEmpty).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_rounded, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.songTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.deepNavy)),
                  const SizedBox(height: 2),
                  Text(names,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  const SizedBox(height: 2),
                  Text('${a.displayReference} · ${l10n.finalizedOn} ${formatDate(a.finalizedAt ?? a.updatedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
            ]),
          ),
        ),
      ),
    );
  }
}
