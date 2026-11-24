import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/animations.dart';
import '../../shared/widgets/form_widgets.dart';

/// Support address shown at the end of the About screen.
const kSupportEmail = 'akijikarandolphy@gmail.com';

/// About SplitSure: the app icon, what SplitSure is, why it is made for Cameroon,
/// what you can do with it, and how to reach support. Everything is centered on a
/// slowly moving gradient with floating music notes.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with TickerProviderStateMixin {
  /// Drives the background, the notes, the icon ring and the shimmer (one 12 s loop).
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 12))
    ..repeat();
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward();

  @override
  void dispose() {
    _loop.dispose();
    _enter.dispose();
    super.dispose();
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0D2137),
      body: Stack(children: [
        Positioned.fill(child: _AnimatedBackdrop(loop: _loop)),
        SafeArea(
          child: Column(children: [
            // Back button + centered title.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
                  onPressed: _back,
                ),
                Expanded(
                  child: Text(l10n.aboutTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      const SizedBox(height: 10),
                      _AppIconHero(loop: _loop, enter: _enter),
                      const SizedBox(height: 22),
                      FadeSlideIn(delay: stagger(2), child: _ShimmerName(loop: _loop)),
                      const SizedBox(height: 10),
                      FadeSlideIn(delay: stagger(3), child: _Pill(text: l10n.aboutTagline)),
                      const SizedBox(height: 30),
                      FadeSlideIn(
                        delay: stagger(4),
                        child: _GlassCard(
                          icon: Icons.music_note_rounded,
                          title: l10n.aboutWhatTitle,
                          child: _Body(l10n.aboutWhatBody),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeSlideIn(delay: stagger(5), child: _CameroonCard(loop: _loop)),
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        delay: stagger(6),
                        child: _GlassCard(
                          icon: Icons.auto_awesome_rounded,
                          title: l10n.aboutFeaturesTitle,
                          child: _FeatureGrid(enter: _enter),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        delay: stagger(7),
                        child: _GlassCard(
                          icon: Icons.verified_user_rounded,
                          title: l10n.aboutPromiseTitle,
                          child: _Body(l10n.aboutPromiseBody),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeSlideIn(delay: stagger(8), child: const _SupportCard()),
                      const SizedBox(height: 26),
                      FadeSlideIn(
                        delay: stagger(9),
                        child: Column(children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFFF6B81)),
                            const SizedBox(width: 6),
                            Text(l10n.aboutMadeWithLove,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFFCBE8E4), fontSize: 12.5)),
                          ]),
                          const SizedBox(height: 6),
                          Text('SplitSure · v1.0.0 · © ${DateTime.now().year}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF8ECFC9), fontSize: 11.5)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Background ─────────────────────────────────────────────────────────────

class _AnimatedBackdrop extends StatelessWidget {
  final Animation<double> loop;
  const _AnimatedBackdrop({required this.loop});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (_, __) {
        final a = loop.value * 2 * math.pi;
        return Stack(children: [
          // The gradient slowly turns.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(math.cos(a), math.sin(a)),
                end: Alignment(-math.cos(a), -math.sin(a)),
                colors: const [Color(0xFF0D2137), Color(0xFF142B4A), Color(0xFF0E4A47), Color(0xFF0D9488)],
                stops: const [0.0, 0.4, 0.75, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          // Soft glowing blobs drifting around.
          _blob(context, 0.15 + 0.08 * math.sin(a), 0.12 + 0.05 * math.cos(a), 220, const Color(0xFF12B8A6), 0.20),
          _blob(context, 0.85 + 0.06 * math.cos(a), 0.45 + 0.06 * math.sin(a), 260, const Color(0xFF1E3F6F), 0.45),
          _blob(context, 0.30 + 0.07 * math.cos(a + 1), 0.85 + 0.04 * math.sin(a), 200, const Color(0xFF12B8A6), 0.14),
          // Music notes floating up.
          CustomPaint(painter: _NotesPainter(loop.value), size: Size.infinite),
        ]);
      },
    );
  }

  Widget _blob(BuildContext context, double x, double y, double size, Color color, double alpha) {
    final s = MediaQuery.of(context).size;
    return Positioned(
      left: s.width * x - size / 2,
      top: s.height * y - size / 2,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)]),
          ),
        ),
      ),
    );
  }
}

