import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';

enum WelcomeKind { back, newAccount }

/// Set right before sign-in / sign-up; the main shell shows the banner once and clears it.
final pendingWelcomeProvider = StateProvider<WelcomeKind?>((ref) => null);

/// A card that slides down from the top, greets the user, and slides away.
class WelcomeBanner extends StatefulWidget {
  final WelcomeKind kind;
  final String firstName;
  final VoidCallback onDone;

  const WelcomeBanner({super.key, required this.kind, required this.firstName, required this.onDone});

  @override
  State<WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<WelcomeBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    reverseDuration: const Duration(milliseconds: 380),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _c.forward();
    });
    _timer = Timer(const Duration(milliseconds: 3800), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNew = widget.kind == WelcomeKind.newAccount;
    final title = isNew ? l10n.welcomeNewName(widget.firstName) : l10n.welcomeBackName(widget.firstName);
    final subtitle = isNew ? l10n.welcomeNewSubtitle : l10n.welcomeBackSubtitle;

    final slide = Tween(begin: const Offset(0, -1.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _c, curve: Curves.elasticOut, reverseCurve: Curves.easeInCubic),
    );
    final iconScale = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.35, 1, curve: Curves.elasticOut),
    );

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _c, curve: const Interval(0, 0.4)),
              child: GestureDetector(
                onTap: _dismiss,
                onVerticalDragEnd: (_) => _dismiss(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF142B4A), Color(0xFF0D9488)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepNavy.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ScaleTransition(
                            scale: iconScale,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(isNew ? Icons.celebration_rounded : Icons.waving_hand_rounded,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// Celebratory dialog shown after sign-up when Supabase requires e-mail confirmation.
Future<void> showAccountCreatedDialog(BuildContext context, AppLocalizations l10n) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: l10n.accountCreatedTitle,
    barrierColor: AppColors.deepNavy.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      final check = CurvedAnimation(parent: anim, curve: const Interval(0.4, 1, curve: Curves.elasticOut));
      return Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.85 + 0.15 * curved.value,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Material(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: check,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 56),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(l10n.accountCreatedTitle,
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                        const SizedBox(height: 8),
                        Text(l10n.accountCreatedCheckEmail,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: AppColors.mutedText, height: 1.5)),
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(l10n.continueToSignIn),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
