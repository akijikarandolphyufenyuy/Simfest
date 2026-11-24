import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in user's id, updated on sign-in / sign-out.
///
/// Every provider that loads the current user's data watches this, so signing
/// out and into another account in the same tab never shows stale data from the
/// previous account. Token refreshes don't change the id and cause no reloads.
final currentUserIdProvider = NotifierProvider<_CurrentUserId, String?>(_CurrentUserId.new);

class _CurrentUserId extends Notifier<String?> {
  @override
  String? build() {
    final auth = Supabase.instance.client.auth;
    final sub = auth.onAuthStateChange.listen((s) {
      final id = s.session?.user.id;
      if (id != state) state = id;
    });
    ref.onDispose(sub.cancel);
    return auth.currentUser?.id;
  }
}
