import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../models/passport.dart';

Future<void> openExternal(String url) async {
  final uri = Uri.tryParse(url.startsWith('http') || url.contains(':') ? url : 'https://$url');
  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Read-only rendering of a Music Passport. Used by the owner preview, the public page
/// and the Opportunity Hub (owner / applicant passports).
class PassportView extends StatelessWidget {
  final MusicPassport passport;
  final List<PortfolioItem> portfolio;
  final List<Widget> actions;
  final GlobalKey? portfolioKey;

  /// Owner preview shows everything; public views only get public fields from the server.
  final bool showContact;

  const PassportView({
    super.key,
    required this.passport,
    this.portfolio = const [],
    this.actions = const [],
    this.portfolioKey,
    this.showContact = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = passport;
    final hasContact = showContact && ((p.contactEmail?.isNotEmpty ?? false) || (p.contactPhone?.isNotEmpty ?? false));
    var i = 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FadeSlideIn(child: _HeroCard(passport: p, actions: actions)),
      if (p.bio?.isNotEmpty ?? false)
        FadeSlideIn(
          delay: stagger(++i),
          child: _Card(
            title: l10n.about,
            child: Text(p.bio!, style: const TextStyle(color: AppColors.deepNavy, height: 1.45)),
          ),
        ),
      FadeSlideIn(
        delay: stagger(++i),
        child: _Card(
          title: l10n.skillsSpecialisations,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Chips([for (final r in p.allRoles) passportRoleLabel(l10n, r)], strong: true),
            if (p.skills.isNotEmpty) ...[const SizedBox(height: 8), _Chips(p.skills)],
            if (p.yearsExperience != null) ...[
              const SizedBox(height: 12),
              _Line(Icons.timeline_rounded, l10n.yearsExperienceValue(p.yearsExperience!)),
            ],
            if (p.genres.isNotEmpty) _Labeled(l10n.genres, _Chips(p.genres)),
            if (p.instruments.isNotEmpty) _Labeled(l10n.instruments, _Chips(p.instruments)),
            if (p.languages.isNotEmpty) _Labeled(l10n.languages, _Chips(p.languages)),
            if (p.arrangements.isNotEmpty)
              _Labeled(l10n.preferredArrangements, _Chips([for (final a in p.arrangements) arrangementLabel(l10n, a)])),
            if (p.operatingLocation?.isNotEmpty ?? false)
              _Labeled(l10n.operatingLocation, _Line(Icons.place_outlined, p.operatingLocation!)),
          ]),
        ),
      ),
      if (p.links.values.any((v) => v.isNotEmpty))
        FadeSlideIn(
          delay: stagger(++i),
          child: _Card(
            title: l10n.externalLinks,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in p.links.entries.where((e) => e.value.isNotEmpty))
                ActionChip(
                  avatar: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.teal),
                  label: Text(e.key == 'website' ? l10n.personalWebsite : (kPassportLinks[e.key] ?? e.key)),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.cardBorder),
                  onPressed: () => openExternal(e.value),
                ),
            ]),
          ),
        ),
      if (hasContact)
        FadeSlideIn(
          delay: stagger(++i),
          child: _Card(
            title: l10n.contact,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (p.contactEmail?.isNotEmpty ?? false) _Line(Icons.email_outlined, p.contactEmail!),
              if (p.contactPhone?.isNotEmpty ?? false) _Line(Icons.phone_outlined, p.contactPhone!),
              if (p.preferredContact != null)
                _Line(Icons.star_outline_rounded,
                    '${l10n.preferredContact}: ${contactMethodLabel(l10n, p.preferredContact!)}'),
            ]),
          ),
        ),
      if (portfolio.isNotEmpty)
        FadeSlideIn(
          key: portfolioKey,
          delay: stagger(++i),
          child: _Card(
            title: l10n.portfolioItems,
            child: Column(children: [for (final item in portfolio) PortfolioTile(item: item)]),
          ),
        ),
    ]);
  }
}

class _HeroCard extends StatelessWidget {
  final MusicPassport passport;
  final List<Widget> actions;
  const _HeroCard({required this.passport, required this.actions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = passport;
    final availColor = switch (p.availability) {
      'limited' => Colors.orange,
      'unavailable' => AppColors.error,
      _ => AppColors.success,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
              shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.teal, AppColors.deepNavy])),
          child: CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.lightBg,
            backgroundImage: p.photoUrl != null ? NetworkImage(p.photoUrl!) : null,
            child: p.photoUrl == null
                ? Text(p.stageName.isNotEmpty ? p.stageName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.deepNavy))
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(p.stageName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.deepNavy)),
        const SizedBox(height: 2),
        Text(passportRoleLabel(l10n, p.primaryRole),
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
        if (p.location.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.place_outlined, size: 15, color: AppColors.mutedText),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                [p.city, if (p.country != null) countryLabel(l10n, p.country!)]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(', '),
                style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: availColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, size: 8, color: availColor),
            const SizedBox(width: 6),
            Text(availabilityLabel(l10n, p.availability),
                style: TextStyle(color: availColor, fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: actions),
        ],
      ]),
    );
  }
}

class PortfolioTile extends StatelessWidget {
  final PortfolioItem item;
  final VoidCallback? onTap;
  final Widget? trailing;
  const PortfolioTile({super.key, required this.item, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sub = [
      portfolioKindLabel(l10n, item.kind),
      if (item.role?.isNotEmpty ?? false) item.role!,
      if (item.year != null) '${item.year}'
    ].join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap ?? (item.url?.isNotEmpty ?? false ? () => openExternal(item.url!) : null),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl != null
                ? Image.network(item.imageUrl!, width: 54, height: 54, fit: BoxFit.cover)
                : Container(
                    width: 54,
                    height: 54,
                    color: AppColors.teal.withValues(alpha: 0.1),
                    child: Icon(_kindIcon(item.kind), color: AppColors.teal),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
              Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              if (item.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(item.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.deepNavy)),
              ],
            ]),
          ),
          if (trailing != null)
            trailing!
          else if (item.url?.isNotEmpty ?? false)
            const Padding(
              padding: EdgeInsets.only(left: 6, top: 4),
              child: Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.mutedText),
            ),
        ]),
      ),
    );
  }

  static IconData _kindIcon(String k) => switch (k) {
        'release' => Icons.music_note_rounded,
        'album' => Icons.album_rounded,
        'production_credit' => Icons.tune_rounded,
        'writing_credit' => Icons.edit_note_rounded,
        'collaboration' => Icons.handshake_outlined,
        'video' => Icons.movie_outlined,
        'award' => Icons.emoji_events_outlined,
        'experience' => Icons.work_outline_rounded,
        _ => Icons.library_music_outlined,
      };
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.deepNavy)),
          const SizedBox(height: 10),
          child,
        ]),
      );
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled(this.label, this.child);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          child,
        ]),
      );
}

class _Chips extends StatelessWidget {
  final List<String> values;
  final bool strong;
  const _Chips(this.values, {this.strong = false});

  @override
  Widget build(BuildContext context) => Wrap(spacing: 6, runSpacing: 6, children: [
        for (final v in values)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: strong ? AppColors.deepNavy : AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(v,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: strong ? Colors.white : AppColors.deepNavy)),
          ),
      ]);
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Line(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.mutedText),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.deepNavy, fontSize: 13.5))),
        ]),
      );
}
