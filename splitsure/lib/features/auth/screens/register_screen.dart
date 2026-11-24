import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/auth_layout.dart';
import '../../../shared/widgets/google_auth_button.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/welcome_banner.dart';
import '../../../core/localization/locale_provider.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _loading = false;
  String _country = 'Cameroon';
  late String _language = ref.read(localeProvider).languageCode;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Opens the Terms; accepting there ticks the box.
  Future<void> _openTerms() async {
    // A real route (/terms?accept=1): the URL changes, and both the header's back arrow
    // and the browser/phone back button return here with the form untouched.
    final agreed = await context.push<bool>('/terms?accept=1');
    if (agreed == true && mounted) setState(() => _acceptedTerms = true);
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mustAcceptTerms)),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      // Apply the chosen language to the whole app right away.
      await ref.read(localeProvider.notifier).setLocale(Locale(_language));
      // Set before sign-up: if Supabase signs the user in directly, the router
      // redirects to /home immediately and the shell shows the welcome banner.
      ref.read(pendingWelcomeProvider.notifier).state = WelcomeKind.newAccount;
      final signedIn = await ref.read(authServiceProvider).signUp(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            firstName: _firstCtrl.text.trim(),
            lastName: _lastCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            country: _country,
            preferredLanguage: _language,
          );
      if (signedIn) {
        // Signed in straight away: confirm the address with SplitSure's own 6-digit code,
        // then choose a plan. (The welcome banner is queued again after verification.)
        ref.read(pendingWelcomeProvider.notifier).state = null;
        final email = Uri.encodeComponent(_emailCtrl.text.trim().toLowerCase());
        if (mounted) context.go('/verify-email?email=$email');
        return;
      }
      ref.read(pendingWelcomeProvider.notifier).state = null;
      // Step 2: the 6-digit code from the confirmation e-mail.
      final email = Uri.encodeComponent(_emailCtrl.text.trim().toLowerCase());
      if (mounted) context.go('/verify-email?email=$email');
    } on AuthException catch (e) {
      ref.read(pendingWelcomeProvider.notifier).state = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(
              delay: stagger(1),
              child: Column(
                children: [
                  Text(l10n.register, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 6),
                  Text(l10n.registerSubtitle,
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstCtrl,
                    decoration: InputDecoration(labelText: l10n.firstName),
                    validator: (v) => (v == null || v.isEmpty) ? l10n.firstNameRequired : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastCtrl,
                    decoration: InputDecoration(labelText: l10n.lastName),
                    validator: (v) => (v == null || v.isEmpty) ? l10n.lastNameRequired : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _usernameCtrl,
              decoration: InputDecoration(labelText: l10n.username),
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _country,
              decoration: InputDecoration(labelText: l10n.country),
              items: [
                for (final c in kCountries) DropdownMenuItem(value: c, child: Text(countryLabel(l10n, c))),
              ],
              onChanged: (v) => setState(() => _country = v ?? 'Cameroon'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: InputDecoration(
                labelText: l10n.preferredLanguage,
                prefixIcon: const Icon(Icons.language_outlined),
              ),
              items: [
                DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                DropdownMenuItem(value: 'fr', child: Text(l10n.french)),
              ],
              onChanged: (v) => setState(() => _language = v ?? 'en'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.passwordRequired;
                if (v.length < 8) return l10n.passwordTooShort;
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => (v != _passCtrl.text) ? l10n.passwordsDoNotMatch : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  activeColor: AppColors.teal,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text(
                      l10n.termsAccept,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                    ),
                    InkWell(
                      onTap: _openTerms,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          l10n.termsReadLink,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.teal,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                    : Text(l10n.register),
              ),
            ),
            GoogleAuthSection(
              label: l10n.signUpWithGoogle,
              canStart: () {
                if (_acceptedTerms) return true;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mustAcceptTerms)));
                return false;
              },
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.alreadyHaveAccount, style: Theme.of(context).textTheme.bodyMedium),
                TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                  child: Text(l10n.signIn, style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
