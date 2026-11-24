import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsure/core/localization/l10n/app_localizations.dart';
import 'package:splitsure/core/localization/l10n_helpers.dart';
import 'package:splitsure/features/subscription/models/subscription.dart';

void main() {
  group('Entitlement', () {
    test('defaults to Free', () {
      expect(Entitlement.free.isPro, isFalse);
      expect(Entitlement.free.planId, 'free');
      expect(Entitlement.free.hasChosenPlan, isFalse);
    });

    test('active Pro without expiry is Pro', () {
      final e = Entitlement.fromJson({'plan_type': 'pro', 'subscription_status': 'active'});
      expect(e.isPro, isTrue);
      expect(e.planId, 'pro');
      expect(e.hasChosenPlan, isTrue);
    });

    test('expired or inactive Pro falls back to Free', () {
      final past = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      expect(Entitlement.fromJson({'plan_type': 'pro', 'pro_expires_at': past}).isPro, isFalse);
      expect(Entitlement.fromJson({'plan_type': 'pro', 'subscription_status': 'expired'}).isPro, isFalse);
    });

    test('plan choice is remembered for Free users', () {
      final e = Entitlement.fromJson({'plan_type': 'free', 'plan_chosen_at': '2026-11-23T10:00:00Z'});
      expect(e.hasChosenPlan, isTrue);
      expect(e.isPro, isFalse);
    });
  });

  group('helpers', () {
    test('formatDate', () {
      expect(formatDate(DateTime(2026, 3, 7)), '07/03/2026');
      expect(formatDate('2026-11-23'), '23/11/2026');
      expect(formatDate('not a date'), '');
      expect(formatDate(null), '');
    });

    test('capitalizeName', () {
      expect(capitalizeName('randolph'), 'Randolph');
      expect(capitalizeName('McKay'), 'McKay');
      expect(capitalizeName(''), '');
    });
  });

  group('localization', () {
    for (final code in ['en', 'fr']) {
      test('$code labels resolve for every stored value', () async {
        final l10n = await AppLocalizations.delegate.load(Locale(code));
        for (final c in kCountries) {
          expect(countryLabel(l10n, c), isNotEmpty);
        }
        for (final r in kMusicRoles) {
          expect(musicRoleLabel(l10n, r), isNotEmpty);
        }
        for (final s in ['draft', 'pending', 'accepted', 'changes_requested', 'declined']) {
          expect(agreementStatusLabel(l10n, s), isNot(s), reason: 'status "$s" is untranslated');
        }
        expect(planLabel(l10n, 'pro'), isNotEmpty);
        expect(planLabel(l10n, 'free'), isNotEmpty);
      });
    }
  });
}
