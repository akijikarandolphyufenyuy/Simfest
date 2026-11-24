import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shared look for every PDF SplitSure produces (agreements, receipts):
/// brand colours, gradients, the centred logo header and the Inter font.

const brandNavy = PdfColor.fromInt(0xFF142B4A);
const brandNavy2 = PdfColor.fromInt(0xFF1E3F6F);
const brandTeal = PdfColor.fromInt(0xFF0D9488);
const brandTealLight = PdfColor.fromInt(0xFF12B8A6);
const brandTealTint = PdfColor.fromInt(0xFFE6F7F5);
const brandMuted = PdfColor.fromInt(0xFF64748B);
const brandBorder = PdfColor.fromInt(0xFFE2E8F0);
const brandSoft = PdfColor.fromInt(0xFFF5F8FA);
const brandWhite = PdfColors.white;

const brandHeroGradient = pw.LinearGradient(
  colors: [brandNavy, brandNavy2, brandTeal],
  begin: pw.Alignment.topLeft,
  end: pw.Alignment.bottomRight,
);
const brandBarGradient = pw.LinearGradient(colors: [brandNavy, brandTeal]);
const brandSoftGradient = pw.LinearGradient(
  colors: [PdfColor.fromInt(0xFFF1FAF9), PdfColor.fromInt(0xFFF5F8FA)],
  begin: pw.Alignment.topLeft,
  end: pw.Alignment.bottomRight,
);

bool _unicodeFont = false;

/// Makes any text safe to print in a SplitSure PDF:
///  • emoji / pictographs (and their joiners) are removed – no font in a PDF can draw them;
///  • without the Inter font, typographic quotes and dashes become plain ones, so the
///    built-in PDF font never prints empty boxes.
String pdfText(String s) {
  var t = s.replaceAll(
      RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{1F1E6}-\u{1F1FF}\u{FE0F}\u{200D}\u{20E3}]',
          unicode: true),
      '');
  if (!_unicodeFont) {
    t = t
        .replaceAll(RegExp('[‘’‚′]'), "'")
        .replaceAll(RegExp('[“”„″]'), '"')
        .replaceAll('«', '"')
        .replaceAll('»', '"')
        .replaceAll(RegExp('[–—−]'), '-')
        .replaceAll('…', '...')
        .replaceAll('•', '-')
        .replaceAll(RegExp('[   ]'), ' ');
  }
  return t.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
}

/// Logo + font, loaded once per document.
class PdfBrand {
  final pw.ImageProvider logo;
  final pw.ThemeData? theme;
  const PdfBrand(this.logo, this.theme);

  static Future<PdfBrand> load({Uint8List? logoBytes, bool loadFonts = true}) async {
    final bytes = logoBytes ?? (await rootBundle.load('assets/images/app_icon.png')).buffer.asUint8List();
    final theme = loadFonts ? await _interTheme() : null;
    _unicodeFont = theme != null;
    return PdfBrand(pw.MemoryImage(bytes), theme);
  }

  /// Inter (the app's font) so accents and symbols render; null → built-in font (offline).
  static Future<pw.ThemeData?> _interTheme() async {
    try {
      final f = await Future.wait([
        PdfGoogleFonts.interRegular(),
        PdfGoogleFonts.interBold(),
        PdfGoogleFonts.interItalic(),
      ]).timeout(const Duration(seconds: 8));
      return pw.ThemeData.withFont(base: f[0], bold: f[1], italic: f[2]);
    } catch (_) {
      return null;
    }
  }
}

/// White rounded tile holding the logo.
pw.Widget brandLogoTile(pw.ImageProvider logo, {double size = 64}) => pw.Container(
      width: size,
      height: size,
      padding: pw.EdgeInsets.all(size * 0.1),
      decoration: pw.BoxDecoration(color: brandWhite, borderRadius: pw.BorderRadius.circular(size * 0.24)),
      child: pw.ClipRRect(
        horizontalRadius: size * 0.16,
        verticalRadius: size * 0.16,
        child: pw.Image(logo, fit: pw.BoxFit.cover),
      ),
    );

/// "Split" white + "Sure" teal wordmark.
pw.Widget brandWordmark({double size = 22}) => pw.RichText(
      text: pw.TextSpan(children: [
        pw.TextSpan(
            text: 'Split', style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold, color: brandWhite)),
        pw.TextSpan(
            text: 'Sure', style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold, color: brandTealLight)),
      ]),
    );

/// Full-width gradient hero with the logo centred, the wordmark, tagline, document title and chips.
pw.Widget brandHero({
  required pw.ImageProvider logo,
  required String tagline,
  required String title,
  List<String> chips = const [],
}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.fromLTRB(40, 30, 40, 26),
    decoration: const pw.BoxDecoration(gradient: brandHeroGradient),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      pw.Center(child: brandLogoTile(logo, size: 64)),
      pw.SizedBox(height: 10),
      brandWordmark(size: 22),
      pw.SizedBox(height: 2),
      pw.Text(pdfText(tagline), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
      pw.SizedBox(height: 14),
      pw.Container(width: 46, height: 2, color: brandTealLight),
      pw.SizedBox(height: 12),
      pw.Text(pdfText(title),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: brandWhite, letterSpacing: 2)),
      if (chips.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Wrap(
          alignment: pw.WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in chips)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF27507A),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFF5C86AE), width: 0.6),
                ),
                child: pw.Text(pdfText(c), style: const pw.TextStyle(fontSize: 8.5, color: brandWhite)),
              ),
          ],
        ),
      ],
    ]),
  );
}

