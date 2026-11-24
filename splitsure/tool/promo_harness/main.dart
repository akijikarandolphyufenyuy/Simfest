// Dev-only harness: renders a promo video in the browser without signing in.
// Build: dart compile js tool/promo_harness/main.dart -o <dir>/main.dart.js
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'package:splitsure/core/services/media_cache.dart';
import 'package:splitsure/features/reach/services/promo_video_service.dart';

/// A 12 s, 120 BPM test track: kick drum on every beat plus a bass note.
Uint8List _beatWav() {
  const rate = 22050, secs = 12;
  const n = rate * secs;
  final data = ByteData(44 + n * 2);
  void str(int o, String s) => s.codeUnits.asMap().forEach((i, c) => data.setUint8(o + i, c));
  str(0, 'RIFF');
  data.setUint32(4, 36 + n * 2, Endian.little);
  str(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    final b = t % 0.5; // beat every 0.5 s
    final kick = b < 0.15 ? math.sin(2 * math.pi * (60 - b * 200) * b) * math.exp(-b * 25) : 0.0;
    final bass = math.sin(2 * math.pi * 55 * t) * 0.15 + math.sin(2 * math.pi * 440 * t) * 0.05;
    final v = ((kick * 0.9 + bass) * 32767).clamp(-32767, 32767).toInt();
    data.setInt16(44 + i * 2, v, Endian.little);
  }
  return data.buffer.asUint8List();
}

String _coverDataUrl() {
  final cv = web.HTMLCanvasElement()
    ..width = 600
    ..height = 600;
  final c = cv.getContext('2d') as web.CanvasRenderingContext2D;
  final g = c.createLinearGradient(0, 0, 600, 600);
  g.addColorStop(0, '#F59E0B');
  g.addColorStop(1, '#DB2777');
  c.fillStyle = g;
  c.fillRect(0, 0, 600, 600);
  c.fillStyle = 'rgba(255,255,255,0.9)'.toJS;
  c.font = '800 90px sans-serif';
  c.textAlign = 'center';
  c.fillText('TEST', 300, 330);
  return cv.toDataURL('image/png');
}

void main() {
  const audioUrl = 'https://harness.local/beat.wav';
  rememberMediaBytes(audioUrl, _beatWav(), 'audio/wav');
  final cover = _coverDataUrl();
  final status = web.document.getElementById('status')!;

  void run(PromoTemplate template, String title, String message) {
    status.textContent = 'Rendering ${template.id}…';
    final sw = Stopwatch()..start();
    generatePromoVideo(
      PromoVideoRequest(
        audioUrl: audioUrl,
        coverUrl: cover,
        title: title,
        artist: 'Randolph Test Artist',
        message: message,
        badge: 'Out now',
        start: 0,
        end: 6,
        template: template,
      ),
      onProgress: (p) => status.textContent = 'Recording ${template.id}… ${(p * 100).round()}%',
    ).then((res) {
      final url = web.URL.createObjectURL(res.blob);
      final v = web.HTMLVideoElement()
        ..id = 'video-${template.id}'
        ..src = url
        ..controls = true
        ..muted = true
        ..style.width = '270px';
      web.document.getElementById('out')!.append(v);
      status.textContent =
          'Done ${template.id}: ${res.extension}, ${(res.blob.size / 1024).round()} KB, ${sw.elapsedMilliseconds} ms';
    }).catchError((Object e) {
      status.textContent = 'ERROR: $e';
    });
  }

  web.document.getElementById('pulse')!.addEventListener(
      'click',
      ((web.Event _) => run(PromoTemplate.pulse, 'Midnight in Douala',
          'New single out now on all platforms. Stream it, share it, love it!')).toJS);
  web.document.getElementById('wave')!.addEventListener(
      'click',
      ((web.Event _) => run(PromoTemplate.waveform, 'A Very Long Song Title That Needs To Shrink To Fit Nicely',
          'Short message.')).toJS);
}
