import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// Background behind the illustrations — matches their own light-blue tone.
const _bg = Color(0xFFEDF4FF);
const _anim = Duration(milliseconds: 420);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  late final AnimationController _intro;
  int _currentPage = 0;

  static final List<_PageData> _pages = [
    _PageData(
      image: 'assets/images/onboarding1.png',
      titleAccent: (l) => l.onboarding1TitleAccent,
      titleRest: (l) => l.onboarding1TitleRest,
      subtitle: (l) => l.onboarding1Subtitle,
    ),
    _PageData(
      image: 'assets/images/onboarding2.png',
      titleAccent: (l) => l.onboarding2TitleAccent,
      titleRest: (l) => l.onboarding2TitleRest,
      subtitle: (l) => l.onboarding2Subtitle,
    ),
    _PageData(
      image: 'assets/images/onboarding3.png',
      titleAccent: (l) => l.onboarding3TitleAccent,
      titleRest: (l) => l.onboarding3TitleRest,
      subtitle: (l) => l.onboarding3Subtitle,
    ),
  ];

  bool get _isLast => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode all illustrations up-front so swiping never flashes an empty frame.
    for (final p in _pages) {
      precacheImage(AssetImage(p.image), context);
    }
  }

  void _next() {
    if (!_isLast) {
      _controller.nextPage(duration: _anim, curve: Curves.easeOutCubic);
    } else {
      context.go('/register');
    }
  }

  void _back() => _controller.previousPage(duration: _anim, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _controller.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    // Side-by-side layout on desktops and on wide landscape screens (tablets).
    final isDesktop = size.width > 900 || (size.width > 640 && size.width > size.height);

    return Scaffold(
      backgroundColor: _bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF2FD), Color(0xFFF4F9FF), Color(0xFFE8F6F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
          child: isDesktop ? _buildDesktop(context, l10n) : _buildMobile(context, l10n),
        ),
      ),
    );
  }

  // ── Illustrations (shared) ─────────────────────────────────────────────────

  Widget _illustrations({EdgeInsets padding = EdgeInsets.zero, double radius = 28, bool fillWidth = false}) {
    return PageView.builder(
      controller: _controller,
      itemCount: _pages.length,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (_, i) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Parallax: the image drifts, shrinks and fades slightly as it leaves.
          final page = _controller.hasClients && _controller.position.haveDimensions
              ? (_controller.page ?? _currentPage.toDouble())
              : _currentPage.toDouble();
          final delta = (page - i).clamp(-1.0, 1.0);
          final t = delta.abs();
          return Opacity(
            opacity: 1 - t * 0.45,
            child: Transform.translate(
              offset: Offset(delta * 70, t * 18),
              child: Transform.scale(scale: 1 - t * 0.12, child: child),
            ),
          );
        },
        child: Padding(
          padding: padding,
          child: fillWidth
              ? Align(
                  alignment: Alignment.topCenter,
                  child: _ImageCard(image: _pages[i].image, radius: radius, fillWidth: true))
              : Center(child: _ImageCard(image: _pages[i].image, radius: radius)),
        ),
      ),
    );
  }

  // ── Text block (shared) ────────────────────────────────────────────────────

  Widget _textBlock(AppLocalizations l10n, {required double titleSize}) {
    final page = _pages[_currentPage];
    return AnimatedSwitcher(
      duration: _anim,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      child: Column(
        key: ValueKey(_currentPage),
        mainAxisSize: MainAxisSize.min,
        children: [
          _TwoToneTitle(data: page, fontSize: titleSize),
          const SizedBox(height: 12),
          Text(
            page.subtitle(l10n),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14.5, color: AppColors.mutedText, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _controls(AppLocalizations l10n) {
    return Row(
      children: [
        // Back (hidden on the first page, keeps its space so nothing jumps)
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _currentPage == 0 ? 0 : 1,
          child: IgnorePointer(
            ignoring: _currentPage == 0,
            child: TextButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(l10n.back),
              style: TextButton.styleFrom(foregroundColor: AppColors.mutedText),
            ),
          ),
        ),
        const Spacer(),
        _NextButton(isLast: _isLast, l10n: l10n, onTap: _next),
      ],
    );
  }

  // ── Mobile ─────────────────────────────────────────────────────────────────

  Widget _buildMobile(BuildContext context, AppLocalizations l10n) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, topPad + 12, 16, 0),
                child: Row(children: [
                  const _Brand(),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _isLast ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: _isLast,
                      child: _SkipButton(onTap: () => context.go('/register'), l10n: l10n),
                    ),
                  ),
                ]),
              ),
              Expanded(
                  child:
                      _illustrations(padding: const EdgeInsets.fromLTRB(14, 12, 14, 16), radius: 24, fillWidth: true)),
            ],
          ),
        ),
        SlideTransition(
          position: Tween(begin: const Offset(0, 0.25), end: Offset.zero)
              .animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic)),
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -6))],
            ),
            padding: EdgeInsets.fromLTRB(24, 22, 20, botPad + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fixed height so the card never jumps between pages / languages.
                SizedBox(
                  height: 160,
                  child: Align(alignment: Alignment.topCenter, child: _textBlock(l10n, titleSize: 27)),
                ),
                const SizedBox(height: 8),
                _Dots(current: _currentPage, total: _pages.length, onTap: _goTo),
                const SizedBox(height: 14),
                _controls(l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _goTo(int i) => _controller.animateToPage(i, duration: _anim, curve: Curves.easeOutCubic);

  // ── Desktop ────────────────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context, AppLocalizations l10n) {
    final w = MediaQuery.of(context).size.width;
    final panel = (w * 0.46).clamp(320.0, 460.0);
    final gap = w < 1000 ? 28.0 : 56.0;
    return Row(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _illustrations(padding: EdgeInsets.fromLTRB(gap, 64, gap, gap), radius: 32),
              Positioned(
                top: 20,
                right: 20,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _isLast ? 0 : 1,
                  child: _SkipButton(onTap: () => context.go('/register'), l10n: l10n),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: panel,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(-6, 0))],
          ),
          padding: EdgeInsets.symmetric(horizontal: panel < 400 ? 28 : 48, vertical: 40),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/app_icon.png', width: 32, height: 32, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  const Text('SplitSure',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepNavy)),
                ],
              ),
              const Spacer(),
              _textBlock(l10n, titleSize: 32),
              const SizedBox(height: 28),
              _Dots(current: _currentPage, total: _pages.length, onTap: _goTo),
              const Spacer(),
              _controls(l10n),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Two-tone title ───────────────────────────────────────────────────────────

