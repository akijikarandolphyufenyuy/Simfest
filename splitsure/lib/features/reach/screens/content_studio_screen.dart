import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/chip_inputs.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../auth/providers/profile_provider.dart';
import '../../passport/models/passport.dart';
import '../../projects/models/project.dart';
import '../models/campaign.dart';
import '../providers/campaigns_provider.dart';

const _platforms = ['instagram', 'tiktok', 'facebook', 'x', 'whatsapp'];
const _platformNames = {
  'instagram': 'Instagram',
  'tiktok': 'TikTok',
  'facebook': 'Facebook',
  'x': 'X',
  'whatsapp': 'WhatsApp'
};
const _kinds = ['caption', 'announcement', 'bio', 'project'];

/// A release-like source: a project or a campaign.
class _Source {
  final String id;
  final String title;
  final String? genre;
  final String? description;
  final String? releaseDate;
  final String? link;
  final String? artist;
  const _Source(this.id, this.title, {this.genre, this.description, this.releaseDate, this.link, this.artist});
}

/// Pro-only content generator built from the user's own projects, campaigns and Music Passport.
/// Nothing is published automatically: text is copied or shared from the device.
class ContentStudioScreen extends ConsumerStatefulWidget {
  const ContentStudioScreen({super.key});

  @override
  ConsumerState<ContentStudioScreen> createState() => _ContentStudioScreenState();
}

class _ContentStudioScreenState extends ConsumerState<ContentStudioScreen> {
  String _kind = 'caption';
  String _platform = 'instagram';
  String? _sourceId;
  int _variant = 0;
  final _out = TextEditingController();

  @override
  void dispose() {
    _out.dispose();
    super.dispose();
  }

  List<_Source> _sources(List<Project> projects, List<Campaign> campaigns, String artist) => [
        for (final c in campaigns)
          _Source('c:${c.id}', c.songTitle,
              description: c.description ?? c.promotionalMessage,
              releaseDate: c.releaseDate,
              link: c.streamingLink,
              artist: c.artistName ?? artist),
        for (final p in projects)
          _Source('p:${p.id}', p.title,
              genre: p.genre, description: p.description, releaseDate: p.releaseDate, artist: artist),
      ];

