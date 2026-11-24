import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/localization/l10n_helpers.dart';
import '../../../core/services/pdf_brand.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../auth/providers/profile_provider.dart';
import '../models/subscription.dart';

/// Who the receipt is for and what plan they are on right now.
class ReceiptHolder {
  final String name;
  final bool isPro;
  const ReceiptHolder({required this.name, required this.isPro});
}

/// Builds and downloads the receipt for a successful payment.
/// Receipts are generated from the server's payment record, so they are always
/// available from Subscription → Payment history and never stored twice.
Future<void> downloadReceipt(BuildContext context, WidgetRef ref, PaymentTransaction tx) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final profile = await ref.read(profileProvider.future);
    final ent = await fetchEntitlement();
    final holder = ReceiptHolder(name: profile?.displayName ?? '', isPro: ent.isPro);
    final bytes = await buildReceiptPdf(tx, holder, l10n);
    await Printing.sharePdf(bytes: bytes, filename: 'SplitSure-receipt-${tx.reference}.pdf');
  } catch (e) {
    if (context.mounted) showError(context, l10n.receiptError(friendlyError(e)));
  }
}

Future<Uint8List> buildReceiptPdf(PaymentTransaction tx, ReceiptHolder holder, AppLocalizations l10n,
    {PdfBrand? brand}) async {
  final b = brand ?? await PdfBrand.load();
  final paidAt = tx.completedAt ?? tx.createdAt;
  final reason = tx.type == 'PRO_UPGRADE' ? l10n.receiptDescPro : l10n.receiptDescAgreement;
  final amount = '${formatFcfa(tx.amountFcfa)} FCFA';
  final method = tx.provider == 'MTN' ? l10n.mtnMomo : l10n.orangeMoney;
  final account = holder.isPro ? l10n.proPlan : l10n.freePlan;

  final doc = pw.Document(title: '${l10n.receiptTitle} ${tx.reference}', author: 'SplitSure', theme: b.theme);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        brandHero(
          logo: b.logo,
          tagline: l10n.pdfTaglineOneLine,
          title: l10n.receiptTitle,
          chips: [l10n.receiptNumber(tx.reference), l10n.receiptIssuedOn(formatDate(DateTime.now()))],
        ),
        pw.SizedBox(height: 24),
        padX(_amountCard(l10n, amount, reason)),
        pw.SizedBox(height: 22),
        padX(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
              brandSectionTitle(l10n.receiptBilledTo),
              brandInfoCard(stacked: true, [
                [l10n.receiptCustomerName, holder.name.isEmpty ? '-' : holder.name],
                [l10n.receiptPhoneUsed, formatPhone(tx.phone)],
                [l10n.receiptAccountType, account],
              ]),
            ]),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
              brandSectionTitle(l10n.receiptPaymentDetails),
              brandInfoCard(stacked: true, [
                [l10n.receiptDate, _dateTime(paidAt)],
                [l10n.receiptPaymentMethod, method],
                [l10n.receiptTransactionId, tx.providerTxId ?? tx.reference],
                [l10n.receiptReference, tx.reference],
              ]),
            ]),
          ),
        ])),
        pw.SizedBox(height: 22),
        padX(_lineItems(l10n, reason, amount)),
        pw.SizedBox(height: 26),
        padX(_thanks(l10n)),
        pw.Spacer(),
        brandFooter(ctx, 'SplitSure - splitsure.app', l10n.pdfTaglineOneLine),
      ]),
    ),
  );
  return doc.save();
}

/// Big amount with a round PAID stamp, on a soft gradient card.
pw.Widget _amountCard(AppLocalizations l10n, String amount, String reason) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColor.fromInt(0xFFE6F7F5), PdfColor.fromInt(0xFFF5F8FA)],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFB2E5DF), width: 0.8),
      ),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(pdfText(l10n.receiptTotalPaid).toUpperCase(),
                style: pw.TextStyle(fontSize: 9, color: brandTeal, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
            pw.SizedBox(height: 4),
            pw.Text(amount, style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: brandNavy)),
            pw.SizedBox(height: 3),
            pw.Text(pdfText(reason), style: const pw.TextStyle(fontSize: 10.5, color: brandMuted)),
          ]),
        ),
        pw.Container(
          width: 78,
          height: 78,
          decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: brandTeal, width: 2)),
          child: pw.Center(
            child: pw.Container(
              width: 66,
              height: 66,
              decoration: const pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                gradient: pw.LinearGradient(
                    colors: [brandTealLight, brandTeal], begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight),
              ),
              child: pw.Center(
                child: pw.Text(pdfText(l10n.receiptPaid),
                    style: pw.TextStyle(
                        color: brandWhite, fontSize: 13, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
              ),
            ),
          ),
        ),
      ]),
    );

pw.Widget _lineItems(AppLocalizations l10n, String reason, String amount) {
  pw.Widget th(String s, {bool right = false}) => pw.Text(pdfText(s).toUpperCase(),
      textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: brandWhite, letterSpacing: 1));
  const cellStyle = pw.TextStyle(fontSize: 10.5, color: brandNavy);
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: brandBorder, width: 0.8),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: const pw.BoxDecoration(
          gradient: brandBarGradient,
          borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(7)),
        ),
        child: pw.Row(children: [
          pw.Expanded(child: th(l10n.receiptReason)),
          pw.SizedBox(width: 120, child: th(l10n.receiptAmount, right: true)),
        ]),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(pdfText(reason), style: cellStyle)),
          pw.SizedBox(width: 120, child: pw.Text(amount, textAlign: pw.TextAlign.right, style: cellStyle)),
        ]),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: const pw.BoxDecoration(
          color: brandTealTint,
          borderRadius: pw.BorderRadius.vertical(bottom: pw.Radius.circular(7)),
        ),
        child: pw.Row(children: [
          pw.Expanded(
            child: pw.Text(pdfText(l10n.receiptTotalPaid),
                style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: brandNavy)),
          ),
          pw.Text(amount, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brandTeal)),
        ]),
      ),
    ]),
  );
}

pw.Widget _thanks(AppLocalizations l10n) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: pw.BoxDecoration(gradient: brandSoftGradient, borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(children: [
        pw.Text(pdfText(l10n.receiptThanks),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandNavy)),
        pw.SizedBox(height: 4),
        pw.Text(pdfText(l10n.receiptFooterNote),
            textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8.5, color: brandMuted)),
      ]),
    );

/// 1000 → "1 000" (plain spaces: the built-in PDF font has no narrow no-break space).
String formatFcfa(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

/// "237677123456" → "+237 677 12 34 56"; anything else is shown as stored.
String formatPhone(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length == 12 && d.startsWith('237')) {
    final n = d.substring(3);
    return '+237 ${n.substring(0, 3)} ${n.substring(3, 5)} ${n.substring(5, 7)} ${n.substring(7)}';
  }
  if (d.length == 9) return '+237 ${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5, 7)} ${d.substring(7)}';
  return raw;
}

String _dateTime(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${formatDate(l)}  ${two(l.hour)}:${two(l.minute)}';
}
