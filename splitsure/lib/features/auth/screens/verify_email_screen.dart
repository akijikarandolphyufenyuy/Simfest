import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/auth_layout.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../../shared/widgets/welcome_banner.dart';
import 'password_reset_screens.dart' show OtpCodeBoxes;
import '../services/email_verification.dart';

/// Step 2 of sign-up: the 6-digit code from the "Confirm your SplitSure account" e-mail.
/// Correct code → the account is confirmed and signed in → plan selection → dashboard.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  /// True when we arrive from the sign-in screen (unconfirmed account): send a fresh code first.
  final bool resendOnOpen;
  const VerifyEmailScreen({super.key, required this.email, this.resendOnOpen = false});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _len = 6;
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  bool _done = false;
  String? _error;
  int _cooldown = 60;
  Timer? _timer;

  SupabaseClient get _client => Supabase.instance.client;

  /// Signed in already (Supabase "Confirm email" off): SplitSure sends its own code.
  late final bool _own = _client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _focus.addListener(() => setState(() {}));
    _code.addListener(() {
      setState(() => _error = null);
      // Verify as soon as the 6th digit is typed or pasted.
      if (_code.text.length == _len && !_busy && !_done) _verify();
    });
    if (_own) {
      // Our own code: send it as soon as the screen opens.
      WidgetsBinding.instance.addPostFrameCallback((_) => _resend(silent: true, first: true));
    } else if (widget.resendOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resend(silent: true));
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _message(AppLocalizations l10n, Object e) {
    if (e is VerificationError) {
      return switch (e.code) {
        'INVALID_CODE' || 'EXPIRED' => l10n.codeInvalid,
        'TOO_MANY_ATTEMPTS' || 'TOO_SOON' => l10n.tooManyRequests,
        _ => l10n.verifySendFailed,
      };
    }
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (e.statusCode == '429' || m.contains('rate limit') || m.contains('security purposes')) {
        return l10n.tooManyRequests;
      }
      if (m.contains('already') && m.contains('confirm')) return l10n.verifyAlreadyConfirmed;
      if (m.contains('expired') || m.contains('invalid') || m.contains('otp') || m.contains('token')) {
        return l10n.codeInvalid;
      }
      return e.message;
    }
    return friendlyError(e);
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    if (_code.text.length != _len) {
      setState(() => _error = l10n.codeInvalid);
      return;
    }
    setState(() => _busy = true);
    try {
      if (_own) {
        await checkVerificationCode(_code.text);
      } else {
        await _client.auth.verifyOTP(email: widget.email, token: _code.text, type: OtpType.signup);
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      // The dashboard greets the new account once the plan is chosen.
      ref.read(pendingWelcomeProvider.notifier).state = WelcomeKind.newAccount;
      setState(() => _done = true);
      await Future.delayed(const Duration(milliseconds: 1700));
      if (mounted) context.go('/choose-plan');
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      // Clear first: the controller listener resets the error on every change.
      _code.clear();
      setState(() => _error = _message(l10n, e));
      _focus.requestFocus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend({bool silent = false, bool first = false}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (_own) {
        final already = await sendVerificationCode();
        if (already) {
          // Nothing to verify (e.g. Google account): carry on.
          if (mounted) context.go('/choose-plan');
          return;
        }
        _startCooldown();
        if (mounted && !first) showSuccess(context, l10n.codeSent);
        return;
      }
      await _client.auth.resend(type: OtpType.signup, email: widget.email);
      _startCooldown();
      if (mounted) showSuccess(context, silent ? l10n.verifyNotConfirmed : l10n.codeSent);
    } on VerificationError catch (e) {
      // A code was sent moments ago (e.g. page reload): just keep waiting for it.
      if (e.code == 'TOO_SOON' && first) return;
      if (mounted) showError(context, _message(l10n, e));
    } catch (e) {
      if (mounted) showError(context, _message(l10n, e));
    }
  }

  /// Wrong address: leave this account and start again.
  Future<void> _restart() async {
    if (_own) await _client.auth.signOut();
    if (mounted) context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthLayout(
      onBack: _restart,
      header: _MailBadge(done: _done),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: child),
        ),
        child: _done ? _success(l10n) : _form(l10n),
      ),
    );
  }

  Widget _form(AppLocalizations l10n) {
    final len = _code.text.length;
    const base = TextStyle(fontSize: 13.5, color: AppColors.mutedText, height: 1.5);
    final sub = l10n.verifySubtitle(widget.email);
    final at = sub.indexOf(widget.email);
    return Column(key: const ValueKey('form'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FadeSlideIn(child: _Steps(current: 1, l10n: l10n)),
      const SizedBox(height: 18),
      FadeSlideIn(
        delay: stagger(1),
        child: Text(l10n.verifyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.deepNavy, height: 1.2)),
      ),
      const SizedBox(height: 8),
      FadeSlideIn(
        delay: stagger(1),
        child: at < 0
            ? Text(sub, textAlign: TextAlign.center, style: base)
            : Text.rich(
                TextSpan(style: base, children: [
                  TextSpan(text: sub.substring(0, at)),
                  TextSpan(
                    text: widget.email,
                    style: const TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: sub.substring(at + widget.email.length)),
                ]),
                textAlign: TextAlign.center,
              ),
      ),
      const SizedBox(height: 22),
      FadeSlideIn(
        delay: stagger(2),
        child: _Shake(
          trigger: _error,
          child: GestureDetector(
            onTap: () => _focus.requestFocus(),
            child: Stack(alignment: Alignment.center, children: [
              Opacity(
                opacity: 0,
                child: TextField(
                  controller: _code,
                  focusNode: _focus,
                  autofocus: true,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_len)],
                  onSubmitted: (_) => _verify(),
                ),
              ),
              OtpCodeBoxes(
                code: _code.text,
                count: _len,
                hasFocus: _focus.hasFocus,
                error: _error != null,
                label: l10n.codeLabel,
              ),
            ]),
          ),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: _error == null
            ? const SizedBox(height: 8)
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!,
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
              ),
      ),
      const SizedBox(height: 14),
      FadeSlideIn(
        delay: stagger(3),
        child: _GradientButton(
          label: l10n.verifyButton,
          icon: Icons.verified_user_rounded,
          busy: _busy,
          onPressed: len == _len ? _verify : null,
        ),
      ),
      const SizedBox(height: 10),
      FadeSlideIn(
        delay: stagger(4),
        child: Center(
          child: TextButton.icon(
            onPressed: _cooldown > 0 ? null : _resend,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(_cooldown > 0 ? l10n.codeResendIn(_cooldown) : l10n.codeResend),
            style: TextButton.styleFrom(foregroundColor: AppColors.teal),
          ),
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset('assets/images/app_icon.png', width: 16, height: 16),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text('${l10n.verifyFrom} ${l10n.codeSpamHint}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        ),
      ]),
      const SizedBox(height: 6),
      TextButton(
        onPressed: _restart,
        child: Text(l10n.verifyWrongEmail, style: const TextStyle(color: AppColors.mutedText, fontSize: 12.5)),
      ),
    ]);
  }

  Widget _success(AppLocalizations l10n) {
    return Column(key: const ValueKey('done'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Steps(current: 2, l10n: l10n),
      const SizedBox(height: 22),
      Text(l10n.verifySuccessTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
      const SizedBox(height: 8),
      Text(l10n.verifySuccessBody,
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.mutedText, height: 1.5)),
      const SizedBox(height: 22),
      const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.teal),
        ),
      ),
    ]);
  }
}

