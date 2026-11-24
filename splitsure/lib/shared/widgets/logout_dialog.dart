import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Log-out confirmation: a card that drops from the top of the screen to the
/// center (with a little bounce), asks to confirm, then signs out.
Future<void> showLogoutConfirm(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final router = GoRouter.of(context);
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: l10n.cancel,
    barrierColor: AppColors.deepNavy.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 650),
    pageBuilder: (ctx, _, __) => _LogoutCard(
      onConfirm: () async {
        await ref.read(authServiceProvider).signOut();
        if (ctx.mounted) Navigator.of(ctx).pop();
        router.go('/login');
      },
    ),
    transitionBuilder: (ctx, anim, _, child) {
      // Drops from above the screen, overshoots slightly and settles in the center.
      final drop = CurvedAnimation(parent: anim, curve: Curves.elasticOut, reverseCurve: Curves.easeInBack);
      final h = MediaQuery.of(ctx).size.height;
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: const Interval(0, 0.3)),
        child: AnimatedBuilder(
          animation: drop,
          builder: (_, c) => Transform.translate(offset: Offset(0, -h * 0.6 * (1 - drop.value)), child: c),
          child: child,
        ),
      );
    },
  );
}

class _LogoutCard extends StatefulWidget {
  final Future<void> Function() onConfirm;
  const _LogoutCard({required this.onConfirm});

  @override
  State<_LogoutCard> createState() => _LogoutCardState();
}

class _LogoutCardState extends State<_LogoutCard> with SingleTickerProviderStateMixin {
  late final AnimationController _icon = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _icon.forward();
    });
  }

  @override
  void dispose() {
    _icon.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pop = CurvedAnimation(parent: _icon, curve: Curves.elasticOut);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.deepNavy.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 18)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Header band with the icon.
                Container(
                  height: 96,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF142B4A), Color(0xFF1E3F6F), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: pop,
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: const Icon(Icons.logout_rounded, color: AppColors.white, size: 30),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(l10n.logoutTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
                    const SizedBox(height: 8),
                    Text(l10n.logoutConfirm,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: AppColors.mutedText, height: 1.5)),
                    const SizedBox(height: 22),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            side: const BorderSide(color: AppColors.cardBorder, width: 1.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(l10n.stayLoggedIn,
                              style: const TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _busy ? null : _confirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(0, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                                : Text(l10n.logout,
                                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
