import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/auth_layout.dart';
import '../../../shared/widgets/google_auth_button.dart';
import '../../../shared/widgets/animations.dart';
import '../../../core/services/session_prefs.dart';
import '../providers/auth_provider.dart';
import 'login_welcome_splash.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _remember = true;
  String? _greetName; // set after a correct sign-in: plays the greeting here

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // Keep the router on /login while the greeting plays (set before signing in,
    // because the auth change triggers the redirect right away).
    loginGreetingActive.value = true;
    var greeting = false;
    try {
      await setRememberSession(_remember);
      await ref.read(authServiceProvider).signIn(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
      if (mounted) {
        final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
        final firstName = (meta?['first_name'] as String? ?? '').trim().split(' ').first;
        FocusScope.of(context).unfocus();
        greeting = true;
        setState(() => _greetName = firstName);
      }
    } on AuthException catch (e) {
      if (e.code == 'email_not_confirmed' || e.message.toLowerCase().contains('not confirmed')) {
        final email = Uri.encodeComponent(_emailCtrl.text.trim().toLowerCase());
        if (mounted) context.go('/verify-email?email=$email&resend=1');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (!greeting) loginGreetingActive.value = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  void _greetingDone() {
    loginGreetingActive.value = false;
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(children: [
      AuthLayout(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                delay: stagger(1),
                child: Column(
                  children: [
                    Text(l10n.signIn, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 6),
                    Text(l10n.signInSubtitle,
                        textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.emailRequired;
                  if (!v.contains('@')) return l10n.emailInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? l10n.passwordRequired : null,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Checkbox(
                      value: _remember,
                      activeColor: AppColors.teal,
                      onChanged: (v) => setState(() => _remember = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _remember = !_remember),
                      child: Text(l10n.rememberMe,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.mutedText)),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push('/forgot-password?email=${Uri.encodeComponent(_emailCtrl.text.trim())}'),
                    child: Text(l10n.forgotPassword,
                        style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loading ? null : () => _submit(l10n),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Text(l10n.login),
                ),
              ),
              const GoogleAuthSection(),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.dontHaveAccount, style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                    child:
                        Text(l10n.register, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (_greetName != null) LoginWelcomeOverlay(firstName: _greetName!, onDone: _greetingDone),
    ]);
  }
}
