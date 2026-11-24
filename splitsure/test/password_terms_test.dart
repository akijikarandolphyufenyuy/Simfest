import 'package:flutter_test/flutter_test.dart';
import 'package:splitsure/features/auth/services/password_recovery.dart';
import 'package:splitsure/features/legal/terms_content.dart';

void main() {
  test('password strength: weak / fair / strong', () {
    expect(passwordStrength('abc'), 0); // too short
    expect(passwordStrength('abcdefgh'), 0);
    expect(passwordStrength('abcdefgh12'), 0);
    expect(passwordStrength('Abcdefgh12'), 1);
    expect(passwordStrength('Abcdefgh12!x'), 2);
  });

  test('recovery flag starts off and can be finished', () {
    expect(passwordRecoveryPending.value, isFalse);
    passwordRecoveryPending.value = true;
    finishPasswordRecovery();
    expect(passwordRecoveryPending.value, isFalse);
  });

  test('terms exist in English and French with matching sections', () {
    final en = termsFor('en');
    final fr = termsFor('fr');
    expect(en, isNotEmpty);
    expect(fr.length, en.length);
    for (var i = 0; i < en.length; i++) {
      expect(fr[i].paragraphs.length, en[i].paragraphs.length, reason: 'section ${i + 1}: ${en[i].title}');
      expect(en[i].paragraphs.every((p) => p.trim().isNotEmpty), isTrue);
    }
    // The plan rules stated in the terms match the app.
    final all = en.expand((s) => s.paragraphs).join(' ');
    expect(all, contains('100 FCFA'));
    expect(all, contains('50 FCFA'));
    expect(all, contains('MeSomb'));
    expect(termsFor('xx'), same(en)); // unknown language falls back to English
  });
}
