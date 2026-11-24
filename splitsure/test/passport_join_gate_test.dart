import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsure/core/localization/l10n/app_localizations.dart';
import 'package:splitsure/features/passport/models/passport.dart';
import 'package:splitsure/features/passport/widgets/passport_join_gate.dart';

/// The "join to view" gate for shared passport links lays out on phone and desktop.
void main() {
  final passport = MusicPassport.fromJson({
    'user_id': 'u1',
    'slug': 'randolph',
    'stage_name': 'Randolph',
    'primary_role': 'producer',
    'city': 'Douala',
    'country': 'Cameroon',
  });

  for (final width in const [375.0, 1280.0]) {
    for (final locale in const [Locale('en'), Locale('fr')]) {
      testWidgets('gate at ${width.toInt()} px (${locale.languageCode})', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PassportJoinGate(passport: passport),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Randolph'), findsWidgets);
      });
    }
  }

  testWidgets('gate without passport data (not found) still renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PassportJoinGate(passport: null),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