class _NotesPainter extends CustomPainter {
  final double t;
  _NotesPainter(this.t);

  // Material icons (already bundled) instead of ♪ characters, which would make
  // Flutter Web download an extra symbol font.
  static const _glyphs = [Icons.music_note_rounded, Icons.audiotrack_rounded, Icons.queue_music_rounded];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 14; i++) {
      final seed = i * 0.6180339;
      final p = (t * (0.6 + (i % 4) * 0.15) + seed) % 1; // 0 → 1 upward
      final x = size.width * ((seed * 7.3) % 1) + math.sin((p + seed) * 2 * math.pi) * 18;
      final y = size.height * (1.05 - p * 1.15);
      final opacity = math.sin(p * math.pi) * 0.16;
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(_glyphs[i % _glyphs.length].codePoint),
          style: TextStyle(
            color: Colors.white.withValues(alpha: opacity),
            fontSize: 16.0 + (i % 5) * 5,
            fontFamily: _glyphs[i % _glyphs.length].fontFamily,
            package: _glyphs[i % _glyphs.length].fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(_NotesPainter old) => old.t != t;
}

// ── Hero ───────────────────────────────────────────────────────────────────

class _AppIconHero extends StatelessWidget {
  final Animation<double> loop;
  final Animation<double> enter;
  const _AppIconHero({required this.loop, required this.enter});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([loop, enter]),
      builder: (_, __) {
        final pop = Curves.elasticOut.transform(enter.value.clamp(0.0, 1.0));
        final float = math.sin(loop.value * 2 * math.pi * 3) * 5;
        final pulse = 1 + math.sin(loop.value * 2 * math.pi * 6) * 0.03;
        return Transform.translate(
          offset: Offset(0, float),
          child: Transform.scale(
            scale: pop,
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(alignment: Alignment.center, children: [
                // Rotating gradient ring.
                Transform.rotate(
                  angle: loop.value * 2 * math.pi * 2,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        Color(0x0012B8A6),
                        Color(0xFF12B8A6),
                        Color(0xFFFFD54F),
                        Color(0x0012B8A6),
                      ]),
                    ),
                  ),
                ),
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0F2A44)),
                ),
                // The app icon.
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: AppColors.teal.withValues(alpha: 0.55), blurRadius: 34, spreadRadius: 2),
                        BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerName extends StatelessWidget {
  final Animation<double> loop;
  const _ShimmerName({required this.loop});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (_, child) {
        final slide = ((loop.value * 3) % 1) * 4 - 1.5;
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: const [AppColors.white, Color(0xFF5EEAD4), AppColors.white, AppColors.white],
            stops: const [0.0, 0.35, 0.6, 1.0],
            transform: _SlidingGradientTransform(slide),
          ).createShader(bounds),
          child: child,
        );
      },
      child: const Text.rich(
        TextSpan(children: [
          TextSpan(text: 'Split'),
          TextSpan(text: 'Sure'),
        ]),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.white, letterSpacing: 1.2),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.45)),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF5EEAD4), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }
}

// ── Cards ──────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _GlassCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A4060).withValues(alpha: 0.82), const Color(0xFF0F2A44).withValues(alpha: 0.78)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF12B8A6), Color(0xFF0D9488)]),
            boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.45), blurRadius: 14)],
          ),
          child: Icon(icon, color: AppColors.white, size: 24),
        ),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.white)),
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
  Widget build(BuildContext context) => Text(text,
      textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFFD5EEEA), height: 1.7));
}