/// Gradient envelope badge with the app logo; it gently floats, and turns into a
/// check mark once the code is accepted.
class _MailBadge extends StatefulWidget {
  final bool done;
  const _MailBadge({required this.done});

  @override
  State<_MailBadge> createState() => _MailBadgeState();
}

class _MailBadgeState extends State<_MailBadge> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
    ..forward();

  @override
  void dispose() {
    _loop.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 136,
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _enter]),
        builder: (context, _) {
          final t = _loop.value;
          final pop = Curves.elasticOut.transform(_enter.value.clamp(0, 1));
          final dy = math.sin(t * 2 * math.pi) * 4;
          return Stack(alignment: Alignment.center, children: [
            // Two expanding rings, like a signal going out.
            for (final offset in [0.0, 0.5])
              Builder(builder: (_) {
                final p = (t + offset) % 1;
                return Opacity(
                  opacity: (1 - p) * 0.35,
                  child: Container(
                    width: 92 + p * 54,
                    height: 92 + p * 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.teal, width: 2),
                    ),
                  ),
                );
              }),
            Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: pop,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF142B4A), Color(0xFF1E3F6F), AppColors.teal],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Icon(
                      widget.done ? Icons.check_rounded : Icons.mark_email_unread_rounded,
                      key: ValueKey(widget.done),
                      color: Colors.white,
                      size: widget.done ? 50 : 42,
                    ),
                  ),
                ),
              ),
            ),
            // App logo tucked on the badge.
            Positioned(
              right: 22,
              bottom: 14 - dy,
              child: Transform.scale(
                scale: pop,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AppColors.deepNavy.withValues(alpha: 0.18), blurRadius: 10)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset('assets/images/app_icon.png', width: 34, height: 34, fit: BoxFit.cover),
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

/// Account → Verify → Plan progress.
class _Steps extends StatelessWidget {
  final int current; // 0-based index of the active step
  final AppLocalizations l10n;
  const _Steps({required this.current, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final labels = [l10n.verifyStepAccount, l10n.verifyStepVerify, l10n.verifyStepPlan];
    Widget dot(int i) {
      final done = i < current;
      final active = i == current;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: (done || active) ? const LinearGradient(colors: [AppColors.teal, Color(0xFF12B8A6)]) : null,
            color: (done || active) ? null : AppColors.lightBg,
            border: Border.all(color: (done || active) ? Colors.transparent : AppColors.cardBorder),
            boxShadow: active
                ? [BoxShadow(color: AppColors.teal.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
                : null,
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
              : Text('${i + 1}',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.mutedText)),
        ),
        const SizedBox(height: 4),
        Text(labels[i],
            style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? AppColors.deepNavy : AppColors.mutedText)),
      ]);
    }

    Widget line(int i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: i < current ? 1 : 0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 3,
                  backgroundColor: AppColors.cardBorder,
                  color: AppColors.teal,
                ),
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        dot(0),
        line(0),
        dot(1),
        line(1),
        dot(2),
      ]),
    );
  }
}

/// Brand gradient call-to-action.
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onPressed;
  const _GradientButton({required this.label, required this.icon, required this.busy, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || busy ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFF142B4A), AppColors.teal]),
          boxShadow: enabled
              ? [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 54,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(label,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Icon(icon, color: Colors.white, size: 19),
                      ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shakes its child horizontally whenever [trigger] changes to a non-null value (wrong code).
class _Shake extends StatefulWidget {
  final Object? trigger;
  final Widget child;
  const _Shake({required this.trigger, required this.child});

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void didUpdateWidget(covariant _Shake old) {
    super.didUpdateWidget(old);
    if (widget.trigger != null && widget.trigger != old.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(
          offset: Offset(math.sin(_c.value * math.pi * 6) * 10 * (1 - _c.value), 0),
          child: child,
        ),
        child: widget.child,
      );
}
