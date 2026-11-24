import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/l10n/app_localizations.dart';
import 'animations.dart';

/// Responsive wrapper for auth screens (login / register).
/// Mobile: a centred, width-constrained card. Desktop: image panel + centred form panel.
class AuthLayout extends StatelessWidget {
  final Widget child;

  /// Replaces the small logo at the top of the card (e.g. an illustration).
  final Widget? header;

  /// Back button action; defaults to the welcome screen.
  final VoidCallback? onBack;

  const AuthLayout({super.key, required this.child, this.header, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      body: isDesktop ? _desktop(context) : _mobile(context),
    );
  }

  Widget _mobile(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: FadeSlideIn(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.deepNavy.withValues(alpha: 0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            header ?? const _LogoMark(size: 56),
                            SizedBox(height: header == null ? 22 : 12),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 8, left: 8, child: _BackToWelcome(onBack: onBack)),
        ],
      ),
    );
  }

  Widget _desktop(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: AppColors.deepNavy,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/images/landing.jpeg', fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.deepNavy.withValues(alpha: 0.35),
                        AppColors.deepNavy.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 56,
                  left: 56,
                  right: 56,
                  child: FadeSlideIn(
                    delay: stagger(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SplitSure',
                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.white)),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.tagline,
                          style: const TextStyle(fontSize: 18, color: AppColors.white, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 540,
          child: Container(
            color: AppColors.white,
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: FadeSlideIn(
                        child: Column(
                          children: [
                            header ?? const _LogoMark(size: 60),
                            SizedBox(height: header == null ? 28 : 14),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(top: 16, left: 16, child: _BackToWelcome(onBack: onBack)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 10),
        const Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Split', style: TextStyle(color: AppColors.deepNavy)),
            TextSpan(text: 'Sure', style: TextStyle(color: AppColors.teal)),
          ]),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ],
    );
  }
}

class _BackToWelcome extends StatelessWidget {
  final VoidCallback? onBack;
  const _BackToWelcome({this.onBack});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.deepNavy),
      onPressed: onBack ?? () => context.go('/welcome'),
    );
  }
}
