import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/chip_inputs.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../passport/models/passport.dart';
import '../../passport/screens/passport_screen.dart';
import '../../passport/widgets/passport_sheet.dart';
import '../../passport/widgets/passport_view.dart';
import '../models/opportunity.dart';
import '../widgets/opportunity_card.dart';
import 'applications_screen.dart';
import 'opportunity_form_screen.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  final String opportunityId;
  const OpportunityDetailScreen({super.key, required this.opportunityId});

  void _refresh(WidgetRef ref) {
    ref.invalidate(opportunityProvider(opportunityId));
    ref.invalidate(applicationCountProvider(opportunityId));
    ref.invalidate(myApplicationsProvider);
    ref.invalidate(myOpportunitiesProvider);
    ref.invalidate(openOpportunitiesProvider);
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await Supabase.instance.client
          .from('collaboration_opportunities')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()}).eq('id', opportunityId);
      _refresh(ref);
    } catch (e) {
      if (context.mounted) showError(context, friendlyError(e));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteOpportunity),
        content: Text(l10n.deleteOpportunityConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client.from('collaboration_opportunities').delete().eq('id', opportunityId);
      _refresh(ref);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(opportunityProvider(opportunityId));
    final o = async.whenOrNull(data: (o) => o);
    final count = ref.watch(applicationCountProvider(opportunityId)).whenOrNull(data: (c) => c) ?? 0;
    final myApp = (ref.watch(myApplicationsProvider).whenOrNull(data: (l) => l) ?? const <Application>[])
        .where((a) => a.opportunityId == opportunityId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async => _refresh(ref),
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          AppSliverHeader(
            title: o?.title ?? l10n.opportunityHub,
            subtitle: o == null ? null : opportunityCategoryLabel(l10n, o.category),
            leading: const HeaderIcon(Icons.work_outline_rounded),
            showBack: true,
            fallbackRoute: '/home',
            actions: [
              if (o != null)
                IconButton(
                  tooltip: l10n.shareOpportunity,
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: opportunityLink(o.id)));
                    showSuccess(context, l10n.linkCopied);
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                  child: async.isLoading && o == null
                      ? const Padding(padding: EdgeInsets.all(60), child: Center(child: CircularProgressIndicator(color: AppColors.teal)))
                      : o == null
                          ? Padding(padding: const EdgeInsets.all(40), child: Text(l10n.noOpportunities, textAlign: TextAlign.center))
                          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              FadeSlideIn(child: _OwnerCard(ownerId: o.ownerId)),
                              const SizedBox(height: 14),
                              FadeSlideIn(delay: stagger(1), child: _Details(o: o, count: count)),
                              const SizedBox(height: 18),
                              FadeSlideIn(
                                delay: stagger(2),
                                child: o.isMine
                                    ? _OwnerActions(
                                        o: o,
                                        count: count,
                                        onClose: () => _setStatus(context, ref, o.isOpen ? 'closed' : 'open'),
                                        onDelete: () => _delete(context, ref),
                                      )
                                    : _ApplicantActions(o: o, application: myApp, onChanged: () => _refresh(ref)),
                              ),
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

class _OwnerCard extends ConsumerWidget {
  final String ownerId;
  const _OwnerCard({required this.ownerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final p = ref.watch(publicPassportByUserProvider(ownerId)).whenOrNull(data: (p) => p);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showPassportSheet(context, ownerId),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.teal.withValues(alpha: 0.12),
              backgroundImage: p?.photoUrl != null ? NetworkImage(p!.photoUrl!) : null,
              child: p?.photoUrl == null ? const Icon(Icons.person_rounded, color: AppColors.teal) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.postedBy, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
                Text(p?.stageName ?? '…', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                if (p != null)
                  Text(passportRoleLabel(l10n, p.primaryRole), style: const TextStyle(fontSize: 12.5, color: AppColors.teal)),
              ]),
            ),
            TextButton(onPressed: () => showPassportSheet(context, ownerId), child: Text(l10n.viewPassport)),
          ]),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final Opportunity o;
  final int count;
  const _Details({required this.o, required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: AppColors.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(color: AppColors.deepNavy, fontSize: 14)),
              ]),
            ),
          ]),
        );
    Widget chips(List<String> v) => Wrap(spacing: 6, runSpacing: 6, children: [
          for (final s in v)
            Chip(
              label: Text(s),
              visualDensity: VisualDensity.compact,
              backgroundColor: AppColors.teal.withValues(alpha: 0.1),
              side: BorderSide.none,
              labelStyle: const TextStyle(fontSize: 12, color: AppColors.deepNavy, fontWeight: FontWeight.w600),
            ),
        ]);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(l10n.publishedOn(formatDate(o.createdAt)), style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (o.isOpen ? AppColors.success : AppColors.mutedText).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(o.isOpen ? l10n.statusOpen : l10n.statusClosed,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: o.isOpen ? AppColors.success : AppColors.mutedText)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(o.description, style: const TextStyle(color: AppColors.deepNavy, height: 1.5)),
        const Divider(height: 28),
        Text(l10n.requiredRoles, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
        const SizedBox(height: 8),
        chips([for (final r in o.requiredRoles) passportRoleLabel(l10n, r)]),
        if (o.skills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.requiredSkills, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          chips(o.skills),
        ],
        if (o.genres.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.genres, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          const SizedBox(height: 8),
          chips(o.genres),
        ],
        const Divider(height: 28),
        row(Icons.handshake_outlined, l10n.collaborationType,
            [arrangementLabel(l10n, o.collaborationType), if (o.compensation?.isNotEmpty ?? false) o.compensation!].join(' · ')),
        row(Icons.place_outlined, l10n.projectLocation,
            [if (o.location?.isNotEmpty ?? false) o.location!, if (o.isRemote) l10n.remoteOk].join(' · ')),
        if (o.deliverables?.isNotEmpty ?? false) row(Icons.inventory_2_outlined, l10n.expectedDeliverables, o.deliverables!),
        if (o.projectDeadline != null) row(Icons.event_outlined, l10n.projectDeadline, formatDate(o.projectDeadline)),
        if (o.applicationDeadline != null) row(Icons.event_available_outlined, l10n.applicationDeadline, formatDate(o.applicationDeadline)),
        row(Icons.groups_outlined, l10n.positionsNeeded, l10n.positionsCount(o.positions)),
        row(Icons.inbox_outlined, l10n.applicationsTitle, l10n.applicationsCount(count)),
        if (o.requirements?.isNotEmpty ?? false) row(Icons.rule_rounded, l10n.additionalRequirements, o.requirements!),
        if (o.referenceLinks.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(l10n.referenceLinks, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
          for (final link in o.referenceLinks)
            TextButton.icon(
              style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
              onPressed: () => openExternal(link),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ]),
    );
  }
}

