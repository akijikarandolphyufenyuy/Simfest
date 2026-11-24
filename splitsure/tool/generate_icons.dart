// Generates the favicon and PWA icons from assets/images/logo.jpeg.
// Run from the project root:  dart run tool/generate_icons.dart
//
// The logo file contains the "S" mark, the SplitSure wordmark and a tagline.
// Icons use only the "S" mark, centred on a white square.
import 'dart:io';
import 'package:image/image.dart' as img;

// Bounding box of the "S" mark inside logo.jpeg (960x936).
const _markX = 140, _markY = 10, _markW = 730, _markH = 500;

void main() {
  final src = img.decodeJpg(File('assets/images/logo.jpeg').readAsBytesSync())!;
  final mark = img.copyCrop(src, x: _markX, y: _markY, width: _markW, height: _markH);

  void write(String path, int size, {required double padding, bool rgba = false}) {
    final canvas = img.Image(width: size, height: size, numChannels: rgba ? 4 : 3);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    final inner = (size * (1 - padding * 2)).round();
    final scale = inner / (_markW > _markH ? _markW : _markH);
    final w = (_markW * scale).round(), h = (_markH * scale).round();
    final resized = img.copyResize(mark, width: w, height: h, interpolation: img.Interpolation.cubic);
    img.compositeImage(canvas, resized, dstX: (size - w) ~/ 2, dstY: (size - h) ~/ 2);
    File(path).writeAsBytesSync(img.encodePng(canvas));
    stdout.writeln('wrote $path (${size}x$size)');
  }

  write('web/favicon.png', 48, padding: 0.04);
  // In-app icon (auth screens, headers).
  write('assets/images/app_icon.png', 256, padding: 0.1);
  write('web/icons/Icon-192.png', 192, padding: 0.08);
  write('web/icons/Icon-512.png', 512, padding: 0.08);
  // Maskable icons need the artwork inside the central ~80% safe zone.
  write('web/icons/Icon-maskable-192.png', 192, padding: 0.18, rgba: true);
  write('web/icons/Icon-maskable-512.png', 512, padding: 0.18, rgba: true);
}
