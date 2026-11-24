import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/protect/models/agreement.dart';
import '../../features/protect/providers/agreements_provider.dart';
import '../localization/l10n/app_localizations.dart';
import '../localization/l10n_helpers.dart';
import 'pdf_brand.dart';

/// Free preview (any status): watermarked, not stored.
Future<void> downloadAgreementPreview(Agreement agreement, AppLocalizations l10n) async {
  final bytes = await buildAgreementPdf(agreement, l10n, preview: true);
  await Printing.sharePdf(bytes: bytes, filename: '${agreement.displayReference}-v${agreement.version}-preview.pdf');
}

/// Final agreement (after unlock): generated once, stored privately for every party, then downloaded.
/// If it was already generated, the stored copy is downloaded instead.
Future<void> downloadFinalAgreement(Agreement agreement, AppLocalizations l10n, {String? storedPath}) async {
  if (storedPath != null) {
    await openStoredAgreementPdf(storedPath);
    return;
  }
  final bytes = await buildAgreementPdf(agreement, l10n);
  await storeFinalAgreementPdf(agreement, bytes);
  await Printing.sharePdf(bytes: bytes, filename: '${agreement.displayReference}-v${agreement.version}.pdf');
}

String _d(DateTime t) => formatDate(t.toLocal());

Future<Uint8List> buildAgreementPdf(Agreement agreement, AppLocalizations l10n,
    {bool preview = false, PdfBrand? brand}) async {
  final b = brand ?? await PdfBrand.load();
  final doc = pw.Document(
    title: '${l10n.collaborationAgreementCaps} - ${agreement.songTitle}',
    author: 'SplitSure',
    theme: b.theme,
  );

  // A page can only break between top-level items, never inside one. Short sections are one
  // item, so they move to the next page whole and a heading is never left alone at the bottom.
  // Long ones (big tables, long terms, many signatures) are handed over row by row, with the
  // heading glued to the first row, so they can continue on the next page.
  List<pw.Widget> section(String title, List<pw.Widget> items, {bool keepTogether = true}) {
    pw.Widget block(List<pw.Widget> children) =>
        padX(pw.Stack(children: [pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: children)]));
    if (keepTogether || items.length < 2) {
      return [
        // A Stack can never be split, so the whole section moves to the next page if needed
        // (plain boxes pass "splittable" through from their content).
        padX(pw.Stack(children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [brandSectionTitle(title), ...items, pw.SizedBox(height: 18)],
          ),
        ])),
      ];
    }
    return [
      block([brandSectionTitle(title), items.first]),
      for (final w in items.skip(1)) padX(w),
      pw.SizedBox(height: 18),
    ];
  }

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        // Drawn on top with real transparency (PDF ignores alpha in plain colours).
        buildForeground: preview ? (_) => _previewWatermark(l10n) : null,
      ),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 16),
              child: brandSlimHeader(b.logo, l10n.pdfReference(agreement.displayReference)),
            ),
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: brandFooter(ctx, 'SplitSure - splitsure.app', l10n.pdfPageOf('${ctx.pageNumber}', '${ctx.pagesCount}')),
      ),
      build: (ctx) => [
        brandHero(
          logo: b.logo,
          tagline: l10n.pdfTaglineOneLine,
          title: l10n.collaborationAgreementCaps,
          chips: [
            l10n.pdfReference(agreement.displayReference),
            '${l10n.versionLabel} ${agreement.version}',
            agreementStatusLabel(l10n, agreement.status).toUpperCase(),
            if (preview) l10n.pdfPreviewWatermark,
          ],
        ),
        pw.SizedBox(height: 22),
        padX(pw.Center(
          child: pw.Text(pdfText(l10n.agreementTitleFor(agreement.songTitle)),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: brandNavy)),
        )),
        pw.SizedBox(height: 18),
        ...section(l10n.songProjectInformation, [
          brandInfoCard([
            [l10n.agreementReference, agreement.displayReference],
            [l10n.versionLabel, '${agreement.version}'],
            [l10n.songTitle, agreement.songTitle],
            if (agreement.genre != null) [l10n.genre, agreement.genre!],
            if (agreement.description != null) [l10n.description, agreement.description!],
            if (agreement.recordingDate != null) [l10n.recordingDate, formatDate(agreement.recordingDate)],
            if (agreement.releaseDate != null) [l10n.releaseDate, formatDate(agreement.releaseDate)],
            if (agreement.effectiveDate != null) [l10n.effectiveDate, formatDate(agreement.effectiveDate)],
            [l10n.agreementStatus, agreementStatusLabel(l10n, agreement.status)],
            if (agreement.finalizedAt != null) [l10n.finalizedOn, _d(agreement.finalizedAt!)],
            [l10n.created, _d(agreement.createdAt)],
          ]),
        ]),
        if (agreement.scopeCategories.isNotEmpty || agreement.scopeOfRights != null)
          ...section(
            l10n.scopeOfRights,
            [
              if (agreement.scopeCategories.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final c in agreement.scopeCategories)
                      brandPill(scopeCategoryLabel(l10n, c), color: brandTealTint, textColor: brandTeal),
                  ]),
                ),
              if (agreement.scopeOfRights != null) ...brandTextBlocks(agreement.scopeOfRights!),
            ],
            keepTogether: (agreement.scopeOfRights?.length ?? 0) < 1500,
          ),
        if (agreement.splits.isNotEmpty)
          ...section(l10n.collaboratorsRevenueShares, _splitsTable(agreement.splits, l10n),
              keepTogether: agreement.splits.length <= 14),
        if (agreement.paymentTerms != null)
          ...section(l10n.paymentTerms, brandTextBlocks(agreement.paymentTerms!),
              keepTogether: agreement.paymentTerms!.length < 1500),
        if (agreement.additionalTerms != null)
          ...section(l10n.additionalTerms, brandTextBlocks(agreement.additionalTerms!),
              keepTogether: agreement.additionalTerms!.length < 1500),
        if (agreement.witnessName != null)
          ...section(l10n.witness, [
            brandInfoCard([
              [l10n.name, agreement.witnessName!],
              if (agreement.witnessEmail != null) [l10n.emailShort, agreement.witnessEmail!],
              if (agreement.witnessPhone != null) [l10n.phone, agreement.witnessPhone!],
              if (agreement.witnessRole != null) [l10n.roleRelationship, agreement.witnessRole!],
              if (agreement.witnessSignatureCode != null) [l10n.witnessCode, agreement.witnessSignatureCode!],
              if (agreement.witnessRespondedAt != null && agreement.witnessResponse == 'confirmed')
                [l10n.witnessConfirmed, formatDate(agreement.witnessRespondedAt)],
            ]),
          ]),
        if (agreement.lawyerName != null)
          ...section(l10n.legalRepresentative, [
            brandInfoCard([
              [l10n.name, agreement.lawyerName!],
              if (agreement.lawyerFirm != null) [l10n.lawFirm, agreement.lawyerFirm!],
              if (agreement.lawyerEmail != null) [l10n.emailShort, agreement.lawyerEmail!],
              if (agreement.lawyerPhone != null) [l10n.phone, agreement.lawyerPhone!],
              if (agreement.lawyerRegistration != null) [l10n.registration, agreement.lawyerRegistration!],
            ]),
          ]),
        ...section(l10n.acceptanceSignatures, _signatures(agreement, l10n), keepTogether: agreement.splits.length <= 4),
        padX(_disclaimer(l10n)),
        pw.SizedBox(height: 10),
      ],
    ),
  );

  return doc.save();
}

