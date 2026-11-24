import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../passport/models/passport.dart';
import '../../passport/widgets/passport_sheet.dart';
import '../../protect/screens/agreement_detail_screen.dart';
import '../../protect/screens/create_agreement_screen.dart';
import '../models/workspace.dart';
import '../../../core/services/plan_limits.dart';

/// DealFlow: negotiate roles, responsibilities and percentages, then continue in Protect.
class WorkspaceScreen extends ConsumerStatefulWidget {
  final String workspaceId;
  const WorkspaceScreen({super.key, required this.workspaceId});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final _msg = TextEditingController();
  bool _busy = false;

  String get _id => widget.workspaceId;

  void _refresh() {
    ref.invalidate(workspaceProvider(_id));
    ref.invalidate(workspaceMembersProvider(_id));
    ref.invalidate(myWorkspacesProvider);
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
      _refresh();
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msg.text.trim();
    if (text.isEmpty) return;
    _msg.clear();
    try {
      await sendWorkspaceMessage(_id, text);
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    }
  }

  Future<void> _continueInProtect(Workspace w, List<WorkspaceMember> members) async {
    if (!await checkPlanLimit(context, PlanLimit.agreements) || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAgreementScreen(
          prefill: AgreementPrefill(
            workspaceId: w.id,
            title: w.title,
            description: [w.description, if (w.deliverables?.isNotEmpty ?? false) w.deliverables].whereType<String>().join('\n\n'),
            paymentTerms: w.paymentArrangement,
            members: [
              for (final m in members)
                (
                  userId: m.userId,
                  name: m.displayName,
                  role: m.role ?? '',
                  responsibilities: m.responsibilities,
                  percentage: m.percentage ?? 0,
                ),
            ],
          ),
        ),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final w = ref.watch(workspaceProvider(_id)).whenOrNull(data: (w) => w);
    final members = ref.watch(workspaceMembersProvider(_id)).whenOrNull(data: (m) => m) ?? const <WorkspaceMember>[];
    final messages = ref.watch(workspaceMessagesProvider(_id)).whenOrNull(data: (m) => m) ?? const <WorkspaceMessage>[];
    final total = members.fold<double>(0, (s, m) => s + (m.percentage ?? 0));
    final me = members.where((m) => m.isMe).firstOrNull;
    final names = {for (final m in members) m.userId: m.displayName};

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async => _refresh(),
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          AppSliverHeader(
            title: w?.title ?? l10n.dealflow,
            subtitle: w == null ? l10n.dealflowTagline : '${l10n.dealflow} · ${workspaceStatusLabel(l10n, w.status)}',
            leading: const HeaderIcon(Icons.handshake_rounded),
            showBack: true,
          ),
          if (w != null)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      FadeSlideIn(child: _Overview(w: w, ownerName: names[w.ownerId] ?? '')),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: stagger(1),
                        child: _Card(
                          title: l10n.participants,
                          trailing: Text(l10n.totalPercent(total.toStringAsFixed(total % 1 == 0 ? 0 : 2)),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: (total - 100).abs() < 0.001 ? AppColors.success : Colors.orange,
                              )),
                          child: Column(children: [
                            for (final m in members)
                              _MemberTile(
                                member: m,
                                canEdit: w.termsEditable && (w.isOwner || m.isMe),
                                onEdit: () => _editTerms(w, m),
                              ),
                            if ((total - 100).abs() >= 0.001 && w.termsEditable)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(l10n.totalMustBe100,
                                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: Colors.orange)),
                              ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeSlideIn(delay: stagger(2), child: _actions(l10n, w, members, me, total)),
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        delay: stagger(3),
                        child: _Card(
                          title: l10n.discussion,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            for (final m in messages) _Bubble(message: m, name: names[m.userId] ?? '', mine: m.userId == me?.userId),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                child: TextField(
                                  controller: _msg,
                                  minLines: 1,
                                  maxLines: 4,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _send(),
                                  decoration: InputDecoration(hintText: l10n.writeMessage, isDense: true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                style: IconButton.styleFrom(backgroundColor: AppColors.teal),
                                onPressed: _send,
                                icon: const Icon(Icons.send_rounded, color: Colors.white),
                                tooltip: l10n.send,
                              ),
                            ]),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator(color: AppColors.teal))),
            ),
        ]),
      ),
    );
  }

  Widget _actions(AppLocalizations l10n, Workspace w, List<WorkspaceMember> members, WorkspaceMember? me, double total) {
    final children = <Widget>[];
    if (!w.termsEditable) {
      children.add(Text(l10n.termsLocked, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)));
    } else if (me != null) {
      children.add(me.agreed
          ? OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(() => setTermsAgreed(w.id, false)),
              icon: const Icon(Icons.undo_rounded),
              label: Text(l10n.withdrawAgreement),
            )
          : FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _busy || (total - 100).abs() >= 0.001 ? null : () => _run(() => setTermsAgreed(w.id, true)),
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(l10n.iAgree),
            ));
    }
    if (w.status == 'agreed' && w.isOwner) {
      children.addAll([
        const SizedBox(height: 12),
        Text(l10n.continueInProtectHint, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 15)),
          onPressed: () => _continueInProtect(w, members),
          icon: const Icon(Icons.shield_rounded),
          label: Text(l10n.continueInProtect),
        ),
      ]);
    }
    if (w.agreementId != null) {
      children.addAll([
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.deepNavy, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => AgreementDetailScreen(agreementId: w.agreementId!))),
          icon: const Icon(Icons.description_rounded),
          label: Text(l10n.openAgreement),
        ),
      ]);
    }
    if (w.isOwner && (w.status == 'in_protect' || w.status == 'active')) {
      children.addAll([
        const SizedBox(height: 8),
        Row(children: [
          if (w.status == 'in_protect')
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _run(() => setWorkspaceStatus(w.id, 'active')),
                child: Text(l10n.markActive),
              ),
            ),
          if (w.status == 'in_protect') const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () => _run(() => setWorkspaceStatus(w.id, 'completed')),
              child: Text(l10n.markCompleted),
            ),
          ),
        ]),
      ]);
    }
    if (w.isOwner && w.status != 'completed' && w.status != 'cancelled') {
      children.add(TextButton(
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
        onPressed: _busy ? null : () => _run(() => setWorkspaceStatus(w.id, 'cancelled')),
        child: Text(l10n.cancelWorkspace),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Future<void> _editTerms(Workspace w, WorkspaceMember m) async {
    final l10n = AppLocalizations.of(context)!;
    final role = TextEditingController(text: m.role);
    final resp = TextEditingController(text: m.responsibilities);
    final pct = TextEditingController(text: m.percentage == null ? '' : m.percentage!.toStringAsFixed(m.percentage! % 1 == 0 ? 0 : 2));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('${l10n.proposeTerms} · ${m.displayName}', textAlign: TextAlign.center),
        content: SizedBox(
          width: 420,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Autocomplete<String>(
              initialValue: TextEditingValue(text: m.role ?? ''),
              optionsBuilder: (v) => kPassportRoles.where((r) => r.toLowerCase().contains(v.text.toLowerCase())),
              onSelected: (v) => role.text = v,
              fieldViewBuilder: (ctx, c, f, s) => TextField(
                controller: c,
                focusNode: f,
                onChanged: (v) => role.text = v,
                decoration: InputDecoration(labelText: l10n.role),
              ),
            ),
            const SizedBox(height: 10),
            TextField(controller: resp, maxLines: 3, decoration: InputDecoration(labelText: l10n.responsibilities)),
            const SizedBox(height: 10),
            TextField(
              controller: pct,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: InputDecoration(labelText: l10n.contributionPercent, suffixText: '%'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (ok == true) {
      final p = double.tryParse(pct.text.replaceAll(',', '.'));
      await _run(() => updateMemberTerms(
            w.id,
            m.userId,
            role: role.text.trim().isEmpty ? null : role.text.trim(),
            responsibilities: resp.text.trim().isEmpty ? null : resp.text.trim(),
            percentage: p?.clamp(0, 100).toDouble(),
          ));
    }
  }
}

class _Overview extends StatelessWidget {
  final Workspace w;
  final String ownerName;
  const _Overview({required this.w, required this.ownerName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget row(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(color: AppColors.deepNavy, height: 1.4)),
            ]),
          );
    return _Card(
      title: w.title,
      trailing: Text(workspaceStatusLabel(l10n, w.status), style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${l10n.projectOwner}: $ownerName · ${formatDate(w.createdAt)}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText)),
        row(l10n.projectDescription, w.description),
        row(l10n.expectedDeliverables, w.deliverables),
        row(l10n.paymentArrangement, w.paymentArrangement),
        row(l10n.importantDates, w.importantDates),
      ]),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final WorkspaceMember member;
  final bool canEdit;
  final VoidCallback onEdit;
  const _MemberTile({required this.member, required this.canEdit, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = member;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => showPassportSheet(context, m.userId),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: (m.isOwner ? AppColors.deepNavy : AppColors.teal).withValues(alpha: 0.12),
            child: Text(m.displayName.isEmpty ? '?' : m.displayName[0].toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.w800, color: m.isOwner ? AppColors.deepNavy : AppColors.teal)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(m.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
              ),
              const SizedBox(width: 6),
              Icon(m.agreed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16, color: m.agreed ? AppColors.success : AppColors.mutedText),
              const SizedBox(width: 3),
              Text(m.agreed ? l10n.agreedBadge : l10n.notAgreedYet,
                  style: TextStyle(fontSize: 11.5, color: m.agreed ? AppColors.success : AppColors.mutedText)),
            ]),
            if (m.role?.isNotEmpty ?? false)
              Text(passportRoleLabel(l10n, m.role!), style: const TextStyle(fontSize: 12.5, color: AppColors.teal)),
            if (m.responsibilities?.isNotEmpty ?? false)
              Text(m.responsibilities!, style: const TextStyle(fontSize: 12.5, color: AppColors.deepNavy)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(m.percentage == null ? '—' : '${m.percentage!.toStringAsFixed(m.percentage! % 1 == 0 ? 0 : 2)}%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.deepNavy)),
          if (canEdit)
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
              onPressed: onEdit,
              child: Text(l10n.editTerms, style: const TextStyle(fontSize: 12)),
            ),
        ]),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final WorkspaceMessage message;
  final String name;
  final bool mine;
  const _Bubble({required this.message, required this.name, required this.mine});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? AppColors.teal : AppColors.lightBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!mine) Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          Text(message.body, style: TextStyle(color: mine ? Colors.white : AppColors.deepNavy)),
          Text(timeAgo(l10n, message.createdAt),
              style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : AppColors.mutedText)),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  const _Card({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.deepNavy))),
            if (trailing != null) trailing!,
          ]),
          const SizedBox(height: 10),
          child,
        ]),
      );
}
