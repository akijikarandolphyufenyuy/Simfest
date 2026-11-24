import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// True while the login screen plays its welcome greeting after a successful
/// sign-in. The router leaves the user on /login until it is cleared, so the
/// greeting runs on the login screen itself (no extra screen) before /home.
final loginGreetingActive = ValueNotifier<bool>(false);

/// Overlay shown on top of the login form after a correct sign-in: the screen
/// dims, a greeting card with a smiling face drops from the top to the center,
/// holds for a moment, then slides away and [onDone] is called.
class LoginWelcomeOverlay extends StatefulWidget {
  final String firstName;
  final VoidCallback onDone;

  const LoginWelcomeOverlay({super.key, required this.firstName, required this.onDone});

  @override
  State<LoginWelcomeOverlay> createState() => _LoginWelcomeOverlayState();
}

class _LoginWelcomeOverlayState extends State<LoginWelcomeOverlay> with TickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    reverseDuration: const Duration(milliseconds: 380),
  );
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _ctrl.forward();
    if (!mounted) return;
    _wave.forward();
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slide = Tween<Offset>(begin: const Offset(0, -2.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut, reverseCurve: Curves.easeInCubic),
    );
    final iconScale = CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0, curve: Curves.elasticOut));
    final name = widget.firstName.trim();

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(children: [
          // Dim the login form underneath (also blocks taps while greeting).
          FadeTransition(
            opacity: CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.35)),
            child: ModalBarrier(dismissible: false, color: AppColors.deepNavy.withValues(alpha: 0.72)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SlideTransition(
                position: slide,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF142B4A), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 32,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      ScaleTransition(
                        scale: iconScale,
                        child: AnimatedBuilder(
                          animation: _wave,
                          builder: (_, child) => Transform.rotate(
                            angle: math.sin(_wave.value * math.pi * 4) * 0.22 * (1 - _wave.value),
                            child: child,
                          ),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.sentiment_very_satisfied_rounded, color: Color(0xFFFFD54F), size: 34),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name.isEmpty ? l10n.welcomeBackPlain : l10n.welcomeBackName(name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.greatToSeeYou,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                              ),
                            ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
