import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../protect/providers/agreements_provider.dart';
import '../../protect/screens/agreement_detail_screen.dart';
import '../../protect/screens/create_agreement_screen.dart';
import '../../reach/providers/campaigns_provider.dart';
import '../../reach/screens/campaign_detail_screen.dart';
import '../../reach/screens/create_campaign_screen.dart';
import '../models/project.dart';
import 'project_form_screen.dart';
import '../../../core/services/plan_limits.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final projects = ref.watch(projectsProvider);
    final agreements = ref.watch(agreementsProvider).whenOrNull(data: (l) => l) ?? [];
    final campaigns = ref.watch(campaignsProvider).whenOrNull(data: (l) => l) ?? [];

    Future<void> create() async {
      final p = await Navigator.push<Project>(context, MaterialPageRoute(builder: (_) => const ProjectFormScreen()));
      ref.invalidate(projectsProvider);
      if (p != null && context.mounted) showSuccess(context, l10n.projectSaved);
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-projects',
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.white,
        onPressed: create,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.createProject, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () async => ref.invalidate(projectsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AppSliverHeader(
              title: l10n.myProjects,
              subtitle: l10n.projectCount(projects.whenOrNull(data: (l) => l.length) ?? 0),
              leading: const HeaderIcon(Icons.library_music_rounded),
              showBack: true,
            ),
            ...projects.when(
              loading: () => [
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.teal))),
              ],
              error: (e, _) => [SliverFillRemaining(child: Center(child: Text(l10n.errorWithDetails('$e'))))],
              data: (list) => list.isEmpty
                  ? [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyProjects(onCreate: create),
                      ),
                    ]
                  : [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                        sliver: SliverList.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => FadeSlideIn(
                            delay: stagger(i.clamp(0, 8), 50),
                            child: ProjectCard(
                              project: list[i],
                              agreementCount: agreements.where((a) => a.projectId == list[i].id).length,
                              campaignCount: campaigns.where((c) => c.projectId == list[i].id).length,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: list[i])),
                                );
                                ref.invalidate(projectsProvider);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyProjects({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: AppColors.deepNavy.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const Icon(Icons.library_music_outlined, size: 40, color: AppColors.deepNavy),
        ),
        const SizedBox(height: 18),
        Text(l10n.noProjectsYet,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
        const SizedBox(height: 8),
        Text(l10n.noProjectsHint,
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.createProject),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
        ),
      ]),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;
  final int agreementCount;
  final int campaignCount;
  final VoidCallback onTap;
  final bool compact;

  const ProjectCard({
    super.key,
    required this.project,
    required this.agreementCount,
    required this.campaignCount,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(children: [
            _Cover(url: project.coverArtUrl, size: compact ? 52 : 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.deepNavy)),
                if (project.genre != null)
                  Text(project.genre!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _Pill(projectStatusLabel(l10n, project.status), AppColors.teal),
                  if (!compact) ...[
                    _Pill(l10n.agreementCount(agreementCount), AppColors.deepNavy),
                    _Pill(l10n.campaignCount(campaignCount), AppColors.deepNavy),
                  ],
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
          ]),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String? url;
  final double size;
  const _Cover({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: url == null ? kHeroGradient : null,
        image: url != null ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover) : null,
      ),
      child: url == null ? Icon(Icons.album_rounded, color: AppColors.white, size: size * 0.45) : null,
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Project detail ─────────────────────────────────────────────────────────

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  late Project _project = widget.project;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final agreements =
        (ref.watch(agreementsProvider).whenOrNull(data: (l) => l) ?? []).where((a) => a.projectId == _project.id).toList();
    final campaigns =
        (ref.watch(campaignsProvider).whenOrNull(data: (l) => l) ?? []).where((c) => c.projectId == _project.id).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(slivers: [
        AppSliverHeader(
          title: _project.title,
          subtitle: [_project.genre, projectStatusLabel(l10n, _project.status)].whereType<String>().join(' · '),
          showBack: true,
          actions: [
            if (_project.isOwner) ...[
              IconButton(
                tooltip: l10n.editProject,
                icon: const Icon(Icons.edit_outlined, color: AppColors.white),
                onPressed: () async {
                  final p = await Navigator.push<Project>(
                      context, MaterialPageRoute(builder: (_) => ProjectFormScreen(project: _project)));
                  if (p != null) setState(() => _project = p);
                  ref.invalidate(projectsProvider);
                },
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.white),
                onPressed: () async {
                  final ok = await confirmDialog(context, l10n.deleteProjectConfirm);
                  if (!ok) return;
                  await deleteProject(_project.id);
                  ref.invalidate(projectsProvider);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (_project.coverArtUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(_project.coverArtUrl!, fit: BoxFit.cover),
                  ),
                ),
              if (_project.coverArtUrl != null) const SizedBox(height: 14),
              _InfoCard(children: [
                if (_project.description != null) _kv(l10n.songDescription, _project.description!),
                if (_project.recordingDate != null) _kv(l10n.recordingDate, formatDate(_project.recordingDate)),
                if (_project.releaseDate != null) _kv(l10n.expectedReleaseDate, formatDate(_project.releaseDate)),
                _kv(l10n.projectStatus, projectStatusLabel(l10n, _project.status)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepNavy, minimumSize: const Size(0, 48)),
                    onPressed: () async {
                      if (!await checkPlanLimit(context, PlanLimit.agreements) || !context.mounted) return;
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => CreateAgreementScreen(project: _project)));
                      ref.invalidate(agreementsProvider);
                    },
                    icon: const Icon(Icons.shield_rounded, size: 18),
                    label: Text(l10n.newAgreement, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size(0, 48)),
                    onPressed: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => CreateCampaignScreen(project: _project)));
                      ref.invalidate(campaignsProvider);
                    },
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: Text(l10n.newCampaign, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              _sectionTitle(l10n.agreementsLabel, agreements.length),
              const SizedBox(height: 8),
              if (agreements.isEmpty) _muted(l10n.noAgreementsYet),
              for (final a in agreements)
                _LinkTile(
                  icon: Icons.shield_outlined,
                  title: a.songTitle,
                  subtitle: agreementStatusLabel(l10n, a.status),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => AgreementDetailScreen(agreement: a))),
                ),
              const SizedBox(height: 18),
              _sectionTitle(l10n.campaignsLabel, campaigns.length),
              const SizedBox(height: 8),
              if (campaigns.isEmpty) _muted(l10n.noCampaignsYet),
              for (final c in campaigns)
                _LinkTile(
                  icon: Icons.campaign_outlined,
                  title: c.campaignName ?? c.songTitle,
                  subtitle: campaignStatusLabel(l10n, c.status),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => CampaignDetailScreen(campaign: c))),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(k, style: const TextStyle(fontSize: 12, color: AppColors.mutedText))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(fontSize: 13, color: AppColors.deepNavy, fontWeight: FontWeight.w500))),
        ]),
      );

  Widget _sectionTitle(String t, int n) => Text('$t ($n)',
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.deepNavy));

  Widget _muted(String t) =>
      Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(t, style: const TextStyle(color: AppColors.mutedText)));
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(children: children),
      );
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            leading: Icon(icon, color: AppColors.deepNavy),
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.deepNavy)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      );
}

Future<bool> confirmDialog(BuildContext context, String message) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
