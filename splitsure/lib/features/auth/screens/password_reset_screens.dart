import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/auth_layout.dart';
import '../../../shared/widgets/floating_illustration.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../services/password_recovery.dart';

const _resetArt = 'assets/images/reset.png';
final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String _authMessage(AppLocalizations l10n, Object e) {
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (e.statusCode == '429' || m.contains('rate limit') || m.contains('security purposes')) {
      return l10n.tooManyRequests;
    }
    if (m.contains('expired') || m.contains('invalid') || m.contains('otp') || m.contains('token')) {
      return l10n.codeInvalid;
    }
    return e.message;
  }
  return friendlyError(e);
}

/// Title + subtitle. [highlight] (e.g. the email address) is shown bold in the subtitle.
Widget _title(String title, String subtitle, {int delay = 1, String? highlight}) {
  const base = TextStyle(fontSize: 13.5, color: AppColors.mutedText, height: 1.5);
  final at = highlight == null ? -1 : subtitle.indexOf(highlight);
  return FadeSlideIn(
    delay: stagger(delay),
    child: Column(children: [
      Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.deepNavy, height: 1.2)),
      const SizedBox(height: 8),
      if (at < 0)
        Text(subtitle, textAlign: TextAlign.center, style: base)
      else
        Text.rich(
          TextSpan(style: base, children: [
            TextSpan(text: subtitle.substring(0, at)),
            TextSpan(
              text: highlight,
              style: const TextStyle(color: AppColors.deepNavy, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: subtitle.substring(at + highlight!.length)),
          ]),
          textAlign: TextAlign.center,
        ),
    ]),
  );
}

Widget _primary({required String label, required bool busy, required VoidCallback? onPressed, IconData? icon}) =>
    ElevatedButton(
      onPressed: busy ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: busy
            ? const SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label),
                if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
              ]),
      ),
    );

// ─── 1. Email ────────────────────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await sendPasswordReset(_email.text, lang: Localizations.localeOf(context).languageCode);
      if (mounted) context.go('/forgot-password/code?email=${Uri.encodeComponent(_email.text.trim().toLowerCase())}');
    } catch (e) {
      if (mounted) showError(context, _authMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthLayout(
      onBack: () => context.go('/login'),
      header: const FloatingIllustration(asset: _resetArt, size: 150),
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _title(l10n.forgotTitle, l10n.forgotSubtitle),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: stagger(2),
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _send(),
              decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.email_outlined)),
              validator: (v) => _emailRe.hasMatch((v ?? '').trim()) ? null : l10n.emailInvalid,
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideIn(
            delay: stagger(3),
            child: _primary(label: l10n.forgotSend, busy: _busy, onPressed: _send, icon: Icons.send_rounded),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: stagger(4),
            child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(l10n.forgotRemembered, style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.signIn, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── 2. Code ─────────────────────────────────────────────────────────────────

class ResetCodeScreen extends StatefulWidget {
  final String email;
  const ResetCodeScreen({super.key, required this.email});

  @override
  State<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  String? _error;
  int _cooldown = 60;
  Timer? _timer;

  static const _minLen = 6;
  static const _maxLen = 8; // Supabase codes are 6 digits by default (configurable up to 8+).

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _code.addListener(() => setState(() => _error = null));
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

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    if (_code.text.length < _minLen) {
      setState(() => _error = l10n.codeInvalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await verifyResetCode(widget.email, _code.text);
      if (mounted) context.go('/new-password');
    } catch (e) {
      if (mounted) setState(() => _error = _authMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await sendPasswordReset(widget.email, lang: Localizations.localeOf(context).languageCode);
      _startCooldown();
      if (mounted) showSuccess(context, l10n.codeSent);
    } catch (e) {
      if (mounted) showError(context, _authMessage(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final len = _code.text.length;
    final boxes = len >= _minLen ? (len < _maxLen ? len + 1 : _maxLen) : _minLen;
    return AuthLayout(
      onBack: () => context.go('/forgot-password?email=${Uri.encodeComponent(widget.email)}'),
      header: const FloatingIllustration(asset: _resetArt, size: 130),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(l10n.codeTitle, l10n.codeSubtitle(widget.email), highlight: widget.email),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: stagger(2),
          child: GestureDetector(
            onTap: () => _focus.requestFocus(),
            child: Stack(alignment: Alignment.center, children: [
              // The real (invisible) input: digits only, supports paste and autofill.
              Opacity(
                opacity: 0,
                child: TextField(
                  controller: _code,
                  focusNode: _focus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_maxLen)],
                  onSubmitted: (_) => _verify(),
                ),
              ),
              OtpCodeBoxes(
                code: _code.text,
                count: boxes,
                hasFocus: _focus.hasFocus,
                error: _error != null,
                label: l10n.codeLabel,
              ),
            ]),
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
          child: _primary(
              label: l10n.codeVerify,
              busy: _busy,
              onPressed: len >= _minLen ? _verify : null,
              icon: Icons.verified_user_rounded),
        ),
        const SizedBox(height: 10),
        FadeSlideIn(
          delay: stagger(4),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton.icon(
              onPressed: _cooldown > 0 ? null : _resend,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(_cooldown > 0 ? l10n.codeResendIn(_cooldown) : l10n.codeResend),
              style: TextButton.styleFrom(foregroundColor: AppColors.teal),
            ),
          ]),
        ),
        Text(l10n.codeSpamHint,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => context.go('/forgot-password'),
          child: Text(l10n.codeChangeEmail, style: const TextStyle(color: AppColors.mutedText, fontSize: 12.5)),
        ),
      ]),
    );
  }
}

/// Row of code boxes drawn over an invisible TextField (used for reset and sign-up codes).
class OtpCodeBoxes extends StatelessWidget {
  final String code;
  final int count;
  final bool hasFocus;
  final bool error;
  final String label;
  const OtpCodeBoxes(
      {super.key,
      required this.code,
      required this.count,
      required this.hasFocus,
      required this.error,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: code,
      child: LayoutBuilder(builder: (context, c) {
        const gap = 8.0;
        final size = ((c.maxWidth - gap * (count - 1)) / count).clamp(34.0, 52.0);
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: size,
              height: size * 1.18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < code.length ? AppColors.teal.withValues(alpha: 0.08) : AppColors.lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: (hasFocus && i == code.length) ? 2 : 1.2,
                  color: error
                      ? AppColors.error
                      : (hasFocus && i == code.length)
                          ? AppColors.teal
                          : i < code.length
                              ? AppColors.teal.withValues(alpha: 0.5)
                              : AppColors.cardBorder,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: Text(
                  i < code.length ? code[i] : '',
                  key: ValueKey('$i-${i < code.length ? code[i] : ''}'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
                ),
              ),
            ),
          ],
        ]);
      }),
    );
  }
}

