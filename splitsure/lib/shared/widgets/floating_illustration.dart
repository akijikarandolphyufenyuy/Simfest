import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// An illustration that pops in, then gently floats over a soft teal glow.
class FloatingIllustration extends StatefulWidget {
  final String asset;
  final double size;
  const FloatingIllustration({super.key, required this.asset, this.size = 170});

  @override
  State<FloatingIllustration> createState() => _FloatingIllustrationState();
}

class _FloatingIllustrationState extends State<FloatingIllustration> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
    ..forward();
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
    ..repeat();

  @override
  void dispose() {
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final pop = CurvedAnimation(parent: _enter, curve: Curves.easeOutBack);
    return SizedBox(
      width: s * 1.15,
      height: s * 1.08,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _float]),
        builder: (context, _) {
          final t = _float.value * 2 * math.pi;
          final dy = math.sin(t) * 6;
          final glow = 0.85 + 0.15 * math.sin(t);
          return Stack(alignment: Alignment.center, children: [
            // Soft glow
            Transform.scale(
              scale: glow * pop.value,
              child: Container(
                width: s * 0.95,
                height: s * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.teal.withValues(alpha: 0.22),
                    AppColors.teal.withValues(alpha: 0.0),
                  ]),
                ),
              ),
            ),
            // Soft, blurred ground shadow that shrinks as the image rises
            Positioned(
              bottom: s * 0.03,
              child: Opacity(
                opacity: _enter.value,
                child: Container(
                  width: s * (0.6 - dy / 160),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepNavy.withValues(alpha: 0.16 - dy / 150),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: pop.value,
                // A deliberate rounded tile, so the artwork's own background reads as a card.
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(s * 0.2),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.14), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepNavy.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(s * 0.2),
                    child: Image.asset(widget.asset, width: s, height: s, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
