import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/login_welcome_splash.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/protect/screens/invite_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../features/passport/screens/public_passport_screen.dart';
import '../../features/hub/screens/opportunity_detail_screen.dart';
import '../../features/auth/screens/password_reset_screens.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/subscription/screens/plan_selection_screen.dart';
import '../../features/auth/services/password_recovery.dart';
import '../../features/legal/terms_screen.dart';
import '../../features/legal/about_screen.dart';
import '../../features/protect/screens/approve_screen.dart';
import '../services/session_prefs.dart';

/// Deep link to reopen after sign-in (see redirect). Persisted, so it survives the
/// page reloads of Google sign-in and e-mail links.
String? get _returnTo => pendingReturnPath;

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier();

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: Listenable.merge([notifier, passwordRecoveryPending]),
    // Unknown links land on the start page (which forwards signed-in users home).
    onException: (_, __, router) => router.go('/welcome'),
    redirect: (context, state) {
      final isAuth = Supabase.instance.client.auth.currentUser != null;
      final loc = state.matchedLocation;
      final onAuthRoute = loc == '/login' || loc == '/register';
      final onIntro = loc == '/welcome' || loc == '/onboarding';
      final isProtected = loc == '/home' || loc == '/choose-plan' || loc.startsWith('/opportunity/');
      final onForgot = loc.startsWith('/forgot-password');

      // Password recovery: a signed-in user who came from the reset code or the reset
      // link must choose a new password before going anywhere else.
      if (loc == '/new-password') return isAuth ? null : '/login';
      if (isAuth && passwordRecoveryPending.value) return '/new-password';
      if (isAuth && onForgot) return '/home';

      // Signed-out visitors of a protected deep link (e.g. a shared opportunity)
      // are sent to sign in, then brought back to that link.
      if (!isAuth && isProtected) {
        if (loc != '/home' && loc != '/choose-plan') rememberReturnPath(state.uri.toString());
        return '/login';
      }
      // The login screen is playing its welcome greeting; it goes home itself.
      if (isAuth && loc == '/login' && loginGreetingActive.value) return null;
      if (isAuth && _returnTo != null) {
        if (state.uri.toString() == _returnTo) {
          clearPendingReturn(); // arrived
          return null;
        }
        if (onAuthRoute || onIntro || loc == '/home') return _returnTo;
      }
      if (isAuth && (onAuthRoute || onIntro)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const MainShell()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, state) => ForgotPasswordScreen(initialEmail: state.uri.queryParameters['email']),
        routes: [
          GoRoute(
            path: 'code',
            redirect: (_, state) => (state.uri.queryParameters['email'] ?? '').isEmpty ? '/forgot-password' : null,
            builder: (_, state) => ResetCodeScreen(email: state.uri.queryParameters['email']!),
          ),
        ],
      ),
      GoRoute(path: '/new-password', builder: (_, __) => const NewPasswordScreen()),
      GoRoute(
        path: '/terms',
        builder: (_, state) => TermsScreen(acceptMode: state.uri.queryParameters['accept'] == '1'),
      ),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      // Sign-up step 2: enter the 6-digit code from the confirmation e-mail.
      GoRoute(
        path: '/verify-email',
        redirect: (_, state) => (state.uri.queryParameters['email'] ?? '').isEmpty ? '/register' : null,
        builder: (_, state) => VerifyEmailScreen(
          email: state.uri.queryParameters['email']!,
          resendOnOpen: state.uri.queryParameters['resend'] == '1',
        ),
      ),
      // Sign-up step 3: choose Basic or Pro, then the dashboard.
      GoRoute(path: '/choose-plan', builder: (_, __) => const PlanSelectionScreen()),
      GoRoute(
        path: '/passport/:slug',
        builder: (_, state) => PublicPassportScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/opportunity/:id',
        builder: (_, state) => OpportunityDetailScreen(opportunityId: state.pathParameters['id']!),
      ),
      // One-tap approval from the invitation e-mail (works signed out).
      GoRoute(path: '/approve/:token', builder: (_, state) => ApproveScreen(
            token: state.pathParameters['token']!, decline: state.uri.queryParameters['decline'] == '1')),
      GoRoute(
        path: '/invite/:token',
        builder: (_, state) => InviteScreen(token: state.pathParameters['token']!),
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthChangeNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((s) {
      // Opening the reset link from the email signs the user in with this event.
      if (s.event == AuthChangeEvent.passwordRecovery) passwordRecoveryPending.value = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
