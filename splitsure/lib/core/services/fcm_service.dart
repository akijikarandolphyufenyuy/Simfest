import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _client = Supabase.instance.client;

  /// Call once after Firebase.initializeApp() and user is authenticated.
  static Future<void> init() async {
    // Request permission (web + iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Get token
    final token = kIsWeb
        ? await _messaging.getToken(
            vapidKey: 'BAVCRHpVskoP3gUPMFXMWbbbBXCh7nt4DB4XrBeHOGW-vCki8vdgTGZL5ZPnzpTd6XwrkWVAbD806uzvdb6MRCI',
          )
        : await _messaging.getToken();

    if (token != null) await _saveToken(token);

    // Handle token refresh
    _messaging.onTokenRefresh.listen(_saveToken);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      // The notifications screen auto-refreshes via Riverpod invalidation.
      // For a richer UX, show an in-app snackbar here if needed.
    });
  }

  static Future<void> _saveToken(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('fcm_tokens').upsert(
      {
        'user_id': user.id,
        'token': token,
        'platform': kIsWeb ? 'web' : 'mobile',
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'token',
    );
  }
}
