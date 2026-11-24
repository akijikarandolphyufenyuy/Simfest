import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsure/core/localization/l10n/app_localizations.dart';
import 'package:splitsure/features/subscription/models/subscription.dart';
import 'package:splitsure/features/subscription/screens/subscription_screen.dart';

/// Regression test: the plan cards used a Spacer that crashed ("RenderFlex children have
/// non-zero flex but incoming height constraints are unbounded") when stacked in a scroll view.
void main() {
  Future<void> pump(WidgetTester tester, double width, Locale locale) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [plansProvider.overrideWith((ref) async => kDefaultPlans)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: PlanOptionsRow(isPro: false, onFree: () {}, onPro: () {}),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  for (final locale in const [Locale('en'), Locale('fr')]) {
    testWidgets('stacked on a phone (${locale.languageCode})', (tester) async {
      await pump(tester, 375, locale);
      expect(tester.takeException(), isNull);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('side by side on a wide screen (${locale.languageCode})', (tester) async {
      await pump(tester, 1000, locale);
      expect(tester.takeException(), isNull);
      // Buttons are pinned to the same bottom line in both cards.
      final pro = tester.getBottomLeft(find.byType(FilledButton)).dy;
      final free = tester.getBottomLeft(find.byType(OutlinedButton)).dy;
      expect((pro - free).abs(), lessThanOrEqualTo(1)); // Pro card has a 2 px border vs 1 px
    });
  }

  testWidgets('Basic card states the 1-agreement limit', (tester) async {
    await pump(tester, 375, const Locale('en'));
    expect(find.text('1 agreement document'), findsOneWidget);
    expect(find.text('Unlimited agreements'), findsOneWidget);
  });
}
