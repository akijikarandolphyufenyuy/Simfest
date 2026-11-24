import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../projects/screens/projects_screen.dart' show confirmDialog;
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../models/agreement.dart';
import '../providers/agreements_provider.dart';
import 'create_agreement_screen.dart';
import 'agreement_detail_screen.dart';
import '../../../core/services/plan_limits.dart';

class ProtectScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const ProtectScreen({super.key, this.onBack});

  @override
  ConsumerState<ProtectScreen> createState() => _ProtectScreenState();
}

class _ProtectScreenState extends ConsumerState<ProtectScreen> {
  String _filter = 'all';

  static const _filters = ['all', 'draft', 'pending', 'changes_requested', 'accepted', 'declined'];

  List<Agreement> _applyFilter(List<Agreement> list) {
    if (_filter == 'all') return list;
    return list.where((a) => a.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final agreements = ref.watch(agreementsProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: l10n.protectModuleTitle,
            subtitle: l10n.collaborationAgreements,
            leading: const HeaderIcon(Icons.shield_rounded),
            showBack: widget.onBack != null,
            onBackOverride: widget.onBack,
            actions: [
              _HeaderAddButton(label: l10n.newShort, onPressed: () => _openCreate(context)),
            ],
          ),

          // Filter chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: _filters.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f == 'all' ? l10n.filterAll : agreementStatusLabel(l10n, f)),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: AppColors.deepNavy,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.white : AppColors.deepNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.white,
                      side: BorderSide(color: selected ? AppColors.deepNavy : AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          agreements.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
            ),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text(l10n.errorWithDetails('$e')))),
            data: (list) {
              final filtered = _applyFilter(list);
              if (filtered.isEmpty) {
                return SliverFillRemaining(child: _emptyState(l10n));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => FadeSlideIn(
                      delay: stagger(i.clamp(0, 8), 45),
                      child: _AgreementCard(
                        agreement: filtered[i],
                        onTap: () => _openDetail(context, filtered[i]),
                        onDelete: filtered[i].isOwner &&
                                (filtered[i].status == 'draft' || filtered[i].status == 'declined')
                            ? () async {
                                final ok = await confirmDialog(context, l10n.deleteAgreementConfirm);
                                if (!ok) return;
                                try {
                                  await deleteAgreement(filtered[i].id);
                                } catch (e) {
                                  if (context.mounted) showError(context, friendlyError(e));
                                }
                                ref.invalidate(agreementsProvider);
                              }
                            : null,
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-protect',
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(l10n.newAgreement, style: const TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _openCreate(context),
      ),
    );
  }

  void _openCreate(BuildContext context) async {
    // Basic plan: 1 agreement. Ask to upgrade before the form is filled in.
    if (!await checkPlanLimit(context, PlanLimit.agreements) || !context.mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAgreementScreen()));
    ref.invalidate(agreementsProvider);
  }

  void _openDetail(BuildContext context, Agreement agreement) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AgreementDetailScreen(agreement: agreement)));
    ref.invalidate(agreementsProvider);
  }

  Widget _emptyState(AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.deepNavy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.handshake_outlined, size: 40, color: AppColors.deepNavy),
              ),
              const SizedBox(height: 20),
              Text(l10n.noAgreementsYet,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              const SizedBox(height: 8),
              Text(
                l10n.noAgreementsHint,
                style: const TextStyle(color: AppColors.mutedText, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _AgreementCard extends StatelessWidget {
  final Agreement agreement;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _AgreementCard({required this.agreement, required this.onTap, required this.onDelete});

  Color get _statusColor => switch (agreement.status) {
        'accepted' || 'signed' => const Color(0xFF38A169),
        'active' || 'pending' => AppColors.teal,
        'declined' => Colors.redAccent,
        'changes_requested' => Colors.orange,
        _ => AppColors.mutedText,
      };

  IconData get _statusIcon => switch (agreement.status) {
        'accepted' || 'signed' => Icons.verified_rounded,
        'pending' => Icons.hourglass_empty_rounded,
        'declined' => Icons.cancel_outlined,
        'changes_requested' => Icons.edit_note_rounded,
        _ => Icons.edit_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.deepNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note_rounded, color: AppColors.deepNavy, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(agreement.songTitle,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.deepNavy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          [
                            if (agreement.genre != null) agreement.genre!,
                            AppLocalizations.of(context)!
                                .updatedOn(formatDate(agreement.updatedAt ?? agreement.createdAt)),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                        ),
                        if (!agreement.isOwner)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.deepNavy.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(AppLocalizations.of(context)!.sharedWithYou,
                                  style: const TextStyle(
                                      fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, size: 12, color: _statusColor),
                        const SizedBox(width: 4),
                        Text(agreementStatusLabel(AppLocalizations.of(context)!, agreement.status),
                            style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: onDelete,
                      splashRadius: 20,
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
            ),
            if (agreement.splits.isNotEmpty) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Column(
                  children: agreement.splits.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                              child: Text(s.collaboratorName.isNotEmpty ? s.collaboratorName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${s.collaboratorName} · ${musicRoleLabel(AppLocalizations.of(context)!, s.role)}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.deepNavy)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${s.splitPercentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal, fontSize: 12)),
                            ),
                          ],
                        ),
                      )).toList(),
                ),
              ),
            ],
          ],
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
