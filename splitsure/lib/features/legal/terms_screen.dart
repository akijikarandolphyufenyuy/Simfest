import 'package:flutter/material.dart';
import '../../core/localization/l10n/app_localizations.dart';
import '../../core/localization/l10n_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/floating_illustration.dart';
import 'terms_content.dart';

/// Terms & Conditions. With [acceptMode] (opened from sign-up) an "I agree" bar
/// is shown and the screen returns `true` when the user accepts.
class TermsScreen extends StatefulWidget {
  final bool acceptMode;
  const TermsScreen({super.key, this.acceptMode = false});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final _scroll = ScrollController();
  final _keys = <GlobalKey>[];
  bool _showTop = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final show = _scroll.offset > 600;
      if (show != _showTop) setState(() => _showTop = show);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jumpTo(int i) {
    final ctx = _keys[i].currentContext;
    if (ctx != null) {
      // Land the section just below the pinned header, whatever the screen height.
      final mq = MediaQuery.of(context);
      final visible = mq.size.height;
      final alignment = ((kHeaderHeight + mq.padding.top + 12) / visible).clamp(0.0, 0.9);
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 550), curve: Curves.easeInOutCubic, alignment: alignment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = termsFor(Localizations.localeOf(context).languageCode);
    while (_keys.length < sections.length) {
      _keys.add(GlobalKey());
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      floatingActionButton: AnimatedScale(
        scale: _showTop ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Padding(
          padding: EdgeInsets.only(bottom: widget.acceptMode ? 70 : 0),
          child: FloatingActionButton.small(
            tooltip: l10n.termsBackToTop,
            backgroundColor: AppColors.deepNavy,
            foregroundColor: AppColors.white,
            onPressed: () =>
                _scroll.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic),
            child: const Icon(Icons.keyboard_arrow_up_rounded),
          ),
        ),
      ),
      bottomNavigationBar: widget.acceptMode
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.08), blurRadius: 16)],
                ),
                // heightFactor 1: only as tall as the button (a plain Center would fill the whole screen).
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.verified_rounded, size: 20),
                      label: Text(l10n.termsAgree),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: CustomScrollView(controller: _scroll, slivers: [
        AppSliverHeader(
          title: l10n.termsTitle,
          subtitle: 'SplitSure',
          leading: const HeaderIcon(Icons.gavel_rounded),
          showBack: true,
          fallbackRoute: '/welcome',
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, widget.acceptMode ? 30 : 60),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _hero(l10n),
                  const SizedBox(height: 18),
                  FadeSlideIn(delay: stagger(3), child: _contents(l10n, sections)),
                  const SizedBox(height: 18),
                  for (var i = 0; i < sections.length; i++)
                    FadeSlideIn(
                      key: _keys[i],
                      delay: stagger(i < 6 ? 4 + i : 0),
                      child: _SectionCard(number: i + 1, section: sections[i]),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _hero(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F4FF), Color(0xFFE6F7F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        const FloatingIllustration(asset: 'assets/images/terms.png', size: 170),
        const SizedBox(height: 8),
        FadeSlideIn(
          delay: stagger(1),
          child: Text(l10n.termsTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.deepNavy)),
        ),
        const SizedBox(height: 8),
        FadeSlideIn(
          delay: stagger(2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.update_rounded, size: 14, color: AppColors.teal),
              const SizedBox(width: 5),
              Text(l10n.termsLastUpdated(formatDate(termsLastUpdated)),
                  style: const TextStyle(fontSize: 12, color: AppColors.deepNavy, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: stagger(2),
          child: Text(l10n.termsIntro,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 13.5, color: AppColors.mutedText, height: 1.55)),
        ),
      ]),
    );
  }

  Widget _contents(AppLocalizations l10n, List<TermsSection> sections) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.list_alt_rounded, size: 18, color: AppColors.teal),
          const SizedBox(width: 8),
          Text(l10n.termsContents.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth < 520 ? _contentsList(sections) : _contentsChips(sections),
        ),
      ]),
    );
  }

  /// Phones: an even, full-width list instead of ragged chip rows.
  Widget _contentsList(List<TermsSection> sections) {
    return Column(children: [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const Divider(height: 1, color: AppColors.cardBorder),
        InkWell(
          onTap: () => _jumpTo(i),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.teal,
                child: Text('${i + 1}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(sections[i].title,
                    style: const TextStyle(fontSize: 13, color: AppColors.deepNavy, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ],
    ]);
  }

  Widget _contentsChips(List<TermsSection> sections) {
    return Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
      for (var i = 0; i < sections.length; i++)
        ActionChip(
          onPressed: () => _jumpTo(i),
          backgroundColor: AppColors.lightBg,
          side: const BorderSide(color: AppColors.cardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          avatar: CircleAvatar(
            backgroundColor: AppColors.teal,
            child: Text('${i + 1}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.white)),
          ),
          label: Text(sections[i].title,
              style: const TextStyle(fontSize: 12, color: AppColors.deepNavy, fontWeight: FontWeight.w600)),
        ),
    ]);
  }
}

class _SectionCard extends StatelessWidget {
  final int number;
  final TermsSection section;
  const _SectionCard({required this.number, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(gradient: kHeroGradient, borderRadius: BorderRadius.circular(11)),
            child: Text('$number',
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 8),
        Text(section.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
        const SizedBox(height: 12),
        for (final p in section.paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(p,
                textAlign: TextAlign.justify,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.6)),
          ),
      ]),
    );
  }
}