class _TwoToneTitle extends StatelessWidget {
  final _PageData data;
  final double fontSize;

  const _TwoToneTitle({required this.data, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: data.titleAccent(l10n), style: const TextStyle(color: AppColors.teal)),
          TextSpan(text: data.titleRest(l10n), style: const TextStyle(color: AppColors.deepNavy)),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, height: 1.18, letterSpacing: -0.3),
    );
  }
}

// ─── Dot indicators ───────────────────────────────────────────────────────────

class _Dots extends StatelessWidget {
  final int current;
  final int total;
  final ValueChanged<int> onTap;

  const _Dots({required this.current, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == current;
        return GestureDetector(
          onTap: () => onTap(i),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              width: active ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.teal : const Color(0xFFCBD5E0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Next / Get Started button ────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final bool isLast;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _NextButton({required this.isLast, required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: isLast ? 26 : 22, vertical: 14),
          decoration: BoxDecoration(
            color: isLast ? AppColors.teal : AppColors.deepNavy,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: (isLast ? AppColors.teal : AppColors.deepNavy).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    isLast ? l10n.getStarted : l10n.next,
                    key: ValueKey(isLast),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skip button ──────────────────────────────────────────────────────────────

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _SkipButton({required this.onTap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.skip,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.mutedText)),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Page data ────────────────────────────────────────────────────────────────

typedef _L10nText = String Function(AppLocalizations l10n);

class _PageData {
  final String image;
  final _L10nText titleAccent;
  final _L10nText titleRest;
  final _L10nText subtitle;

  const _PageData({
    required this.image,
    required this.titleAccent,
    required this.titleRest,
    required this.subtitle,
  });
}

// ─── Illustration card ────────────────────────────────────────────────────────

/// Shows the whole illustration (never cropped) as a rounded card with a soft
/// shadow, sized to the largest box of the image's aspect ratio that fits.
class _ImageCard extends StatelessWidget {
  final String image;
  final double radius;

  /// Phones: span the full available width (trimming a little off the top and
  /// bottom on short screens) instead of shrinking to fit the height.
  final bool fillWidth;
  const _ImageCard({required this.image, required this.radius, this.fillWidth = false});

  /// All onboarding illustrations are portrait, roughly 4:5.4.
  static const _aspect = 800 / 1080;

  @override
  Widget build(BuildContext context) {
    if (fillWidth) {
      return LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final h = math.min(c.maxHeight, w / _aspect);
        return SizedBox(width: w, height: h, child: _card());
      });
    }
    return AspectRatio(aspectRatio: _aspect, child: _card());
  }

  Widget _card() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.14), blurRadius: 30, offset: const Offset(0, 14)),
          BoxShadow(color: AppColors.teal.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(fit: StackFit.expand, children: [
          // Biased upwards: the faces/shields near the top stay in view when trimmed.
          Image.asset(image, fit: BoxFit.cover, alignment: const Alignment(0, -0.3)),
          // Thin inner border so the light image edges read as a clean frame.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Brand (mobile top bar) ───────────────────────────────────────────────────

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset('assets/images/app_icon.png', width: 30, height: 30, fit: BoxFit.cover),
      ),
      const SizedBox(width: 8),
      const Text.rich(
        TextSpan(children: [
          TextSpan(text: 'Split', style: TextStyle(color: AppColors.deepNavy)),
          TextSpan(text: 'Sure', style: TextStyle(color: AppColors.teal)),
        ]),
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
      ),
    ]);
  }
}