/// Large faint diagonal "PREVIEW" behind every page of a non-final copy.
pw.Widget _previewWatermark(AppLocalizations l10n) => pw.FullPage(
      ignoreMargins: true,
      child: pw.Center(
        child: pw.Opacity(
          opacity: 0.07,
          child: pw.Transform.rotate(
            angle: 0.6,
            child: pw.Text(pdfText(l10n.pdfPreviewWatermark),
                style: pw.TextStyle(fontSize: 46, fontWeight: pw.FontWeight.bold, color: brandNavy)),
          ),
        ),
      ),
    );

List<pw.Widget> _splitsTable(List<AgreementSplit> splits, AppLocalizations l10n) {
  final total = splits.fold(0.0, (sum, s) => sum + s.splitPercentage);
  pw.Widget cell(String text, {bool head = false, bool right = false, PdfColor? color, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: pw.Text(pdfText(text),
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: head ? 8.5 : 9.5,
              letterSpacing: head ? 1 : 0,
              fontWeight: head || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? (head ? brandWhite : brandNavy),
            )),
      );
  String pct(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}%';

  // A Column of separate rows (no outer box), so a long list continues on the next page.
  const side = pw.BorderSide(color: brandBorder, width: 0.8);
  return [
    pw.Container(
      decoration: const pw.BoxDecoration(
        gradient: brandBarGradient,
        borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(7)),
      ),
      child: pw.Row(children: [
        pw.Expanded(flex: 3, child: cell(l10n.name.toUpperCase(), head: true)),
        pw.Expanded(flex: 3, child: cell(l10n.role.toUpperCase(), head: true)),
        pw.Expanded(flex: 4, child: cell(l10n.contribution.toUpperCase(), head: true)),
        pw.Expanded(flex: 2, child: cell(l10n.sharePercent.toUpperCase(), head: true, right: true)),
      ]),
    ),
    for (var i = 0; i < splits.length; i++)
      pw.Container(
        decoration: pw.BoxDecoration(
          color: i.isOdd ? brandSoft : brandWhite,
          border: const pw.Border(left: side, right: side),
        ),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Expanded(flex: 3, child: cell(splits[i].collaboratorName, bold: true)),
          pw.Expanded(flex: 3, child: cell(musicRoleLabel(l10n, splits[i].role))),
          pw.Expanded(
              flex: 4,
              child: cell(
                  (splits[i].contributionDescription?.trim().isNotEmpty ?? false)
                      ? splits[i].contributionDescription!.trim()
                      : '-',
                  color: brandMuted)),
          pw.Expanded(
            flex: 2,
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: pw.Align(alignment: pw.Alignment.centerRight, child: brandPill(pct(splits[i].splitPercentage))),
            ),
          ),
        ]),
      ),
    pw.Container(
      decoration: const pw.BoxDecoration(
        color: brandTealTint,
        borderRadius: pw.BorderRadius.vertical(bottom: pw.Radius.circular(7)),
      ),
      child: pw.Row(children: [
        pw.Expanded(child: cell(l10n.pdfTotal('').replaceAll(RegExp(r'[:\s%]+$'), ''), bold: true)),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Text(pct(total),
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: (total - 100).abs() < 0.001 ? brandTeal : PdfColors.red700)),
        ),
      ]),
    ),
  ];
}

