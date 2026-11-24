import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../models/passport.dart';

/// Shown when someone without a SplitSure session opens a shared passport link.
/// Teases the passport (photo, name, role, place), then asks them to create an
/// account or sign in. The caller has already saved the link, so they land back
/// on the full passport right after signing up / in.
class PassportJoinGate extends StatelessWidget {
  final MusicPassport? passport;
  const PassportJoinGate({super.key, required this.passport});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = passport;
    final name = p?.stageName ?? 'SplitSure';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF142B4A), Color(0xFF1E3F6F), AppColors.teal],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Brand
                  FadeSlideIn(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset('assets/images/app_icon.png', width: 34, height: 34, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text.rich(
                          TextSpan(children: [
                            TextSpan(text: 'Split', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'Sure', style: TextStyle(color: Color(0xFF12B8A6))),
                          ]),
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  // Card
                  FadeSlideIn(
                    delay: stagger(1),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 14)),
                        ],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if (p != null) _Teaser(passport: p),
                        if (p != null) const SizedBox(height: 18),
                        if (p != null) _LockedPreview(label: l10n.passportGateLocked),
                        const SizedBox(height: 20),
                        Text(l10n.passportGateTitle(name),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.deepNavy, height: 1.25)),
                        const SizedBox(height: 8),
                        Text(l10n.passportGateBody(name),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13.5, color: AppColors.mutedText, height: 1.5)),
                        const SizedBox(height: 16),
                        for (final (i, perk) in [
                          (Icons.badge_rounded, l10n.passportGatePerk1),
                          (Icons.collections_bookmark_rounded, l10n.passportGatePerk2),
                          (Icons.handshake_rounded, l10n.passportGatePerk3),
                        ].indexed)
                          FadeSlideIn(
                            delay: stagger(3 + i),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(perk.$1, size: 17, color: AppColors.teal),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(perk.$2,
                                      style: const TextStyle(
                                          fontSize: 13.5, color: AppColors.deepNavy, fontWeight: FontWeight.w600)),
                                ),
                              ]),
                            ),
                          ),
                        const SizedBox(height: 14),
                        _GradientButton(
                          label: l10n.passportGateCreate,
                          onTap: () => context.go('/register'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            side: const BorderSide(color: AppColors.teal, width: 1.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => context.go('/login'),
                          child: Text(l10n.passportGateSignIn,
                              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.subdirectory_arrow_left_rounded, size: 15, color: AppColors.mutedText),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(l10n.passportGateBack,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Teaser extends StatelessWidget {
  final MusicPassport passport;
  const _Teaser({required this.passport});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = passport;
    final place = [p.city, p.country].where((x) => x != null && x.trim().isNotEmpty).join(', ');
    return Column(children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFF142B4A), AppColors.teal]),
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 41,
              backgroundColor: AppColors.teal.withValues(alpha: 0.12),
              backgroundImage: (p.photoUrl?.isNotEmpty ?? false) ? NetworkImage(p.photoUrl!) : null,
              child: (p.photoUrl?.isNotEmpty ?? false)
                  ? null
                  : Text(p.stageName.isNotEmpty ? p.stageName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(p.stageName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
      const SizedBox(height: 6),
      Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
        _Pill(icon: Icons.music_note_rounded, text: passportRoleLabel(l10n, p.primaryRole)),
        if (place.isNotEmpty) _Pill(icon: Icons.place_rounded, text: place),
      ]),
    ]);
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppColors.lightBg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppColors.teal),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.deepNavy, fontWeight: FontWeight.w600)),
        ]),
      );
}

/// A blurred stand-in for the passport details, with a lock badge.
class _LockedPreview extends StatelessWidget {
  final String label;
  const _LockedPreview({required this.label});

  @override
  Widget build(BuildContext context) {
    Widget bar(double w) => Container(
          height: 10,
          width: w,
          margin: const EdgeInsets.only(bottom: 9),
          decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(6)),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(alignment: Alignment.center, children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.lightBg,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              bar(180),
              bar(240),
              bar(140),
              Row(children: [
                for (final w in [60.0, 74.0, 52.0]) ...[
                  Container(
                    width: w,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ]),
            ]),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.25), blurRadius: 12)],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFF142B4A), AppColors.teal]),
          boxShadow: [
            BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              height: 54,
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                  const SizedBox(width: 12),
                ]),
              ),
            ),
          ),
        ),
      );
}
