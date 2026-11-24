import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:web/web.dart' as web;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/services/password_recovery.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/localization/locale_provider.dart';
import 'core/localization/l10n/app_localizations.dart';
import 'core/services/fcm_service.dart';
import 'core/services/session_prefs.dart';

/// Links shared before the switch to path URLs look like /#/approve/<token>,
/// /#/invite/<token> or /#/passport/<slug>. Turn them into /approve/<token>
/// before the router starts, so e-mails already sent keep working.
/// (Auth redirects such as #access_token=… are left alone.)
void _upgradeLegacyHashLink() {
  final hash = web.window.location.hash;
  if (!hash.startsWith('#/')) return;
  web.window.history.replaceState(null, '', hash.substring(1));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _upgradeLegacyHashLink();
  usePathUrlStrategy();

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  // Opening the password-reset link from the email: make the user choose a new password.
  Supabase.instance.client.auth.onAuthStateChange.listen((s) {
    if (s.event == AuthChangeEvent.passwordRecovery) passwordRecoveryPending.value = true;
  });
  await enforceRememberSession();
  await loadPendingReturn();

  // Firebase init — catches errors gracefully if config is not yet set up
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAxKZsZi5f4tq_urvEN9PcL__2FoX_8OjY',
        appId: '1:130930853529:web:5fbc4e88ce5e065a069a08',
        messagingSenderId: '130930853529',
        projectId: 'splitsure-e31bd',
        storageBucket: 'splitsure-e31bd.firebasestorage.app',
        authDomain: 'splitsure-e31bd.firebaseapp.com',
        measurementId: 'G-2FL6F3QNR0',
      ),
    );

    // Init FCM only if user is already signed in (e.g. returning user)
    if (Supabase.instance.client.auth.currentUser != null) {
      await FcmService.init();
    }

    // Also init FCM on sign-in
    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn) {
        await FcmService.init();
      }
    });
  } catch (e) {
    debugPrint('[Firebase] Init skipped: $e');
  }

  // context.push() also updates the URL, so the browser/phone back button returns to the
  // previous screen (e.g. Terms → the sign-up form) instead of leaving it.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(const ProviderScope(child: SplitSureApp()));
}

class SplitSureApp extends ConsumerWidget {
  const SplitSureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'SplitSure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
