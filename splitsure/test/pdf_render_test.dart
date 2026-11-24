import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsure/core/localization/l10n/app_localizations.dart';
import 'package:splitsure/core/services/pdf_brand.dart';
import 'package:splitsure/core/services/pdf_service.dart';
import 'package:splitsure/features/protect/models/agreement.dart';
import 'package:splitsure/features/subscription/models/subscription.dart';
import 'package:splitsure/features/subscription/services/receipt_service.dart';

/// Builds the agreement and receipt PDFs. Set PDF_OUT=<dir> to write them out for a visual check.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PdfBrand> brand() async =>
      PdfBrand.load(logoBytes: (await rootBundle.load('assets/images/app_icon.png')).buffer.asUint8List(), loadFonts: false);

  Agreement sample() => Agreement(
        id: '7d1e2f3a-0000-4000-8000-000000000042',
        songTitle: 'Mboa Love',
        genre: 'Afrobeats',
        description: 'Single recorded at Studio Ndop, Douala.',
        recordingDate: '2026-10-02',
        releaseDate: '2026-12-15',
        effectiveDate: '2026-11-24',
        scopeOfRights: 'Covers the master recording and the composition worldwide, including streaming and sync.',
        scopeCategories: const ['master', 'composition'],
        paymentTerms: 'Royalties are paid quarterly within 30 days of receipt, according to the shares below.',
        status: 'accepted',
        version: 2,
        reference: 'SS-AGR-2026-0042',
        finalizedAt: DateTime(2026, 11, 24),
        witnessName: 'Paul Etoa',
        witnessRole: 'Studio manager',
        createdAt: DateTime(2026, 11, 20),
        splits: [
          AgreementSplit(
              id: 'a', collaboratorName: 'Randolph Yufenyuy', role: 'Artist', splitPercentage: 50,
              contributionDescription: 'Lead vocals, lyrics', response: 'accepted', acceptedAt: DateTime(2026, 11, 22)),
          AgreementSplit(
              id: 'b', collaboratorName: 'Amina Ngono', role: 'Producer', splitPercentage: 35,
              contributionDescription: 'Beat, arrangement, mixing', response: 'accepted', acceptedAt: DateTime(2026, 11, 23)),
          AgreementSplit(id: 'c', collaboratorName: 'Kevin Mbah', role: 'Songwriter', splitPercentage: 15),
        ],
      );

  test('very long terms, 25 collaborators and emoji still produce a PDF', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final long = List.filled(120, 'Royalties are paid quarterly according to the agreed shares. ').join();
    final a = sample();
    final big = Agreement(
      id: a.id,
      songTitle: 'Mboa Love 🔥🎶',
      status: 'pending',
      createdAt: a.createdAt,
      scopeOfRights: long,
      paymentTerms: long,
      additionalTerms: long,
      splits: [
        for (var i = 0; i < 25; i++)
          AgreementSplit(id: 's$i', collaboratorName: 'Artist $i ✨', role: 'Producer', splitPercentage: 4),
      ],
    );
    final bytes = await buildAgreementPdf(big, l10n, brand: await brand());
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(pdfText('Mboa Love 🔥🎶 – “Hit”'), 'Mboa Love - "Hit"');
  });

  for (final code in ['en', 'fr']) {
    test('agreement + receipt PDFs build ($code)', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(code));
      final b = await brand();
      final agreement = await buildAgreementPdf(sample(), l10n, brand: b);
      final preview = await buildAgreementPdf(sample(), l10n, preview: true, brand: b);
      final tx = PaymentTransaction.fromJson({
        'id': '1', 'reference': 'SS-PRO-MIG1Z7Q-8F2K1Q', 'type': 'PRO_UPGRADE', 'amount_fcfa': 100,
        'provider': 'MTN', 'phone': '237677123456', 'status': 'success', 'provider_tx_id': '4f6c1d2e-7a1b-4c3d',
        'created_at': '2026-11-24T08:42:00Z', 'completed_at': '2026-11-24T08:43:10Z',
      });
      final receipt =
          await buildReceiptPdf(tx, const ReceiptHolder(name: 'Randolph Yufenyuy', isPro: true), l10n, brand: b);
      for (final bytes in [agreement, preview, receipt]) {
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      }
      final out = Platform.environment['PDF_OUT'];
      if (out != null) {
        File('$out/agreement_$code.pdf').writeAsBytesSync(agreement);
        File('$out/agreement_preview_$code.pdf').writeAsBytesSync(preview);
        File('$out/receipt_$code.pdf').writeAsBytesSync(receipt);
      }
    });
  }
}
