import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../dealflow/models/workspace.dart';
import '../../dealflow/screens/workspace_screen.dart';
import '../../passport/models/passport.dart';
import '../../passport/widgets/passport_sheet.dart';
import '../../passport/widgets/passport_view.dart';
import '../models/opportunity.dart';
import '../widgets/opportunity_card.dart';

/// Owner's application-management dashboard for one opportunity.
class ApplicationsScreen extends ConsumerWidget {
  final Opportunity opportunity;
  const ApplicationsScreen({super.key, required this.opportunity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final apps = ref.watch(receivedApplicationsProvider(opportunity.id));
    final list = apps.whenOrNull(data: (l) => l) ?? const <Application>[];
    final workspace = ref.watch(workspaceForOpportunityProvider(opportunity.id)).whenOrNull(data: (w) => w);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async => ref.invalidate(receivedApplicationsProvider(opportunity.id)),
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          AppSliverHeader(
            title: l10n.applicationsTitle,
            subtitle: opportunity.title,
            leading: const HeaderIcon(Icons.inbox_rounded),
            showBack: true,
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (workspace != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.deepNavy, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => WorkspaceScreen(workspaceId: workspace.id))),
                          icon: const Icon(Icons.handshake_rounded),
                          label: Text('${l10n.dealflow} · ${workspaceStatusLabel(l10n, workspace.status)}'),
                        ),
                      ),
                    if (apps.isLoading && list.isEmpty)
                      const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.teal))),
                    if (!apps.isLoading && list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(l10n.noApplicationsYet, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
                      ),
                    for (var i = 0; i < list.length; i++)
                      FadeSlideIn(delay: stagger(i), child: _ApplicantCard(app: list[i], opportunity: opportunity)),
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

class _ApplicantCard extends ConsumerStatefulWidget {
  final Application app;
  final Opportunity opportunity;
  const _ApplicantCard({required this.app, required this.opportunity});

  @override
  ConsumerState<_ApplicantCard> createState() => _ApplicantCardState();
}

class _ApplicantCardState extends ConsumerState<_ApplicantCard> {
  bool _busy = false;

  Future<void> _set(String status) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await setApplicationStatus(widget.app.id, status);
      if (status == 'accepted') {
        final ws = await startWorkspaceFromApplication(widget.app.id);
        ref.invalidate(workspaceForOpportunityProvider(widget.opportunity.id));
        ref.invalidate(myWorkspacesProvider);
        if (mounted) {
          showSuccess(context, l10n.workspaceOpened);
          Navigator.push(context, MaterialPageRoute(builder: (_) => WorkspaceScreen(workspaceId: ws)));
        }
      }
      ref.invalidate(receivedApplicationsProvider(widget.opportunity.id));
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final a = widget.app;
    final p = ref.watch(publicPassportByUserProvider(a.applicantId)).whenOrNull(data: (p) => p);
    final closed = a.status == 'withdrawn' || a.status == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showPassportSheet(context, a.applicantId),
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
                Text(p?.stageName ?? '…', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                if (p != null)
                  Text(
                    [passportRoleLabel(l10n, p.primaryRole), if (p.yearsExperience != null) l10n.yearsExperienceValue(p.yearsExperience!)]
                        .join(' · '),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.teal),
                  ),
                Text(l10n.appliedOn(formatDate(a.createdAt)), style: const TextStyle(fontSize: 11.5, color: AppColors.mutedText)),
              ]),
            ),
            StatusPill(a.status),
          ]),
        ),
        const SizedBox(height: 12),
        Text(a.message, style: const TextStyle(color: AppColors.deepNavy, height: 1.4)),
        for (final link in a.links)
          TextButton.icon(
            style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: EdgeInsets.zero),
            onPressed: () => openExternal(link),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          OutlinedButton.icon(
            style: _compact,
            onPressed: () => showPassportSheet(context, a.applicantId),
            icon: const Icon(Icons.badge_outlined, size: 18),
            label: Text(l10n.viewPassport),
          ),
          if (!closed && a.status != 'accepted') ...[
            if (a.status == 'pending')
              OutlinedButton(style: _compact, onPressed: _busy ? null : () => _set('under_review'), child: Text(l10n.markUnderReview)),
            if (a.status != 'shortlisted')
              OutlinedButton(style: _compact, onPressed: _busy ? null : () => _set('shortlisted'), child: Text(l10n.shortlist)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: _busy ? null : () => _set('accepted'),
              child: Text(l10n.accept),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: _busy ? null : () => _set('rejected'),
              child: Text(l10n.reject),
            ),
          ],
          if (a.status == 'accepted')
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.deepNavy),
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        final ws = await startWorkspaceFromApplication(a.id);
                        if (context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => WorkspaceScreen(workspaceId: ws)));
                        }
                      } catch (e) {
                        if (context.mounted) showError(context, friendlyError(e));
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              icon: const Icon(Icons.handshake_rounded, size: 18),
              label: Text(l10n.startWorkspace),
            ),
        ]),
      ]),
    );
  }
}

/// The theme gives outlined buttons full width; in a Wrap they should size to their label.
final _compact = OutlinedButton.styleFrom(minimumSize: const Size(0, 40));
