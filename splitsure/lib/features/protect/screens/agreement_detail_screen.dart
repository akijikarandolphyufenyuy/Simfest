import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/payment_service.dart';
import '../../subscription/models/subscription.dart';
import '../../subscription/widgets/payment_sheet.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../models/agreement.dart';
import '../providers/agreements_provider.dart';
import 'create_agreement_screen.dart';

class AgreementDetailScreen extends ConsumerStatefulWidget {
  /// Initial data (shown instantly); the screen then loads the latest version.
  final Agreement? agreement;
  final String? agreementId;
  const AgreementDetailScreen({super.key, this.agreement, this.agreementId})
      : assert(agreement != null || agreementId != null);

  @override
  ConsumerState<AgreementDetailScreen> createState() => _AgreementDetailScreenState();
}

class _AgreementDetailScreenState extends ConsumerState<AgreementDetailScreen> {
  bool _busy = false;

  String get _id => widget.agreement?.id ?? widget.agreementId!;
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  void _refresh() {
    ref.invalidate(agreementProvider(_id));
    ref.invalidate(agreementVersionsProvider(_id));
    ref.invalidate(agreementResponsesProvider(_id));
    ref.invalidate(agreementsProvider);
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      _refresh();
      if (mounted && success != null) showSuccess(context, success);
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color _statusColor(String s) => switch (s) {
        'accepted' || 'signed' => const Color(0xFF38A169),
        'pending' => AppColors.teal,
        'declined' => Colors.redAccent,
        'changes_requested' => Colors.orange,
        _ => AppColors.mutedText,
      };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(agreementProvider(_id));
    final a = async.whenOrNull(data: (a) => a) ?? widget.agreement;

    if (a == null) {
      return Scaffold(
        backgroundColor: AppColors.lightBg,
        appBar: const GradientAppBar(title: ''),
        body: Center(
          child: async.hasError
              ? Text(l10n.errorWithDetails('${async.error}'))
              : const CircularProgressIndicator(color: AppColors.teal),
        ),
      );
    }

    final color = _statusColor(a.status);
    final mine = a.mySplit;
    final accepted = a.splits.where((s) => s.response == 'accepted').length;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Stack(children: [
        RefreshIndicator(
          color: AppColors.teal,
          onRefresh: () async => _refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              AppSliverHeader(
                title: a.songTitle,
                subtitle: '${a.displayReference} · ${l10n.versionShort(a.version)}',
                showBack: true,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 6, bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
                    child: Text(agreementStatusLabel(l10n, a.status),
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeSlideIn(child: _progressCard(a, accepted, color)),
                    const SizedBox(height: 14),
                    if (mine != null && a.isOpenForResponses && mine.response == null)
                      FadeSlideIn(delay: stagger(1), child: _myResponseCard(a, mine)),
                    if (a.isMyWitness && a.witnessInvited && a.isOpenForResponses && a.witnessResponse == null)
                      FadeSlideIn(delay: stagger(1), child: _witnessResponseCard(a)),
                    if (mine != null && mine.response != null) ...[
                      _Card(
                        title: l10n.yourResponse,
                        child: _ResponseChip(response: mine.response!, note: mine.responseNote, date: mine.respondedAt),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (a.isOwner) ...[
                      FadeSlideIn(delay: stagger(1), child: _ownerActions(a)),
                      const SizedBox(height: 14),
                    ],
                    if (a.isOwner && a.splits.any((s) => s.response == 'changes_requested')) _changeRequests(a),
                    _Card(
                      title: l10n.collaboratorsAndSplits,
                      child: Column(children: [
                        for (final s in a.splits) _CollaboratorRow(agreement: a, split: s),
                        const Divider(height: 18),
                        Row(children: [
                          Text(l10n.totalLabel,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                          const Spacer(),
                          Text('${a.totalPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: (a.totalPercentage - 100).abs() < 0.001 ? AppColors.teal : Colors.red,
                              )),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    _Card(
                      title: l10n.songDetails,
                      child: Column(children: [
                        if (a.genre != null) _InfoRow(l10n.genre, a.genre!),
                        if (a.description != null) _InfoRow(l10n.description, a.description!),
                        if (a.recordingDate != null) _InfoRow(l10n.recordingDate, formatDate(a.recordingDate)),
                        if (a.releaseDate != null) _InfoRow(l10n.releaseDate, formatDate(a.releaseDate)),
                        if (a.effectiveDate != null) _InfoRow(l10n.effectiveDate, formatDate(a.effectiveDate)),
                        _InfoRow(l10n.created, formatDate(a.createdAt)),
                        if (a.finalizedAt != null) _InfoRow(l10n.finalizedOn, formatDate(a.finalizedAt)),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    if (a.scopeCategories.isNotEmpty || a.scopeOfRights != null) ...[
                      _Card(
                        title: l10n.scopeOfRights,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (a.scopeCategories.isNotEmpty)
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              for (final c in a.scopeCategories)
                                Chip(
                                  label: Text(scopeCategoryLabel(l10n, c)),
                                  labelStyle:
                                      const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600),
                                  backgroundColor: AppColors.teal.withValues(alpha: 0.08),
                                  side: BorderSide.none,
                                  visualDensity: VisualDensity.compact,
                                ),
                            ]),
                          if (a.scopeOfRights != null) ...[
                            const SizedBox(height: 8),
                            _Body(a.scopeOfRights!),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (a.paymentTerms != null) ...[
                      _Card(title: l10n.paymentTerms, child: _Body(a.paymentTerms!)),
                      const SizedBox(height: 14),
                    ],
                    if (a.additionalTerms != null) ...[
                      _Card(title: l10n.additionalTerms, child: _Body(a.additionalTerms!)),
                      const SizedBox(height: 14),
                    ],
                    if (a.witnessName != null) ...[
                      _Card(
                        title: l10n.witness,
                        child: Column(children: [
                          if (a.witnessInvited) _witnessStatus(a),
                          if (a.isOwner && !a.witnessInvited && a.isOpenForResponses && (a.witnessEmail?.trim().isNotEmpty ?? false))
                            _askWitnessButton(a),
                          _InfoRow(l10n.name, a.witnessName!),
                          if (a.witnessEmail != null) _InfoRow(l10n.emailShort, a.witnessEmail!),
                          if (a.witnessPhone != null) _InfoRow(l10n.phone, a.witnessPhone!),
                          if (a.witnessRole != null) _InfoRow(l10n.role, a.witnessRole!),
                        ]),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (a.lawyerName != null) ...[
                      _Card(
                        title: l10n.legalRepresentative,
                        child: Column(children: [
                          _InfoRow(l10n.name, a.lawyerName!),
                          if (a.lawyerFirm != null) _InfoRow(l10n.firm, a.lawyerFirm!),
                          if (a.lawyerEmail != null) _InfoRow(l10n.emailShort, a.lawyerEmail!),
                          if (a.lawyerPhone != null) _InfoRow(l10n.phone, a.lawyerPhone!),
                          if (a.lawyerRegistration != null) _InfoRow(l10n.registration, a.lawyerRegistration!),
                        ]),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _historyCard(a),
                    const SizedBox(height: 14),
                    _Card(
                      title: l10n.exportAndShare,
                      child: Column(children: [
                        _finalAgreementButton(a),
                        const SizedBox(height: 8),
                        _ExportButton(
                          icon: Icons.picture_as_pdf_outlined,
                          label: l10n.previewPdf,
                          subtitle: switch (ref.watch(agreementDocAccessProvider(a.id)).whenOrNull(data: (v) => v)) {
                            'pay' => l10n.previewPdfFeeSubtitle(l10n.amountFcfa('50')),
                            'unlocked' => l10n.previewPdfUnlocked,
                            _ => l10n.previewPdfSubtitle,
                          },
                          onTap: () => _downloadPdf(a),
                        ),
                        const SizedBox(height: 8),
                        _ExportButton(
                          icon: Icons.copy_outlined,
                          label: l10n.copyAgreementId,
                          subtitle: a.displayReference,
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: a.displayReference));
                            showSuccess(context, l10n.agreementIdCopied);
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Text(l10n.recordKeepingDisclaimer,
                          style: const TextStyle(fontSize: 12, color: Colors.deepOrange, height: 1.5)),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        if (_busy)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.12),
              child: const Center(child: CircularProgressIndicator(color: AppColors.teal)),
            ),
          ),
      ]),
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────

  Widget _progressCard(Agreement a, int accepted, Color color) {
    final total = a.splits.length;
    final ratio = total == 0 ? 0.0 : accepted / total;
    final message = switch (a.status) {
      'draft' => l10n.draftExplain,
      'pending' => l10n.pendingExplain(accepted, total),
      'changes_requested' => l10n.changesRequestedExplain,
      'declined' => l10n.declinedExplain,
      'accepted' => l10n.acceptedExplain,
      _ => '',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
            switch (a.status) {
              'accepted' => Icons.verified_rounded,
              'declined' => Icons.cancel_rounded,
              'changes_requested' => Icons.edit_note_rounded,
              'pending' => Icons.hourglass_top_rounded,
              _ => Icons.edit_document,
            },
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(agreementStatusLabel(l10n, a.status),
                style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15)),
          ),
          if (a.status != 'draft')
            Text(l10n.acceptedOfTotal(accepted, total),
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontWeight: FontWeight.w600)),
        ]),
        if (a.status != 'draft') ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 7,
                backgroundColor: AppColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText, height: 1.45)),
      ]),
    );
  }

  Widget _myResponseCard(Agreement a, AgreementSplit mine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: kNavyGradient, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.yourResponseNeeded,
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 4),
        Text(
          l10n.yourShareIs('${mine.splitPercentage.toStringAsFixed(0)}%', musicRoleLabel(l10n, mine.role)),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _PillButton(
              label: l10n.accept,
              icon: Icons.check_rounded,
              color: const Color(0xFF38A169),
              onTap: () async {
                final ok = await _confirm(l10n.acceptConfirm);
                if (ok) {
                  await _run(() => respondToAgreement(mine.id, 'accepted'), success: l10n.responseSentAccepted);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PillButton(
              label: l10n.requestChanges,
              icon: Icons.edit_note_rounded,
              color: Colors.orange,
              onTap: () async {
                final note = await _askNote(l10n.requestChanges, l10n.describeChanges, required: true);
                if (note != null) {
                  await _run(() => respondToAgreement(mine.id, 'changes_requested', note: note),
                      success: l10n.responseSentChanges);
                }
              },
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () async {
              final note = await _askNote(l10n.decline, l10n.declineReasonOptional, required: false);
              if (note != null) {
                await _run(() => respondToAgreement(mine.id, 'declined', note: note.isEmpty ? null : note),
                    success: l10n.responseSentDeclined);
              }
            },
            child: Text(l10n.decline, style: const TextStyle(color: Color(0xFFFFB4B4), fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _witnessStatus(Agreement a) {
    final (label, color, icon) = switch (a.witnessResponse) {
      'confirmed' => (l10n.witnessConfirmed, AppColors.success, Icons.verified_rounded),
      'declined' => (l10n.witnessDeclined, Colors.redAccent, Icons.cancel_rounded),
      _ => (l10n.witnessWaiting, Colors.orange, Icons.hourglass_top_rounded),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13))),
          if (a.witnessRespondedAt != null)
            Text(formatDate(a.witnessRespondedAt), style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
        ]),
        if (a.witnessSignatureCode != null) ...[
          const SizedBox(height: 6),
          SelectableText('${l10n.witnessCode}: ${a.witnessSignatureCode}',
              style: const TextStyle(fontSize: 12, color: AppColors.deepNavy, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ],
        if (a.witnessNote != null) ...[
          const SizedBox(height: 6),
          Text(a.witnessNote!, style: const TextStyle(fontSize: 12, color: AppColors.mutedText, height: 1.4)),
        ],
      ]),
    );
  }

  Widget _askWitnessButton(Agreement a) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.witnessNotAskedYet, style: const TextStyle(fontSize: 12.5, color: AppColors.deepNavy, height: 1.45)),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () async {
            final ok = await _confirm(l10n.askWitnessConfirm);
            if (!ok) return;
            bool? emailed;
            await _run(() async => emailed = await inviteWitness(a.id));
            if (mounted && emailed != null) {
              showSuccess(context, emailed! ? l10n.witnessAskedEmailed : l10n.witnessAskedInApp);
            }
          },
          icon: const Icon(Icons.how_to_reg_rounded, size: 18),
          label: Text(l10n.askWitnessButton),
        ),
      ]),
    );
  }

  Widget _witnessResponseCard(Agreement a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: kNavyGradient, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.how_to_reg_rounded, color: AppColors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.witnessResponseNeeded,
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(l10n.witnessResponseIntro, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _PillButton(
              label: l10n.witnessConfirmButton,
              icon: Icons.check_rounded,
              color: const Color(0xFF38A169),
              onTap: () async {
                final ok = await _confirm(l10n.witnessConfirmQuestion);
                if (ok) {
                  await _run(() => respondAsWitness(a.id, 'confirmed'), success: l10n.witnessConfirmedToast);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PillButton(
              label: l10n.decline,
              icon: Icons.close_rounded,
              color: Colors.redAccent,
              onTap: () async {
                final note = await _askNote(l10n.decline, l10n.declineReasonOptional, required: false);
                if (note != null) {
                  await _run(() => respondAsWitness(a.id, 'declined', note: note.isEmpty ? null : note),
                      success: l10n.witnessDeclinedToast);
                }
              },
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _ownerActions(Agreement a) {
    final canSend = a.status == 'draft' && a.splits.isNotEmpty && (a.totalPercentage - 100).abs() < 0.001;
    return _Card(
      title: l10n.agreementActions,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (a.status == 'draft') ...[
          ElevatedButton.icon(
            onPressed: canSend
                ? () async {
                    final ok = await _confirm(l10n.sendForReviewConfirm);
                    if (!ok) return;
                    SendResult? r;
                    await _run(() async => r = await sendForReview(a.id));
                    if (mounted && r != null) {
                      showSuccess(context, r!.emailed > 0 ? l10n.sentForReviewEmailed(r!.emailed) : l10n.sentForReview);
                    }
                  }
                : null,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(l10n.sendForReview),
          ),
          if (!canSend) ...[
            const SizedBox(height: 6),
            Text(l10n.splitsMustReach100, style: const TextStyle(fontSize: 12, color: Colors.orange)),
          ],
          const SizedBox(height: 10),
        ],
        Row(children: [
          if (a.isEditable)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAgreementScreen(agreement: a)));
                  _refresh();
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(a.status == 'draft' ? l10n.edit : l10n.editAndResend, overflow: TextOverflow.ellipsis),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
              ),
            ),
          if (a.status == 'draft' || a.status == 'declined') ...[
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await _confirm(l10n.deleteAgreementConfirm, destructive: true);
                  if (!ok) return;
                  await _run(() => deleteAgreement(a.id));
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                label: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ]),
        if (a.status == 'accepted')
          Text(l10n.acceptedLocked, style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText)),
      ]),
    );
  }

  Widget _changeRequests(Agreement a) {
    final requests = a.splits.where((s) => s.response == 'changes_requested').toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.changeRequests,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.deepOrange, fontSize: 14)),
          const SizedBox(height: 8),
          for (final s in requests) ...[
            Text(s.collaboratorName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
            if (s.responseNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Text('“${s.responseNote}”',
                    style: const TextStyle(fontSize: 13, color: AppColors.deepNavy, height: 1.4)),
              ),
          ],
          Text(l10n.changeRequestsHint, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        ]),
      ),
    );
  }

  Widget _historyCard(Agreement a) {
    final versions = ref.watch(agreementVersionsProvider(a.id)).whenOrNull(data: (l) => l) ?? [];
    final responses = ref.watch(agreementResponsesProvider(a.id)).whenOrNull(data: (l) => l) ?? [];
    if (versions.isEmpty && responses.isEmpty) return const SizedBox.shrink();
    String nameFor(String splitId) =>
        a.splits.where((s) => s.id == splitId).map((s) => s.collaboratorName).firstOrNull ?? '—';
    return _Card(
      title: l10n.versionHistory,
      child: Column(children: [
        for (final v in versions)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
              leading: CircleAvatar(
                radius: 15,
                backgroundColor: v.version == a.version ? AppColors.teal : AppColors.cardBorder,
                child: Text('v${v.version}',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: v.version == a.version ? AppColors.white : AppColors.deepNavy)),
              ),
              title: Text(l10n.versionSentOn(v.version, formatDate(v.createdAt)),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepNavy)),
              subtitle: v.changeNote != null
                  ? Text(v.changeNote!,
                      style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)
                  : null,
              children: [
                for (final r in responses.where((r) => r.version == v.version))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(_responseIcon(r.response), size: 16, color: _statusColor(r.response)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${nameFor(r.splitId)} · ${agreementStatusLabel(l10n, r.response)} · ${formatDate(r.createdAt)}'
                          '${r.note != null ? '\n“${r.note}”' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.deepNavy, height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                if (!responses.any((r) => r.version == v.version))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.noResponsesYet, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  ),
              ],
            ),
          ),
      ]),
    );
  }

  IconData _responseIcon(String r) => switch (r) {
        'accepted' => Icons.check_circle_rounded,
        'declined' => Icons.cancel_rounded,
        _ => Icons.edit_note_rounded,
      };

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _finalAgreementButton(Agreement a) {
    final doc = ref.watch(agreementDocumentProvider(a.id)).whenOrNull(data: (d) => d);
    final isPro = ref.watch(entitlementProvider).whenOrNull(data: (e) => e.isPro) ?? false;
    final access = ref.watch(agreementDocAccessProvider(a.id)).whenOrNull(data: (v) => v);
    final fee = l10n.amountFcfa('50');
    final accepted = a.status == 'accepted';
    return _ExportButton(
      icon: doc != null ? Icons.verified_rounded : Icons.workspace_premium_outlined,
      label: doc?.pdfPath != null ? l10n.downloadFinalAgreement : l10n.generateFinalAgreement,
      subtitle: !accepted
          ? l10n.finalAgreementNeedsAcceptance
          : doc != null
              ? l10n.finalAgreementReady
              : access == 'free'
                  ? (isPro ? l10n.finalAgreementFree : l10n.finalAgreementFirstFree)
                  : access == 'unlocked'
                      ? l10n.previewPdfUnlocked
                      : l10n.finalAgreementFee(fee),
      onTap: accepted ? () => _generateFinal(a, doc) : null,
    );
  }

  /// Pro and the creator's first agreement: unlocked on the server for free.
  /// Otherwise 50 FCFA (once per agreement), verified server-side.
  /// The document is generated once and stored for every party.
  Future<void> _generateFinal(Agreement a, AgreementDocument? doc) async {
    setState(() => _busy = true);
    try {
      if (doc == null) {
        final access = await ref.read(agreementDocAccessProvider(a.id).future);
        if (access == 'free') {
          await unlockAgreementFree(a.id);
        } else if (access == 'pay') {
          setState(() => _busy = false);
          if (!await _payForDocument(a, l10n.generateFinalAgreement)) return;
          setState(() => _busy = true);
        }
        ref.invalidate(agreementDocumentProvider(a.id));
        doc = await ref.read(agreementDocumentProvider(a.id).future);
        if (doc == null) return;
      }
      await downloadFinalAgreement(a, l10n, storedPath: doc.pdfPath);
      ref.invalidate(agreementDocumentProvider(a.id));
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 50 FCFA payment that unlocks this agreement's PDF (preview and download) for every party.
  Future<bool> _payForDocument(Agreement a, String title) async {
    final paid = await showPaymentSheet(
      context,
      type: PaymentType.agreementGeneration,
      amountFcfa: 50,
      title: title,
      targetId: a.id,
    );
    ref.invalidate(agreementDocAccessProvider(a.id));
    ref.invalidate(agreementDocumentProvider(a.id));
    return paid;
  }

  /// Preview: free on Pro and for the creator's first agreement; otherwise paid once (50 FCFA).
  Future<void> _downloadPdf(Agreement a) async {
    setState(() => _busy = true);
    try {
      final access = await ref.read(agreementDocAccessProvider(a.id).future);
      if (access == 'pay') {
        setState(() => _busy = false);
        if (!await _payForDocument(a, l10n.payToPreviewTitle)) return;
        setState(() => _busy = true);
      }
      await downloadAgreementPreview(a, l10n);
    } catch (e) {
      if (mounted) showError(context, l10n.pdfError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String message, {bool destructive = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: destructive ? Colors.redAccent : AppColors.teal),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Returns the typed note ('' allowed when not required) or null if cancelled.
  Future<String?> _askNote(String title, String label, {required bool required}) async {
    final c = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: c,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
            validator: (v) => required && (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, c.text.trim());
            },
            child: Text(l10n.send),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 13, color: AppColors.deepNavy, height: 1.5));
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText))),
        Expanded(
          child:
              Text(value, style: const TextStyle(fontSize: 13, color: AppColors.deepNavy, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.white, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  const _ExportButton({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Icon(icon, color: AppColors.deepNavy, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.deepNavy)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedText, size: 18),
          ]),
        ),
      ),
    );
  }
}