List<pw.Widget> _signatures(Agreement agreement, AppLocalizations l10n) {
  pw.Widget card(AgreementSplit s) {
    final accepted = s.response == 'accepted' || s.acceptedAt != null;
    final status = s.response != null ? agreementStatusLabel(l10n, s.response!) : l10n.pdfAwaitingResponse;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        gradient: brandSoftGradient,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: accepted ? brandTealLight : brandBorder, width: 0.8),
      ),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(pdfText(s.collaboratorName),
                style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: brandNavy)),
            pw.SizedBox(height: 2),
            pw.Text(pdfText(musicRoleLabel(l10n, s.role)), style: const pw.TextStyle(fontSize: 9, color: brandMuted)),
            pw.SizedBox(height: 8),
            brandPill(status.toUpperCase(),
                color: accepted ? brandTeal : const PdfColor.fromInt(0xFFE2E8F0),
                textColor: accepted ? brandWhite : brandMuted,
                fontSize: 7.5),
          ]),
        ),
        pw.SizedBox(width: 24),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(pdfText(l10n.signatureLabel), style: const pw.TextStyle(fontSize: 8.5, color: brandMuted)),
            if (accepted && s.signatureCode != null) ...[
              // Electronic signature: the party's signature code, stamped on the line.
              pw.SizedBox(height: 4),
              pw.Text(pdfText(s.collaboratorName),
                  style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: brandNavy)),
              pw.SizedBox(height: 2),
              pw.Text(s.signatureCode!,
                  style:
                      pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: brandTeal, letterSpacing: 1)),
              pw.SizedBox(height: 2),
            ] else
              pw.SizedBox(height: 22),
            pw.Container(height: 0.8, color: brandNavy),
            pw.SizedBox(height: 3),
            pw.Text(
              pdfText(s.acceptedAt != null
                  ? (s.signatureCode != null
                      ? l10n.pdfSignedOn(_d(s.acceptedAt!))
                      : l10n.pdfAcceptedOn(_d(s.acceptedAt!)))
                  : l10n.dateBlank),
              style: const pw.TextStyle(fontSize: 8, color: brandMuted),
            ),
            if (accepted && s.signatureCode != null)
              pw.Text(pdfText(s.signedVia == 'email' ? l10n.signedViaEmail : l10n.signedViaApp),
                  style: const pw.TextStyle(fontSize: 7.5, color: brandMuted)),
          ]),
        ),
      ]),
    );
  }

  return [
    pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(pdfText(l10n.pdfAcceptanceIntro),
          style: const pw.TextStyle(fontSize: 9, color: brandMuted, lineSpacing: 3)),
    ),
    for (final s in agreement.splits) card(s),
  ];
}

pw.Widget _disclaimer(AppLocalizations l10n) => pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF7ED),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFFDBA74), width: 0.6),
      ),
      child: pw.Text(
        pdfText(l10n.pdfDisclaimer),
        style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF9A3412), lineSpacing: 3),
      ),
    );
