import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsure/core/localization/l10n/app_localizations.dart';
import 'package:splitsure/features/subscription/models/subscription.dart';
import 'package:splitsure/features/subscription/services/receipt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('formatFcfa groups thousands with plain spaces', () {
    expect(formatFcfa(100), '100');
    expect(formatFcfa(1000), '1 000');
    expect(formatFcfa(2500000), '2 500 000');
  });

  test('formatPhone shows Cameroon numbers readably', () {
    expect(formatPhone('237677123456'), '+237 677 12 34 56');
    expect(formatPhone('677123456'), '+237 677 12 34 56');
    expect(formatPhone('+44 20 1234'), '+44 20 1234');
  });

  for (final code in ['en', 'fr']) {
    test('builds a $code receipt PDF', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(code));
      final tx = PaymentTransaction.fromJson({
        'id': '1',
        'reference': 'SS-PRO-20261123-8F2K1Q',
        'type': 'PRO_UPGRADE',
        'amount_fcfa': 100,
        'provider': 'MTN',
        'phone': '237677123456',
        'status': 'success',
        'provider_tx_id': '4f6c1d2e-7a1b',
        'created_at': '2026-11-23T18:42:00Z',
        'completed_at': '2026-11-23T18:43:10Z',
      });
      final bytes = await buildReceiptPdf(tx, const ReceiptHolder(name: 'Randolph Yufenyuy', isPro: true), l10n);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      // Optional: write it out for a visual check (RECEIPT_OUT=<dir>).
      final out = Platform.environment['RECEIPT_OUT'];
      if (out != null) File('$out/receipt_$code.pdf').writeAsBytesSync(bytes);
    });
  }
}