class _ResponseChip extends StatelessWidget {
  final String response;
  final String? note;
  final DateTime? date;
  const _ResponseChip({required this.response, this.note, this.date});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = switch (response) {
      'accepted' => const Color(0xFF38A169),
      'declined' => Colors.redAccent,
      _ => Colors.orange,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(
          '${agreementStatusLabel(l10n, response)}${date != null ? ' · ${formatDate(date)}' : ''}',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700),
        ),
      ),
      if (note != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('“$note”', style: const TextStyle(fontSize: 12.5, color: AppColors.deepNavy)),
        ),
    ]);
  }
}

class _CollaboratorRow extends StatelessWidget {
  final Agreement agreement;
  final AgreementSplit split;
  const _CollaboratorRow({required this.agreement, required this.split});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = split;
    final myEmail = (Supabase.instance.client.auth.currentUser?.email ?? '').toLowerCase();
    final isMe = s.userId == Supabase.instance.client.auth.currentUser?.id ||
        (s.collaboratorEmail != null && s.collaboratorEmail!.toLowerCase() == myEmail);
    final showInvite =
        agreement.isOwner && !isMe && !s.isLinked && s.inviteToken != null && agreement.status != 'accepted';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.teal.withValues(alpha: 0.12),
            child: Text(s.collaboratorName.isNotEmpty ? s.collaboratorName[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.teal)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.collaboratorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              Text(
                [musicRoleLabel(l10n, s.role), if (s.contributionDescription != null) s.contributionDescription!]
                    .join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration:
                BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('${s.splitPercentage.toStringAsFixed(s.splitPercentage % 1 == 0 ? 0 : 1)}%',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal, fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (agreement.status != 'draft')
              s.response != null
                  ? _ResponseChip(response: s.response!, date: s.respondedAt)
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppColors.mutedText.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(l10n.awaitingResponse,
                          style:
                              const TextStyle(fontSize: 12, color: AppColors.mutedText, fontWeight: FontWeight.w600)),
                    ),
            if (s.response == 'accepted' && s.signatureCode != null)
              Tooltip(
                message: s.signedVia == 'email' ? l10n.signedViaEmail : l10n.signedViaApp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(s.signedVia == 'email' ? Icons.mark_email_read_rounded : Icons.draw_rounded,
                        size: 14, color: AppColors.teal),
                    const SizedBox(width: 6),
                    SelectableText(s.signatureCode!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.deepNavy, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  ]),
                ),
              ),
            if (showInvite)
              ActionChip(
                avatar: const Icon(Icons.link_rounded, size: 16, color: AppColors.deepNavy),
                label: Text(l10n.copyInviteLink),
                labelStyle: const TextStyle(fontSize: 12, color: AppColors.deepNavy, fontWeight: FontWeight.w600),
                backgroundColor: AppColors.lightBg,
                side: const BorderSide(color: AppColors.cardBorder),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteLink(s)));
                  showSuccess(context, l10n.inviteLinkCopied(s.collaboratorName));
                },
              ),
          ]),
        ),
      ]),
    );
  }
}
