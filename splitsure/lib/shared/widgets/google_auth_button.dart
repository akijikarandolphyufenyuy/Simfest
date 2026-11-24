import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/localization/l10n/app_localizations.dart';
import '../../core/services/session_prefs.dart';
import '../../core/theme/app_theme.dart';
import 'form_widgets.dart';

/// Official multicolour Google "G".
const _googleG = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>
<path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>
<path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238C29.211 35.091 26.715 36 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>
<path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303c-.792 2.237-2.231 4.166-4.087 5.571l.003-.002 6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.389-3.917z"/>
</svg>''';

/// Starts "Continue with Google" through Supabase Auth.
///
/// On the web the browser goes to Google and comes back to this site with a
/// one-time code; supabase_flutter exchanges it for a session and the router
/// then opens Home (new accounts get the plan-selection step there).
/// Returns false (after showing a message) when Google sign-in isn't enabled.
Future<bool> signInWithGoogle(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    // Avoid sending people to an error page when the provider is switched off.
    final res = await http.get(Uri.parse('$supabaseUrl/auth/v1/settings'), headers: {'apikey': supabaseAnonKey});
    final enabled = (jsonDecode(res.body)['external'] as Map?)?['google'] == true;
    if (!enabled) {
      if (context.mounted) showError(context, l10n.googleSignInUnavailable);
      return false;
    }
    await setRememberSession(true);
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      // Trailing slash so it matches the "https://site/**" entries in Supabase's redirect allow list;
      // without a match Supabase falls back to the Site URL and the sign-in can't complete.
      redirectTo: kIsWeb ? '${Uri.base.origin}/' : null,
      queryParams: const {'prompt': 'select_account'},
    );
    return true;
  } catch (e) {
    if (context.mounted) showError(context, l10n.googleSignInFailed(friendlyError(e)));
    return false;
  }
}

/// "or" divider + "Continue with Google" button, shown below the auth forms.
class GoogleAuthSection extends StatefulWidget {
  /// Checked before starting (e.g. the sign-up page requires accepted terms).
  final bool Function()? canStart;

  /// Button text; defaults to "Continue with Google".
  final String? label;
  const GoogleAuthSection({super.key, this.canStart, this.label});

  @override
  State<GoogleAuthSection> createState() => _GoogleAuthSectionState();
}

class _GoogleAuthSectionState extends State<GoogleAuthSection> {
  bool _busy = false;

  Future<void> _go() async {
    if (widget.canStart != null && !widget.canStart!()) return;
    setState(() => _busy = true);
    final started = await signInWithGoogle(context);
    // On success the page navigates away to Google; keep the spinner until then.
    if (!started && mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 18),
      Row(children: [
        const Expanded(child: Divider(color: AppColors.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(l10n.orDivider, style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
        ),
        const Expanded(child: Divider(color: AppColors.cardBorder)),
      ]),
      const SizedBox(height: 18),
      OutlinedButton(
        onPressed: _busy ? null : _go,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.deepNavy,
          side: const BorderSide(color: AppColors.cardBorder, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                SvgPicture.string(_googleG, width: 20, height: 20),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(widget.label ?? l10n.continueWithGoogle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.deepNavy)),
                ),
              ]),
      ),
    ]);
  }
}
