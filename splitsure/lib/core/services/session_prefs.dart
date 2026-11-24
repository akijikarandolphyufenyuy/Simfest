import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

/// "Remember me" support.
///
/// Supabase always persists the session in local storage. When the user signs in
/// with "Remember me" turned off we mark the current browser session; on the next
/// app start without that marker (i.e. after the browser/tab was closed) we sign out.
const _rememberKey = 'remember_session';
const _activeKey = 'ss_session_active';

Future<void> setRememberSession(bool remember) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_rememberKey, remember);
  try {
    web.window.sessionStorage.setItem(_activeKey, '1');
  } catch (_) {}
}

/// Call once at startup, after Supabase is initialised.
Future<void> enforceRememberSession() async {
  final client = Supabase.instance.client;
  if (client.auth.currentSession == null) return;
  final prefs = await SharedPreferences.getInstance();
  final remember = prefs.getBool(_rememberKey) ?? true;
  if (remember) return;
  String? active;
  try {
    active = web.window.sessionStorage.getItem(_activeKey);
  } catch (_) {}
  if (active == null) await client.auth.signOut();
}

// ── Pending agreement invitation (survives sign-up / sign-in) ───────────────
const _inviteKey = 'pending_invite_token';

Future<void> savePendingInvite(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_inviteKey, token);
}

/// Returns and clears the stored invitation token, if any.
Future<String?> takePendingInvite() async {
  final prefs = await SharedPreferences.getInstance();
  final t = prefs.getString(_inviteKey);
  if (t != null) await prefs.remove(_inviteKey);
  return t;
}

// ── Deep link to reopen after sign-up / sign-in (e.g. a shared Music Passport) ──
// Kept in memory for the router (its redirect is synchronous) and in storage so it
// survives page reloads during sign-in (Google OAuth, e-mail links).
const _returnKey = 'pending_return_path';
String? _pendingReturn;

/// The path to open once the user is signed in, if any.
String? get pendingReturnPath => _pendingReturn;

/// Call once at startup, before the router is built.
Future<void> loadPendingReturn() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    _pendingReturn = prefs.getString(_returnKey);
  } catch (_) {}
}

void rememberReturnPath(String path) {
  _pendingReturn = path;
  SharedPreferences.getInstance().then((p) => p.setString(_returnKey, path)).catchError((_) => false);
}

void clearPendingReturn() {
  _pendingReturn = null;
  SharedPreferences.getInstance().then((p) => p.remove(_returnKey)).catchError((_) => false);
}