  String _tag(String s) => '#${s.replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ]'), '')}';

  String _hashtags(_Source? s, MusicPassport? p) {
    final tags = <String>{
      if (s != null) _tag(s.title),
      if (s?.genre?.isNotEmpty ?? false) _tag(s!.genre!),
      for (final g in p?.genres ?? const <String>[]) _tag(g),
      if (p != null) _tag(p.stageName),
      '#NewMusic',
      if ((p?.country ?? 'Cameroon') == 'Cameroon') '#237Music',
    }..removeWhere((t) => t.length < 3);
    final max = switch (_platform) { 'instagram' => 12, 'tiktok' => 6, 'x' => 3, 'facebook' => 4, _ => 0 };
    return tags.take(max).join(' ');
  }

  String _list(AppLocalizations l10n, List<String> v) =>
      v.length <= 1 ? v.join() : '${v.sublist(0, v.length - 1).join(', ')} ${l10n.andWord} ${v.last}';

  void _generate(List<_Source> sources, MusicPassport? passport, List<PortfolioItem> portfolio, String fallbackName) {
    final l10n = AppLocalizations.of(context)!;
    final src = sources.where((s) => s.id == _sourceId).firstOrNull;
    final artist = passport?.stageName ?? src?.artist ?? fallbackName;
    final link = src?.link ?? (passport?.isPublished == true ? passportLink(passport!.slug) : '');
    String text;

    switch (_kind) {
      case 'bio':
        if (passport == null) {
          showError(context, l10n.needPassportForBio);
          return;
        }
        final roles =
            _list(l10n, [for (final r in passport.allRoles.take(3)) passportRoleLabel(l10n, r).toLowerCase()]);
        final place = [passport.city, passport.country].whereType<String>().where((s) => s.isNotEmpty).join(', ');
        final credits =
            portfolio.take(3).map((i) => i.year != null ? '"${i.title}" (${i.year})' : '"${i.title}"').toList();
        text = [
          l10n.genBioIntro(passport.stageName, roles, place.isEmpty ? '' : l10n.genBioBasedIn(place)),
          if (passport.yearsExperience != null && passport.genres.isNotEmpty)
            l10n.genBioExperience('${passport.yearsExperience}', passport.stageName, _list(l10n, passport.genres))
          else if (passport.genres.isNotEmpty)
            l10n.genBioGenres(passport.stageName, _list(l10n, passport.genres)),
          if (passport.instruments.isNotEmpty) l10n.genBioInstruments(_list(l10n, passport.instruments)),
          if (credits.isNotEmpty) l10n.genBioCredits(_list(l10n, credits)),
          if (passport.bio?.isNotEmpty ?? false) passport.bio!,
          if (passport.availability != 'unavailable') l10n.genBioOpen,
        ].join(' ');
      case 'announcement':
        final title = src?.title ?? artist;
        final date = src?.releaseDate != null ? formatDate(DateTime.tryParse(src!.releaseDate!)) : null;
        text = date == null
            ? l10n.genAnnouncementNoDate(title, artist, link)
            : (_variant.isEven
                ? l10n.genAnnouncement1(l10n.kindSingle, title, date, link)
                : l10n.genAnnouncement2(title, artist, date, link));
      case 'project':
        final title = src?.title ?? artist;
        text = l10n.genProjectPromo(
            title, src?.genre?.isNotEmpty ?? false ? ' (${src!.genre})' : '', (src?.description ?? '').trim());
      default:
        final title = src?.title ?? artist;
        text = switch (_variant % 3) {
          0 => l10n.genCaption1(title, artist, link),
          1 => l10n.genCaption2(title, artist, link),
          _ => l10n.genCaption3(title, link),
        };
    }

    text = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (_kind != 'bio') {
      final tags = _hashtags(src, passport);
      if (tags.isNotEmpty) text = '$text\n\n$tags';
      if (_platform == 'x' && text.length > 280) text = '${text.substring(0, 277)}…';
    }
    setState(() {
      _out.text = text;
      _variant++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final passport = ref.watch(myPassportProvider).whenOrNull(data: (p) => p);
    final portfolio = ref.watch(myPortfolioProvider).whenOrNull(data: (l) => l) ?? const <PortfolioItem>[];
    final projects = ref.watch(projectsProvider).whenOrNull(data: (l) => l) ?? const <Project>[];
    final campaigns = ref.watch(campaignsProvider).whenOrNull(data: (l) => l) ?? const <Campaign>[];
    final profile = ref.watch(profileProvider).whenOrNull(data: (p) => p);
    final fallbackName = profile?.displayName ?? '';
    final sources = _sources(projects, campaigns, fallbackName);

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
        );

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(slivers: [
        AppSliverHeader(
          title: l10n.contentStudio,
          subtitle: l10n.contentStudioSubtitle,
          gradient: kTealGradient,
          leading: const HeaderIcon(Icons.auto_awesome_rounded),
          showBack: true,
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 60),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  label(l10n.contentType),
                  SingleChoiceChips<String>(
                    options: _kinds,
                    value: _kind,
                    label: (k) => switch (k) {
                      'announcement' => l10n.contentAnnouncement,
                      'bio' => l10n.contentBio,
                      'project' => l10n.contentProjectPromo,
                      _ => l10n.contentCaption,
                    },
                    onChanged: (v) => setState(() => _kind = v),
                  ),
                  if (_kind != 'bio') ...[
                    label(l10n.sourceProject),
                    DropdownButtonFormField<String?>(
                      initialValue: _sourceId,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.noSourceSelected)),
                        for (final s in sources)
                          DropdownMenuItem(value: s.id, child: Text(s.title, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setState(() => _sourceId = v),
                    ),
                    label(l10n.platform),
                    SingleChoiceChips<String>(
                      options: _platforms,
                      value: _platform,
                      label: (p) => _platformNames[p]!,
                      onChanged: (v) => setState(() => _platform = v),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () => _generate(sources, passport, portfolio, fallbackName),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(_out.text.isEmpty ? l10n.generate : l10n.regenerate),
                  ),
                  if (_out.text.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _out,
                      maxLines: null,
                      minLines: 5,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _out.text));
                            showSuccess(context, l10n.textCopied);
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: Text(l10n.copyText),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.deepNavy),
                          onPressed: () => SharePlus.instance.share(ShareParams(text: _out.text)),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: Text(l10n.shareText),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 18),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.mutedText),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(l10n.directPublishNote,
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedText))),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