// ─── 3. New password ─────────────────────────────────────────────────────────

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _busy = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _pass.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await setNewPassword(_pass.text);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) showError(context, _authMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _continue() {
    finishPasswordRecovery();
    context.go('/home');
  }

  Future<void> _cancel() async {
    finishPasswordRecovery();
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthLayout(
      onBack: _done ? _continue : _cancel,
      // The success view has its own check-mark badge, so no second hero graphic.
      header: _done ? const SizedBox.shrink() : const FloatingIllustration(asset: _resetArt, size: 130),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: child),
        ),
        child: _done ? _success(l10n) : _formView(l10n),
      ),
    );
  }

  Widget _formView(AppLocalizations l10n) {
    final strength = passwordStrength(_pass.text);
    final colors = [AppColors.error, Colors.orange, AppColors.success];
    final labels = [l10n.passWeak, l10n.passFair, l10n.passStrong];
    return Form(
      key: _form,
      child: Column(key: const ValueKey('form'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _title(l10n.newPassTitle, l10n.newPassSubtitle),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: stagger(2),
          child: TextFormField(
            controller: _pass,
            obscureText: !_show,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: l10n.newPassLabel,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _show = !_show),
              ),
            ),
            validator: (v) => (v ?? '').length < 8 ? l10n.passTooShort : null,
          ),
        ),
        if (_pass.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= strength ? colors[strength] : AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          Text(l10n.passStrength(labels[strength]),
              style: TextStyle(fontSize: 11.5, color: colors[strength], fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: stagger(3),
          child: TextFormField(
            controller: _confirm,
            obscureText: !_show,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _save(),
            decoration:
                InputDecoration(labelText: l10n.newPassConfirm, prefixIcon: const Icon(Icons.lock_reset_rounded)),
            validator: (v) => v != _pass.text ? l10n.passMismatch : null,
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: stagger(4),
          child: _primary(label: l10n.newPassSave, busy: _busy, onPressed: _save, icon: Icons.check_rounded),
        ),
      ]),
    );
  }

  Widget _success(AppLocalizations l10n) {
    return Column(key: const ValueKey('done'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.teal, Color(0xFF12B8A6)]),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.white, size: 42),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _title(l10n.passwordUpdatedTitle, l10n.passwordUpdatedBody, delay: 0),
      const SizedBox(height: 24),
      _primary(label: l10n.continueToApp, busy: false, onPressed: _continue, icon: Icons.arrow_forward_rounded),
    ]);
  }
}
