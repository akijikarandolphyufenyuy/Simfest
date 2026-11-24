import 'package:supabase_flutter/supabase_flutter.dart';

/// Sign-up e-mail verification with a 6-digit code, sent by the `agreement-emails`
/// Edge Function (actions verify_send / verify_check). Used when the account is
/// already signed in (Supabase "Confirm email" is off).
SupabaseClient get _client => Supabase.instance.client;

/// Error from the verification function: INVALID_CODE, EXPIRED, TOO_MANY_ATTEMPTS,
/// TOO_SOON, EMAIL_NOT_CONFIGURED, SEND_FAILED…
class VerificationError implements Exception {
  final String code;
  const VerificationError(this.code);
  @override
  String toString() => code;
}

Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
  try {
    final res = await _client.functions.invoke('agreement-emails', body: body);
    return (res.data as Map).cast<String, dynamic>();
  } on FunctionException catch (e) {
    final d = e.details;
    throw VerificationError(d is Map && d['error'] != null ? '${d['error']}' : 'FAILED');
  }
}

/// Whether the signed-in user's e-mail is verified (true when signed out or on error,
/// so a network problem never locks anyone out).
Future<bool> isEmailVerified() async {
  final user = _client.auth.currentUser;
  if (user == null) return true;
  try {
    final row = await _client.from('profiles').select('email_verified_at').eq('id', user.id).maybeSingle();
    if (row == null) return false;
    return row['email_verified_at'] != null;
  } catch (_) {
    return true;
  }
}

/// E-mails a new code. Returns true when the address turned out to be verified already
/// (e.g. Google sign-in), in which case no code is sent.
Future<bool> sendVerificationCode() async {
  final r = await _call({'action': 'verify_send'});
  return r['verified'] == true;
}

/// Checks the code; throws [VerificationError] when it is wrong or expired.
Future<void> checkVerificationCode(String code) async {
  await _call({'action': 'verify_check', 'code': code});
}
