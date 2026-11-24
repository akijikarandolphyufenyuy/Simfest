import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../models/subscription.dart';
import 'subscription_screen.dart';

/// Shown once after sign-up (until a plan is chosen): Free or Pro.
/// Choosing Free is recorded server-side; Pro is granted only after a verified payment.
class PlanSelectionScreen extends ConsumerStatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  ConsumerState<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends ConsumerState<PlanSelectionScreen> {
  bool _busy = false;

  Future<void> _free() async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.rpc('choose_free_plan');
      ref.invalidate(entitlementProvider);
      if (mounted) _leave();
    } catch (e) {
      if (mounted) showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pro() async {
    if (await startProUpgrade(context, ref) && mounted) _leave();
  }

  /// Shown over the dashboard (existing accounts) → close; shown after sign-up → open the dashboard.
  void _leave() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8FAF7), AppColors.lightBg],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    FadeSlideIn(
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset('assets/images/app_icon.png',
                              width: 72,
                              height: 72,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.workspace_premium_rounded, size: 64, color: AppColors.teal)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: stagger(1),
                      child: Text(l10n.choosePlanTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.deepNavy)),
                    ),
                    const SizedBox(height: 6),
                    FadeSlideIn(
                      delay: stagger(2),
                      child: Text(l10n.choosePlanSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.mutedText, fontSize: 14)),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: stagger(3),
                      child: PlanOptionsRow(isPro: false, busy: _busy, onFree: _free, onPro: _pro),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
