import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Returns true when the user is signed in straight away (email confirmation
  /// disabled); false when Supabase sent a confirmation email first.
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String country,
    required String preferredLanguage,
  }) async {
    String? orNull(String s) => s.trim().isEmpty ? null : s.trim();
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        // profiles.username is UNIQUE: send null, never '', when left blank.
        'username': orNull(username),
        'phone': orNull(phone),
        'country': country,
        'preferred_language': preferredLanguage,
      },
    );
    return res.session != null;
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
