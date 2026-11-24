import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// True while a signed-in user still has to choose a new password, either after
/// entering the reset code or after opening the reset link from the email.
/// The router sends them to the "new password" screen until it is cleared.
final passwordRecoveryPending = ValueNotifier<bool>(false);

SupabaseClient get _auth => Supabase.instance.client;

/// Where Supabase's reset link should bring the user back (this site).
String? get _redirect => kIsWeb ? '${Uri.base.origin}/' : null;

/// Sends the reset email (code + link) to [email].
///
/// SplitSure e-mails it through its own sender with the branded template (the
/// 'reset_send' action of the agreement-emails function); Supabase's default
/// mailer is only used if that is unavailable.
Future<void> sendPasswordReset(String email, {String? lang}) async {
  final e = email.trim().toLowerCase();
  try {
    await _auth.functions.invoke('agreement-emails', body: {'action': 'reset_send', 'email': e, if (lang != null) 'lang': lang});
  } on FunctionException catch (err) {
    final code = err.details is Map ? '${(err.details as Map)['error']}' : '';
    if (code == 'TOO_SOON') throw const AuthException('Too many requests', statusCode: '429');
    if (code == 'INVALID_EMAIL') rethrow;
    // Our sender is unavailable: fall back to Supabase's own e-mail.
    await _auth.auth.resetPasswordForEmail(e, redirectTo: _redirect);
  }
}

/// Checks the code from the email; on success the user is signed in and must set a new password.
Future<void> verifyResetCode(String email, String code) async {
  passwordRecoveryPending.value = true;
  try {
    await _auth.auth.verifyOTP(email: email.trim().toLowerCase(), token: code.trim(), type: OtpType.recovery);
  } catch (_) {
    passwordRecoveryPending.value = false;
    rethrow;
  }
}

/// Saves the new password and ends the recovery.
Future<void> setNewPassword(String password) async {
  await _auth.auth.updateUser(UserAttributes(password: password));
}

/// Called once the user leaves the "password updated" screen.
void finishPasswordRecovery() => passwordRecoveryPending.value = false;

/// 0 = weak, 1 = fair, 2 = strong.
int passwordStrength(String p) {
  var score = 0;
  if (p.length >= 8) score++;
  if (p.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
  if (RegExp(r'\d').hasMatch(p)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
  if (p.length < 8) return 0;
  return score >= 4 ? 2 : (score >= 3 ? 1 : 0);
}