/// Slim gradient bar used at the top of continuation pages (logo centred).
pw.Widget brandSlimHeader(pw.ImageProvider logo, String right) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      decoration: const pw.BoxDecoration(gradient: brandBarGradient),
      child: pw.Stack(alignment: pw.Alignment.center, children: [
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(pdfText(right), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey200)),
        ),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
          brandLogoTile(logo, size: 22),
          pw.SizedBox(width: 6),
          brandWordmark(size: 11),
        ]),
      ]),
    );

/// Gradient footer strip with page numbers.
pw.Widget brandFooter(pw.Context ctx, String left, String pageLabel) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      decoration: const pw.BoxDecoration(gradient: brandBarGradient),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(pdfText(left), style: const pw.TextStyle(fontSize: 8, color: brandWhite)),
        pw.Text(pdfText(pageLabel), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey200)),
      ]),
    );

/// Section heading: gradient accent bar + uppercase title + hairline.
pw.Widget brandSectionTitle(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(children: [
        pw.Container(
          width: 4,
          height: 14,
          decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                  colors: [brandTealLight, brandNavy], begin: pw.Alignment.topCenter, end: pw.Alignment.bottomCenter),
              borderRadius: pw.BorderRadius.circular(2)),
        ),
        pw.SizedBox(width: 8),
        pw.Text(pdfText(title).toUpperCase(),
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandNavy, letterSpacing: 1.2)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: pw.Container(height: 0.6, color: brandBorder)),
      ]),
    );

/// Label/value rows in a rounded card with alternating backgrounds.
/// [stacked]: label above the value (for narrow, side-by-side cards).
pw.Widget brandInfoCard(List<List<String>> rows, {double labelWidth = 150, bool stacked = false}) => pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: brandBorder, width: 0.8),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(children: [
        for (var i = 0; i < rows.length; i++)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: pw.BoxDecoration(
              color: i.isOdd ? brandSoft : brandWhite,
              borderRadius: rows.length == 1
                  ? pw.BorderRadius.circular(8)
                  : i == 0
                      ? const pw.BorderRadius.vertical(top: pw.Radius.circular(8))
                      : i == rows.length - 1
                          ? const pw.BorderRadius.vertical(bottom: pw.Radius.circular(8))
                          : null,
            ),
            child: stacked
                ? pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(pdfText(rows[i][0]), style: const pw.TextStyle(fontSize: 8, color: brandMuted)),
                    pw.SizedBox(height: 2),
                    pw.Text(pdfText(rows[i][1]),
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandNavy)),
                  ])
                : pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.SizedBox(
                      width: labelWidth,
                      child: pw.Text(pdfText(rows[i][0]), style: const pw.TextStyle(fontSize: 9, color: brandMuted)),
                    ),
                    pw.Expanded(
                      child: pw.Text(pdfText(rows[i][1]),
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: brandNavy)),
                    ),
                  ]),
          ),
      ]),
    );

/// Text block with a soft gradient background and a teal left edge.
// (Teal outer box showing 3pt on the left, soft inner box on top: sizes to its text,
// unlike a stretched Row, which has no height limit inside a multi-page document.)
// Long text is cut into paragraph-sized boxes (a single box taller than a page can't be
// placed); the boxes sit in a Column, which the document can continue on the next page.
pw.Widget brandTextBlock(String text) {
  final boxes = brandTextBlocks(text);
  return boxes.length == 1
      ? boxes.first
      : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: boxes);
}

/// The same text as separate boxes, for documents that must be able to break between them.
List<pw.Widget> brandTextBlocks(String text) {
  final chunks = _chunks(pdfText(text), 900);
  pw.Widget box(String t) => pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 4),
        decoration: pw.BoxDecoration(color: brandTealLight, borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Container(
          margin: const pw.EdgeInsets.only(left: 3),
          padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const pw.BoxDecoration(
            gradient: brandSoftGradient,
            borderRadius: pw.BorderRadius.horizontal(right: pw.Radius.circular(8), left: pw.Radius.circular(6)),
          ),
          child: pw.Text(t, style: const pw.TextStyle(fontSize: 9.5, color: brandNavy, lineSpacing: 4)),
        ),
      );
  return [for (final c in chunks) box(c)];
}

/// Splits text at paragraph, then sentence, then word boundaries into pieces of at most [max] characters.
List<String> _chunks(String text, int max) {
  final out = <String>[];
  for (final para in text.split(RegExp(r'\n\s*\n'))) {
    var rest = para.trim();
    while (rest.length > max) {
      var cut = rest.lastIndexOf(RegExp(r'[.!?;]\s'), max);
      if (cut < max ~/ 3) cut = rest.lastIndexOf(' ', max);
      if (cut < max ~/ 3) cut = max - 1;
      out.add(rest.substring(0, cut + 1).trim());
      rest = rest.substring(cut + 1).trim();
    }
    if (rest.isNotEmpty) out.add(rest);
  }
  return out.isEmpty ? [''] : out;
}

/// Rounded pill (status badges, shares).
pw.Widget brandPill(String text,
        {PdfColor color = brandTeal, PdfColor textColor = brandWhite, double fontSize = 8.5}) =>
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(9)),
      child: pw.Text(pdfText(text),
          style:
              pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: textColor, letterSpacing: 0.5)),
    );

/// Horizontal padding helper for full-bleed pages.
pw.Widget padX(pw.Widget child, [double x = 40]) =>
    pw.Padding(padding: pw.EdgeInsets.symmetric(horizontal: x), child: child);
