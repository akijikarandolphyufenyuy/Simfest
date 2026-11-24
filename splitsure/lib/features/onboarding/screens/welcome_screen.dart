import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../shared/widgets/animations.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────

class _Palette {
  static const Color pageBg = Color(0xFFEAF4FB);
  static const Color navy = Color(0xFF0B2A66);
  static const Color teal = Color(0xFF14A89C);
  static const Color tealDark = Color(0xFF12A394);
  static const Color tealLight = Color(0xFF1BB5A6);
  static const Color greyLabel = Color(0xFF5B6B7B);
  static const Color greyFooter = Color(0xFF7A8896);
  static const Color divider = Color(0xFFD5DEE8);
  static const Color cardTop = Color(0xFFFFFFFF);
  static const Color cardBottom = Color(0xFFF2F8FD);
}

// ─── Entry point ─────────────────────────────────────────────────────────────

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final selectedLang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: _Palette.pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        24,
                  ),
                  child: _Card(
                    selectedLang: selectedLang,
                    onLangChanged: (lang) {
                      ref.read(localeProvider.notifier).setLocale(Locale(lang));
                    },
                    onGetStarted: () => context.go('/onboarding'),
                    onSignIn: () => context.go('/login'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String selectedLang;
  final ValueChanged<String> onLangChanged;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const _Card({
    required this.selectedLang,
    required this.onLangChanged,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_Palette.cardTop, _Palette.cardBottom],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FadeSlideIn(child: _LogoBlock()),
            FadeSlideIn(delay: stagger(2), offset: const Offset(0, 0.04), child: const _HeroImage()),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: stagger(4),
              child: _LanguageSection(selectedLang: selectedLang, onLangChanged: onLangChanged),
            ),
            FadeSlideIn(
              delay: stagger(5),
              child: _GetStartedButton(selectedLang: selectedLang, onPressed: onGetStarted),
            ),
            FadeSlideIn(delay: stagger(6), child: _SignInLink(onPressed: onSignIn)),
            FadeSlideIn(delay: stagger(7), child: _Footer(selectedLang: selectedLang)),
          ],
        ),
      ),
    );
  }
}

// ─── 1) Logo Block ────────────────────────────────────────────────────────────

class _LogoBlock extends StatelessWidget {
  const _LogoBlock();
  @override
  Widget build(BuildContext context) {
    final cardWidth = math.min(
      MediaQuery.of(context).size.width - 24,
      420.0,
    );
    final logoWidth = cardWidth * 0.62;
    return Container(
      color: _Palette.cardTop,
      padding: const EdgeInsets.only(top: 28, bottom: 4),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The logo file has an English-only tagline baked into its bottom
          // ~22%. Crop it off and render the tagline as localized text instead.
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _logoMarkHeightFactor,
              child: Image.asset(
                'assets/images/logo.jpeg',
                width: logoWidth,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _Palette.navy,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 56,
            height: 2,
            decoration: BoxDecoration(
              color: _Palette.teal,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fraction of logo.jpeg (from the top) that holds the icon + wordmark,
/// i.e. everything above the baked-in tagline.
const double _logoMarkHeightFactor = 0.775;

// ─── Sign In link ─────────────────────────────────────────────────────────────

class _SignInLink extends StatelessWidget {
  final VoidCallback onPressed;
  const _SignInLink({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l10n.alreadyHaveAccount,
            style: const TextStyle(fontSize: 13, color: _Palette.greyLabel),
          ),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              minimumSize: const Size(0, 36),
              foregroundColor: _Palette.teal,
            ),
            child: Text(
              l10n.signIn,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2) Hero Image ────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  const _HeroImage();
  @override
  Widget build(BuildContext context) {
    // The whole illustration, framed as a rounded card (landing.jpeg is ~1.3:1).
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: _Palette.navy.withValues(alpha: 0.16), blurRadius: 22, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 1002 / 774,
            child: Image.asset('assets/images/landing.png', fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

// ─── 3) Language Section ──────────────────────────────────────────────────────

class _LanguageSection extends StatelessWidget {
  final String selectedLang;
  final ValueChanged<String> onLangChanged;

  const _LanguageSection({
    required this.selectedLang,
    required this.onLangChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.chooseLanguageBilingual,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: _Palette.greyLabel,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: _LanguageButton(
                    label: 'English',
                    langCode: 'en',
                    selected: selectedLang == 'en',
                    flag: const _UKFlag(),
                    onTap: () => onLangChanged('en'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LanguageButton(
                    label: 'Français',
                    langCode: 'fr',
                    selected: selectedLang == 'fr',
                    flag: const _FrenchFlag(),
                    onTap: () => onLangChanged('fr'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Language Button ──────────────────────────────────────────────────────────

class _LanguageButton extends StatelessWidget {
  final String label;
  final String langCode;
  final bool selected;
  final Widget flag;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.langCode,
    required this.selected,
    required this.flag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        decoration: BoxDecoration(
          color: selected ? _Palette.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _Palette.navy,
            width: selected ? 0 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            flag,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _Palette.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── UK Flag ──────────────────────────────────────────────────────────────────

class _UKFlag extends StatelessWidget {
  const _UKFlag();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(painter: _UnionJackPainter()),
      ),
    );
  }
}

class _UnionJackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Blue background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF012169),
    );

    final white = Paint()..color = Colors.white;
    final red = Paint()..color = const Color(0xFFC8102E);

    // White diagonals (St Andrew's cross + St Patrick's cross combined)
    final diagPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = h * 0.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(w, h), diagPaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), diagPaint);

    // Red diagonals (thinner, offset)
    final redDiagPaint = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = h * 0.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(w, h), redDiagPaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), redDiagPaint);

    // White cross (St George)
    canvas.drawRect(Rect.fromLTWH(w * 0.375, 0, w * 0.25, h), white);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.375, w, h * 0.25), white);

    // Red cross (St George, thinner)
    canvas.drawRect(Rect.fromLTWH(w * 0.417, 0, w * 0.167, h), red);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.417, w, h * 0.167), red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── French Flag ──────────────────────────────────────────────────────────────

class _FrenchFlag extends StatelessWidget {
  const _FrenchFlag();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 18,
        height: 18,
        child: Row(
          children: [
            Expanded(child: Container(color: const Color(0xFF0055A4))),
            Expanded(child: Container(color: Colors.white)),
            Expanded(child: Container(color: const Color(0xFFEF4135))),
          ],
        ),
      ),
    );
  }
}

// ─── 4) Get Started Button ────────────────────────────────────────────────────

class _GetStartedButton extends StatelessWidget {
  final String selectedLang;
  final VoidCallback onPressed;

  const _GetStartedButton({
    required this.selectedLang,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.getStarted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [_Palette.tealDark, _Palette.tealLight],
          ),
          boxShadow: [
            BoxShadow(
              color: _Palette.teal.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 5) Footer ────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final String selectedLang;

  const _Footer({required this.selectedLang});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!.welcomeFooter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: _Palette.divider, thickness: 1, height: 1),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9.5,
                color: _Palette.greyFooter,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(color: _Palette.divider, thickness: 1, height: 1),
          ),
        ],
      ),
    );
  }
}