class _OwnerActions extends ConsumerWidget {
  final Opportunity o;
  final int count;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  const _OwnerActions({required this.o, required this.count, required this.onClose, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.yourOwnOpportunity, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
      const SizedBox(height: 10),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 15)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicationsScreen(opportunity: o))),
        icon: const Icon(Icons.inbox_rounded),
        label: Text('${l10n.applicationsTitle} ($count)'),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => openOpportunityForm(context, ref, existing: o),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l10n.edit),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onClose,
            icon: Icon(o.isOpen ? Icons.lock_outline_rounded : Icons.lock_open_rounded, size: 18),
            label: Text(o.isOpen ? l10n.closeOpportunity : l10n.reopenOpportunity),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
        label: Text(l10n.deleteOpportunity),
      ),
    ]);
  }
}

class _ApplicantActions extends ConsumerWidget {
  final Opportunity o;
  final Application? application;
  final VoidCallback onChanged;
  const _ApplicantActions({required this.o, required this.application, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final app = application;
    if (app != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(l10n.alreadyApplied, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
            const SizedBox(width: 8),
            StatusPill(app.status),
          ]),
          const SizedBox(height: 4),
          Text(l10n.appliedOn(formatDate(app.createdAt)), style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
          if (app.canWithdraw)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: Text(l10n.withdrawConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.withdraw)),
                    ],
                  ),
                );
                if (ok != true) return;
                try {
                  await withdrawApplication(app.id);
                  onChanged();
                } catch (e) {
                  if (context.mounted) showError(context, friendlyError(e));
                }
              },
              child: Text(l10n.withdraw),
            ),
        ]),
      );
    }
    if (o.applicationsClosed) {
      return Text(l10n.opportunityClosedNotice, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.teal,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () async {
          if (!await requirePublishedPassport(context, ref)) return;
          if (context.mounted && await _showApplySheet(context, o) == true) onChanged();
        },
        icon: const Icon(Icons.send_rounded),
        label: Text(l10n.applyNow, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => showPassportSheet(context, o.ownerId),
        icon: const Icon(Icons.badge_outlined),
        label: Text(l10n.viewPassport),
      ),
    ]);
  }
}

Future<bool?> _showApplySheet(BuildContext context, Opportunity o) {
  final msg = TextEditingController();
  var links = <String>[];
  var busy = false;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final l10n = AppLocalizations.of(ctx)!;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.applyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.deepNavy)),
            const SizedBox(height: 4),
            Text(o.title, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
            const SizedBox(height: 16),
            TextField(
              controller: msg,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(labelText: l10n.applicationMessage, hintText: l10n.applicationMessageHint),
            ),
            TagInput(label: l10n.supportingLinks, hint: 'https://…', values: links, max: 8, onChanged: (v) => setS(() => links = v)),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 15)),
              onPressed: busy
                  ? null
                  : () async {
                      if (msg.text.trim().isEmpty) {
                        showError(ctx, '${l10n.applicationMessage}: ${l10n.requiredField}');
                        return;
                      }
                      setS(() => busy = true);
                      try {
                        await Supabase.instance.client.from('opportunity_applications').insert({
                          'opportunity_id': o.id,
                          'message': msg.text.trim(),
                          'links': links,
                        });
                        if (ctx.mounted) {
                          showSuccess(ctx, l10n.applicationSent);
                          Navigator.pop(ctx, true);
                        }
                      } catch (e) {
                        if (ctx.mounted) showError(ctx, friendlyError(e));
                        setS(() => busy = false);
                      }
                    },
              icon: const Icon(Icons.send_rounded),
              label: Text(l10n.submitApplication),
            ),
          ]),
        ),
      );
    }),
  );
}
