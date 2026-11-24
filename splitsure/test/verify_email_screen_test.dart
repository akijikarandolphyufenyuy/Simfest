import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsure/core/localization/l10n/app_localizations.dart';
import 'package:splitsure/features/auth/screens/verify_email_screen.dart';

/// The sign-up verification screen lays out without errors on a phone and a desktop,
/// in English and French, and shows the e-mail it was sent to.
void main() {
  for (final width in const [375.0, 1280.0]) {
    for (final locale in const [Locale('en'), Locale('fr')]) {
      testWidgets('renders at ${width.toInt()} px (${locale.languageCode})', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const VerifyEmailScreen(email: 'artist@example.com'),
          ),
        ));
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(find.textContaining('artist@example.com', findRichText: true), findsOneWidget);
        // Leave no timers running.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 61));
      });
    }
  }
}