class _CameroonCard extends StatelessWidget {
  final Animation<double> loop;
  const _CameroonCard({required this.loop});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF007A3D), Color(0xFF0B5E3A), Color(0xFF8E1020), Color(0xFFCE1126)],
          stops: [0.0, 0.45, 0.75, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Waving flag.
        AnimatedBuilder(
          animation: loop,
          builder: (_, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(math.sin(loop.value * 2 * math.pi * 4) * 0.25),
            child: child,
          ),
          child: const _CameroonFlag(width: 78),
        ),
        const SizedBox(height: 14),
        Text(l10n.aboutCameroonTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 10),
        Text(l10n.aboutCameroonBody,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFFFFF1F1), height: 1.7)),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          _Chip(Icons.phone_android_rounded, l10n.aboutCameroonPay),
          _Chip(Icons.translate_rounded, l10n.aboutCameroonLang),
          _Chip(Icons.payments_rounded, l10n.aboutCameroonPrice),
        ]),
      ]),
    );
  }
}

/// Green–red–yellow vertical stripes with the yellow star (no emoji font needed).
class _CameroonFlag extends StatelessWidget {
  final double width;
  const _CameroonFlag({required this.width});

  @override
  Widget build(BuildContext context) {
    final h = width * 2 / 3;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: width,
          height: h,
          child: Row(children: [
            Expanded(child: Container(color: const Color(0xFF007A5E))),
            Expanded(
              child: Container(
                color: const Color(0xFFCE1126),
                alignment: Alignment.center,
                child: Icon(Icons.star_rounded, color: const Color(0xFFFCD116), size: h * 0.42),
              ),
            ),
            Expanded(child: Container(color: const Color(0xFFFCD116))),
          ]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.white),
        const SizedBox(width: 6),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.white, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final Animation<double> enter;
  const _FeatureGrid({required this.enter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (Icons.shield_rounded, l10n.protect, l10n.aboutFeatProtect),
      (Icons.badge_rounded, l10n.musicPassport, l10n.aboutFeatPassport),
      (Icons.hub_rounded, l10n.opportunityHub, l10n.aboutFeatHub),
      (Icons.campaign_rounded, l10n.reach, l10n.aboutFeatReach),
      (Icons.handshake_rounded, l10n.dealflow, l10n.aboutFeatDealflow),
    ];
    return LayoutBuilder(builder: (context, c) {
      final perRow = c.maxWidth >= 420 ? 3 : 2;
      final w = (c.maxWidth - (perRow - 1) * 10) / perRow;
      return Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
        for (var i = 0; i < items.length; i++)
          SizedBox(
            width: w,
            child: FadeSlideIn(
              delay: Duration(milliseconds: 500 + i * 110),
              child: _FeatureTile(icon: items[i].$1, title: items[i].$2, text: items[i].$3),
            ),
          ),
      ]);
    });
  }
}

class _FeatureTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String text;
  const _FeatureTile({required this.icon, required this.title, required this.text});

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.04 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          constraints: const BoxConstraints(minHeight: 168),
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: _hover ? 0.14 : 0.08),
            border: Border.all(color: AppColors.teal.withValues(alpha: _hover ? 0.6 : 0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(widget.icon, color: const Color(0xFF5EEAD4), size: 21),
            ),
            const SizedBox(height: 10),
            Text(widget.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.white)),
            const SizedBox(height: 4),
            Text(widget.text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFFCBE8E4), height: 1.45)),
          ]),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF12B8A6), Color(0xFF0D9488), Color(0xFF1E3F6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.support_agent_rounded, color: AppColors.white, size: 28),
        ),
        const SizedBox(height: 12),
        Text(l10n.aboutSupportTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white)),
        const SizedBox(height: 8),
        Text(l10n.aboutSupportBody,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFFEFFFFC), height: 1.6)),
        const SizedBox(height: 18),
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30),
          elevation: 4,
          shadowColor: Colors.black38,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => launchUrl(Uri.parse('mailto:$kSupportEmail?subject=SplitSure%20support')),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.email_rounded, color: AppColors.teal, size: 19),
                SizedBox(width: 8),
                Flexible(
                  child: Text(kSupportEmail,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: kSupportEmail));
            if (context.mounted) showSuccess(context, l10n.aboutSupportCopied);
          },
          icon: const Icon(Icons.copy_rounded, size: 15, color: AppColors.white),
          label: Text(MaterialLocalizations.of(context).copyButtonLabel,
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
