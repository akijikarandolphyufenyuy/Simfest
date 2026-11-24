// Browser-side promotional video generator (Flutter Web).
//
// Renders a 9:16 animated frame on a <canvas>, mixes in the selected audio
// snippet through Web Audio, and records both with MediaRecorder. The result is
// a real video file (MP4 where the browser supports it — Chrome/Edge/Safari —
// otherwise WebM). Nothing is faked: if recording fails, an error is thrown.
import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import '../../../core/services/media_cache.dart';

enum PromoTemplate {
  pulse('pulse'),
  waveform('waveform');

  final String id;
  const PromoTemplate(this.id);
}

class PromoVideoRequest {
  final String audioUrl;
  final String? coverUrl;
  final String title;
  final String artist;
  final String? message;
  final String? badge; // e.g. "OUT NOW" (already localized)
  final double start;
  final double end;
  final PromoTemplate template;

  const PromoVideoRequest({
    required this.audioUrl,
    required this.coverUrl,
    required this.title,
    required this.artist,
    required this.message,
    required this.badge,
    required this.start,
    required this.end,
    required this.template,
  });

  double get duration => (end - start).clamp(3, 60).toDouble();
}

class PromoVideoResult {
  /// The recorded file, kept as a browser Blob (uploaded and previewed without copying).
  final web.Blob blob;
  final String mimeType;
  final String extension;
  const PromoVideoResult(this.blob, this.mimeType, this.extension);
  bool get isMp4 => extension == 'mp4';
}

const _w = 720, _h = 1280, _fps = 30;

/// 2 Mbps is plenty for these motion graphics at 720p and keeps a 30 s clip
/// around 7–8 MB, so it uploads almost twice as fast as at 3.5 Mbps.
const _videoBitrate = 2000000;

/// Black frames recorded before the animation starts (~0.5 s), see generatePromoVideo.
const _preRollFrames = 15;

/// Chooses the best container this browser can record.
String? _pickMime() {
  const candidates = [
    'video/mp4;codecs="avc1.42E01E,mp4a.40.2"',
    'video/mp4;codecs=avc1,mp4a',
    'video/mp4',
    'video/webm;codecs=vp9,opus',
    'video/webm;codecs=vp8,opus',
    'video/webm',
  ];
  for (final c in candidates) {
    if (web.MediaRecorder.isTypeSupported(c)) return c;
  }
  return null;
}

bool get promoVideoSupported {
  try {
    return _pickMime() != null;
  } catch (_) {
    return false;
  }
}

/// Local object URL for [url] when the file is cached (or can be fetched once),
/// else the remote URL itself. Created object URLs are added to [created].
Future<String> _localSrc(String url, List<String> created) async {
  final blob = await cachedMedia(url);
  if (blob == null) return url;
  final local = web.URL.createObjectURL(blob);
  created.add(local);
  return local;
}

Future<web.HTMLImageElement?> _loadImage(String? src) async {
  if (src == null) return null;
  final img = web.HTMLImageElement()..crossOrigin = 'anonymous';
  final c = Completer<web.HTMLImageElement?>();
  img.onload = ((web.Event _) => c.complete(img)).toJS;
  img.onerror = ((web.Event _) => c.complete(null)).toJS;
  img.src = src;
  return c.future.timeout(const Duration(seconds: 20), onTimeout: () => null);
}

Future<void> _waitAudioReady(web.HTMLAudioElement a) {
  final c = Completer<void>();
  a.oncanplaythrough = ((web.Event _) {
    if (!c.isCompleted) c.complete();
  }).toJS;
  a.onerror = ((web.Event _) {
    if (!c.isCompleted) c.completeError(StateError('Audio could not be loaded'));
  }).toJS;
  a.load();
  return c.future.timeout(const Duration(seconds: 30));
}

Future<void> _seek(web.HTMLAudioElement a, double t) {
  final c = Completer<void>();
  a.onseeked = ((web.Event _) {
    if (!c.isCompleted) c.complete();
  }).toJS;
  a.currentTime = t;
  return c.future.timeout(const Duration(seconds: 10), onTimeout: () {});
}

/// Font stack for the video text: Inter (the app's font) with system fallbacks.
const _font = 'Inter, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';
Future<void>? _fontsReady;

/// Loads Inter into the page so the canvas can draw with it (once per session).
Future<void> _ensureFonts() => _fontsReady ??= () async {
      try {
        if (web.document.querySelector('link[data-promo-font]') == null) {
          final link = web.HTMLLinkElement()
            ..rel = 'stylesheet'
            ..href = 'https://fonts.googleapis.com/css2?family=Inter:wght@500;600;800&display=swap'
            ..setAttribute('data-promo-font', '1');
          web.document.head?.append(link);
          final loaded = Completer<void>();
          link.onload = ((web.Event _) => loaded.complete()).toJS;
          link.onerror = ((web.Event _) => loaded.complete()).toJS;
          await loaded.future.timeout(const Duration(seconds: 4), onTimeout: () {});
        }
        await Future.wait([
          for (final w in ['500', '600', '800']) web.document.fonts.load('$w 40px Inter').toDart,
        ]).timeout(const Duration(seconds: 4));
      } catch (_) {
        // Offline or blocked: the system fallback fonts are used.
      }
    }();

/// Generates the video. [onProgress] receives 0..1 while recording (real time).
Future<PromoVideoResult> generatePromoVideo(
  PromoVideoRequest req, {
  void Function(double progress)? onProgress,
}) async {
  final mime = _pickMime();
  if (mime == null) throw UnsupportedError('This browser cannot record video.');

  final canvas = web.HTMLCanvasElement()
    ..width = _w
    ..height = _h;
  final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;

  // Song and artwork come from the in-memory cache (filled when they were
  // uploaded or when the campaign opened), so nothing streams while recording.
  final objectUrls = <String>[];
  final (audioSrc, coverSrc, _) = await (
    _localSrc(req.audioUrl, objectUrls),
    req.coverUrl == null ? Future<String?>.value(null) : _localSrc(req.coverUrl!, objectUrls),
    _ensureFonts(),
  ).wait;
  final cover = await _loadImage(coverSrc);

  final audio = web.HTMLAudioElement()..preload = 'auto';
  if (!audioSrc.startsWith('blob:')) audio.crossOrigin = 'anonymous';
  audio.src = audioSrc;
  try {
    await _waitAudioReady(audio);
    await _seek(audio, req.start);
  } catch (_) {
    for (final u in objectUrls) {
      web.URL.revokeObjectURL(u);
    }
    rethrow;
  }

  final ac = web.AudioContext();
  final source = ac.createMediaElementSource(audio);
  final analyser = ac.createAnalyser()..fftSize = 128;
  final dest = ac.createMediaStreamDestination();
  source.connect(analyser);
  analyser.connect(dest);
  final freq = Uint8List(analyser.frequencyBinCount);
  final freqJs = freq.toJS;

  // Frame rate 0 = we push every frame ourselves (requestFrame after each draw),
  // so no frame is skipped while the encoder warms up or the tab is hidden.
  final videoStream = canvas.captureStream(0);
  final captureTrack = videoStream.getVideoTracks().toDart.first as web.CanvasCaptureMediaStreamTrack;
  void pushFrame() {
    try {
      captureTrack.requestFrame();
    } catch (_) {}
  }
  final tracks = <web.MediaStreamTrack>[
    ...videoStream.getVideoTracks().toDart,
    ...dest.stream.getAudioTracks().toDart,
  ];
  final stream = web.MediaStream(tracks.toJS);

  final recorder = web.MediaRecorder(
    stream,
    web.MediaRecorderOptions(mimeType: mime, videoBitsPerSecond: _videoBitrate, audioBitsPerSecond: 128000),
  );
  final chunks = <web.Blob>[];
  final stopped = Completer<void>();
  recorder.ondataavailable = ((web.BlobEvent e) {
    if (e.data.size > 0) chunks.add(e.data);
  }).toJS;
  recorder.onstop = ((web.Event _) => stopped.complete()).toJS;

  final painter = _Painter(ctx, req, cover);
  painter.draw(0, 0); // first frame before recording starts

  await ac.resume().toDart;
  recorder.start(250);
  pushFrame();

  final sw = Stopwatch();
  final duration = req.duration;
  final finished = Completer<void>();
  var preRoll = _preRollFrames;
  final timer = _FrameTicker(1000 ~/ _fps, (t) {
    // Pre-roll: the video encoder needs a moment to warm up and drops frames
    // meanwhile. Feed it the (black) opening frame first so no animation is lost.
    if (preRoll > 0) {
      pushFrame();
      if (--preRoll == 0) {
        audio.play().toDart.then((_) => sw.start(), onError: (Object e) {
          if (!finished.isCompleted) finished.completeError(e);
        });
      }
      return;
    }
    if (!sw.isRunning) return; // waiting for playback to begin
    final elapsed = sw.elapsedMilliseconds / 1000;
    analyser.getByteFrequencyData(freqJs);
    var level = 0.0;
    for (var i = 0; i < freq.length; i++) {
      level += freq[i];
    }
    level = freq.isEmpty ? 0 : (level / freq.length / 255);
    painter.draw(elapsed, level, bars: freq);
    pushFrame();
    onProgress?.call((elapsed / duration).clamp(0, 1));
    if (elapsed >= duration) {
      t.cancel();
      if (!finished.isCompleted) finished.complete();
    }
  });

  try {
    await finished.future.timeout(Duration(milliseconds: (duration * 1000).round() + 15000));
  } finally {
    timer.cancel();
  }
  audio.pause();
  if (recorder.state != 'inactive') recorder.stop();
  await stopped.future.timeout(const Duration(seconds: 10));
  for (final t in tracks) {
    t.stop();
  }
  await ac.close().toDart;
  audio.removeAttribute('src');
  for (final u in objectUrls) {
    web.URL.revokeObjectURL(u);
  }
  onProgress?.call(1);

  final type = mime.split(';').first;
  final blob = web.Blob(chunks.toJS, web.BlobPropertyBag(type: type));
  if (blob.size == 0) throw StateError('Recording produced an empty file.');
  return PromoVideoResult(blob, type, type.contains('mp4') ? 'mp4' : 'webm');
}

/// Calls [onTick] every [ms] milliseconds, driven by a Web Worker.
///
/// Browsers slow `setInterval`/Dart timers to about once per second when the
/// tab is in the background, which left recorded videos almost frozen if the
/// user switched tabs. Worker timers are not throttled that way, so the video
/// keeps its full frame rate. Falls back to a normal timer if workers fail.
class _FrameTicker {
  web.Worker? _worker;
  String? _url;
  Timer? _timer;
  bool _active = true;

  _FrameTicker(int ms, void Function(_FrameTicker) onTick) {
    try {
      final src = 'setInterval(function(){postMessage(0)},$ms);';
      _url = web.URL.createObjectURL(web.Blob([src.toJS].toJS, web.BlobPropertyBag(type: 'text/javascript')));
      _worker = web.Worker(_url!.toJS)
        ..onmessage = ((web.MessageEvent _) {
          if (_active) onTick(this);
        }).toJS;
    } catch (_) {
      _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
        if (_active) onTick(this);
      });
    }
  }

  void cancel() {
    if (!_active) return;
    _active = false;
    _worker?.terminate();
    _timer?.cancel();
    if (_url != null) web.URL.revokeObjectURL(_url!);
  }
}

/// Triggers a browser download of [bytes].
void downloadBytes(Uint8List bytes, String mimeType, String filename) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.append(a);
  a.click();
  a.remove();
  Timer(const Duration(seconds: 5), () => web.URL.revokeObjectURL(url));
}

/// Downloads a remote file (e.g. a stored video) under a friendly name.
Future<void> downloadUrl(String url, String filename) async {
  final blob = await cachedMedia(url);
  if (blob == null) throw StateError('Video could not be downloaded');
  final buf = await blob.arrayBuffer().toDart;
  downloadBytes(buf.toDart.asUint8List(), blob.type.isEmpty ? 'video/mp4' : blob.type, filename);
}

// ── Frame painter ─────────────────────────────────────────────────────────

class _Painter {
  final web.CanvasRenderingContext2D c;
  final PromoVideoRequest r;
  final web.HTMLImageElement? cover;

  _Painter(this.c, this.r, this.cover) : _bg = _renderBackground(cover) {
    final rnd = math.Random(7);
    _particles = List.generate(
      42,
      (_) => _Particle(
        rnd.nextDouble() * _w,
        rnd.nextDouble() * _h,
        0.35 + rnd.nextDouble() * 0.9,
        2 + rnd.nextDouble() * 4.5,
        rnd.nextDouble() * math.pi * 2,
        rnd.nextBool(),
      ),
    );
  }

  static const navy = '#142B4A', teal = '#12B8A6', tealDark = '#0D9488';

  /// Background (gradient + blurred artwork + vignette) drawn ONCE. Blurring the
  /// cover on every frame was the most expensive step and caused dropped frames.
  final web.HTMLCanvasElement _bg;
  late final List<_Particle> _particles;

  // Audio-reactive state
  double _lastT = 0, _smooth = 0, _bassAvg = 0, _beat = 0, _travel = 0;
  final _waves = <double>[]; // start times of beat shockwaves
  final _barVals = List<double>.filled(48, 0);

  static web.HTMLCanvasElement _renderBackground(web.HTMLImageElement? cover) {
    final bg = web.HTMLCanvasElement()
      ..width = _w
      ..height = _h;
    final b = bg.getContext('2d') as web.CanvasRenderingContext2D;
    final g = b.createLinearGradient(0, 0, _w.toDouble(), _h.toDouble());
    g.addColorStop(0, navy);
    g.addColorStop(1, tealDark);
    b.fillStyle = g;
    b.fillRect(0, 0, _w, _h);
    if (cover != null) {
      b.save();
      b.globalAlpha = 0.22;
      b.filter = 'blur(30px)';
      b.drawImage(cover, -200, -100, _w + 400, _h + 200);
      b.restore();
    }
    final v = b.createRadialGradient(_w / 2, _h * 0.42, _h * 0.2, _w / 2, _h / 2, _h * 0.75);
    v.addColorStop(0, 'rgba(0,0,0,0)');
    v.addColorStop(1, 'rgba(0,0,0,0.45)');
    b.fillStyle = v;
    b.fillRect(0, 0, _w, _h);
    return bg;
  }

  static double _easeOut(double x) => 1 - math.pow(1 - x.clamp(0.0, 1.0), 3).toDouble();

  /// Ease with a small overshoot ("pop").
  static double _easeBack(double x) {
    final p = x.clamp(0.0, 1.0);
    const k = 1.70158;
    return 1 + (k + 1) * math.pow(p - 1, 3) + k * math.pow(p - 1, 2);
  }

  void draw(double t, double level, {Uint8List? bars}) {
    final dt = (t - _lastT).clamp(0.0, 0.1);
    _lastT = t;

    // Bass energy (lowest bins) drives the beat; overall level drives the glow.
    var bass = level;
    if (bars != null && bars.isNotEmpty) {
      final n = math.min(6, bars.length);
      var s = 0;
      for (var i = 0; i < n; i++) {
        s += bars[i];
      }
      bass = s / n / 255;
    }
    _smooth += (level - _smooth) * 0.35;
    _bassAvg += (bass - _bassAvg) * 0.05;
    if (t > 0.6 && bass > _bassAvg * 1.18 + 0.03 && bass > 0.28 && _beat < 0.35) {
      _beat = 1;
      _waves.add(t);
    }
    _beat = math.max(0, _beat - dt * 3.2);
    _waves.removeWhere((w) => t - w > 0.9);
    _travel += dt * (1 + _smooth * 2.5);

    // Background: slow Ken Burns drift + a kick on each beat
    final zoom = 1.05 + 0.03 * math.sin(t * 0.3) + _beat * 0.025;
    c.save();
    c.translate(_w / 2 + math.sin(t * 0.2) * 12, _h / 2);
    c.scale(zoom, zoom);
    c.drawImage(_bg, -_w / 2, -_h / 2);
    c.restore();

    // Two soft moving lights
    c.save();
    c.globalAlpha = 0.10 + _smooth * 0.18;
    c.fillStyle = teal.toJS;
    c.beginPath();
    c.arc(_w / 2 + math.sin(t * 0.9) * 160, 380 + math.cos(t * 0.7) * 80, 300 + _smooth * 110, 0, math.pi * 2);
    c.fill();
    c.globalAlpha = 0.06 + _smooth * 0.10;
    c.fillStyle = '#FFFFFF'.toJS;
    c.beginPath();
    c.arc(_w / 2 - math.cos(t * 0.6) * 200, 980 + math.sin(t * 0.8) * 90, 220 + _smooth * 70, 0, math.pi * 2);
    c.fill();
    c.restore();

    _drawParticles(t);

    if (r.template == PromoTemplate.pulse) {
      _pulse(t, bars);
    } else {
      _waveform(t, bars);
    }
    _texts(t);
    _footer(t);

    // Flash on the beat + fade in from black at the start
    if (_beat > 0) {
      c.fillStyle = 'rgba(255,255,255,${(_beat * 0.07).toStringAsFixed(3)})'.toJS;
      c.fillRect(0, 0, _w, _h);
    }
    if (t < 0.35) {
      c.fillStyle = 'rgba(0,0,0,${(1 - t / 0.35).toStringAsFixed(3)})'.toJS;
      c.fillRect(0, 0, _w, _h);
    }
  }

  void _drawParticles(double t) {
    c.save();
    for (final p in _particles) {
      final y = (p.y - _travel * 60 * p.speed) % _h;
      final x = p.x + math.sin(_travel * 0.8 + p.phase) * 24;
      final a = (0.18 + 0.32 * (0.5 + 0.5 * math.sin(t * 2 + p.phase))) * (0.7 + _smooth);
      c.globalAlpha = a.clamp(0.0, 0.8);
      c.fillStyle = (p.teal ? teal : '#FFFFFF').toJS;
      c.beginPath();
      c.arc(x, y < 0 ? y + _h : y, p.size * (1 + _beat * 0.4), 0, math.pi * 2);
      c.fill();
    }
    c.restore();
  }

  /// Expanding rings that ripple out from the artwork on every beat.
  void _shockwaves(double t, double cx, double cy, double r0) {
    c.save();
    for (final w in _waves) {
      final p = ((t - w) / 0.9).clamp(0.0, 1.0);
      c.strokeStyle = 'rgba(255,255,255,${((1 - p) * 0.45).toStringAsFixed(3)})'.toJS;
      c.lineWidth = 6 * (1 - p) + 1;
      c.beginPath();
      c.arc(cx, cy, r0 + _easeOut(p) * 220, 0, math.pi * 2);
      c.stroke();
    }
    c.restore();
  }

  void _coverSquare(double t, double cx, double cy, double size, double radius) {
    c.save();
    c.shadowColor = 'rgba(0,0,0,0.45)';
    c.shadowBlur = 50;
    c.shadowOffsetY = 20;
    _roundRect(cx - size / 2, cy - size / 2, size, size, radius);
    c.fillStyle = navy.toJS;
    c.fill();
    c.restore();
    c.save();
    _roundRect(cx - size / 2, cy - size / 2, size, size, radius);
    c.clip();
    if (cover != null) {
      // slow zoom inside the frame
      final z = 1.04 + 0.04 * math.sin(t * 0.5);
      final s = size * z;
      c.drawImage(cover!, cx - s / 2, cy - s / 2, s, s);
    } else {
      final g = c.createLinearGradient(cx - size / 2, cy - size / 2, cx + size / 2, cy + size / 2);
      g.addColorStop(0, teal);
      g.addColorStop(1, navy);
      c.fillStyle = g;
      c.fillRect(cx - size / 2, cy - size / 2, size, size);
      c.fillStyle = 'rgba(255,255,255,0.9)'.toJS;
      c.font = '800 ${size * 0.4}px $_font';
      c.textAlign = 'center';
      c.textBaseline = 'middle';
      c.fillText('♪', cx, cy);
    }
    // light sweep across the artwork every 3.5 s
    final sweep = ((t - 1.0) % 3.5) / 0.9;
    if (t > 1.0 && sweep < 1) {
      final x = cx - size + sweep * size * 2;
      final g = c.createLinearGradient(x - 90, cy - size / 2, x + 90, cy + size / 2);
      g.addColorStop(0, 'rgba(255,255,255,0)');
      g.addColorStop(0.5, 'rgba(255,255,255,0.28)');
      g.addColorStop(1, 'rgba(255,255,255,0)');
      c.fillStyle = g;
      c.fillRect(cx - size / 2, cy - size / 2, size, size);
    }
    c.restore();
  }

  /// Smoothed spectrum value for bar [i] of [count].
  double _bar(int i, int count, Uint8List? bars, double t) {
    double target;
    if (bars != null && bars.isNotEmpty) {
      // Mirror from the centre (bass in the middle, highs at the edges) and
      // spread bars over the lower ~45% of bins, where music has its energy.
      final k = (i - (count - 1) / 2).abs() / (count / 2);
      final idx = (math.pow(k, 1.4) * bars.length * 0.45).floor().clamp(0, bars.length - 1);
      target = bars[idx] / 255;
    } else {
      target = (math.sin(t * 6 + i * 0.6) + 1) / 2 * 0.6;
    }
    final v = _barVals[i] + (target - _barVals[i]) * (target > _barVals[i] ? 0.6 : 0.18);
    return _barVals[i] = v;
  }

  void _pulse(double t, Uint8List? bars) {
    const cy = 460.0;
    final pop = _easeBack((t - 0.1) / 0.7);
    final beat = 1 + _smooth * 0.06 + _beat * 0.05;
    final size = 430 * beat * pop;
    if (size <= 1) return;

    _shockwaves(t, _w / 2, cy, size / 2 + 20);

    // radial spectrum around the artwork
    const count = 48;
    c.save();
    c.translate(_w / 2, cy);
    c.rotate(t * 0.15);
    c.lineCap = 'round';
    for (var i = 0; i < count; i++) {
      final v = _bar(i, count, bars, t);
      final a = i / count * math.pi * 2;
      final r0 = size / 2 + 92;
      final len = 6 + v * 46;
      c.strokeStyle = (i.isEven ? teal : 'rgba(255,255,255,0.85)').toJS;
      c.lineWidth = 6;
      c.globalAlpha = 0.45 + v * 0.55;
      c.beginPath();
      c.moveTo(math.cos(a) * r0, math.sin(a) * r0);
      c.lineTo(math.cos(a) * (r0 + len), math.sin(a) * (r0 + len));
      c.stroke();
    }
    c.restore();

    // rings spinning in opposite directions
    for (var i = 0; i < 3; i++) {
      c.save();
      c.translate(_w / 2, cy);
      c.rotate(t * (i.isEven ? 0.9 : -0.7) + i);
      c.strokeStyle = 'rgba(18,184,166,${(0.45 - i * 0.12 + _smooth * 0.3).clamp(0.0, 1.0)})'.toJS;
      c.lineWidth = 4;
      c.beginPath();
      c.arc(0, 0, size / 2 + 26 + i * 22 + _smooth * 18, 0, math.pi * (1.1 + i * 0.2));
      c.stroke();
      c.restore();
    }

    c.save();
    c.translate(_w / 2, cy);
    c.rotate(math.sin(t * 0.8) * 0.025);
    c.globalAlpha = pop.clamp(0.0, 1.0);
    _coverSquare(t, 0, 0, size, 36);
    c.restore();
  }

  void _waveform(double t, Uint8List? bars) {
    const cy = 410.0;
    final pop = _easeBack((t - 0.1) / 0.7);
    final size = 400 * (1 + _beat * 0.04) * pop;
    if (size > 1) {
      _shockwaves(t, _w / 2, cy, size / 2 + 10);
      c.save();
      c.translate(_w / 2, cy + math.sin(t * 1.2) * 6);
      c.globalAlpha = pop.clamp(0.0, 1.0);
      _coverSquare(t, 0, 0, size, 30);
      c.restore();
    }

    // mirrored audio-reactive bars that grow in from the centre
    const count = 32;
    const barW = 12.0, gap = 7.0;
    const total = count * barW + (count - 1) * gap;
    const x0 = (_w - total) / 2;
    const baseY = 745.0;
    final reveal = _easeOut((t - 0.3) / 0.8);
    for (var i = 0; i < count; i++) {
      final fromCentre = (i - (count - 1) / 2).abs() / (count / 2);
      if (fromCentre > reveal) continue;
      final v = _bar(i, count, bars, t);
      final hgt = 10 + v * 130;
      final g = c.createLinearGradient(0, baseY - hgt / 2, 0, baseY + hgt / 2);
      g.addColorStop(0, i.isEven ? teal : '#FFFFFF');
      g.addColorStop(1, i.isEven ? 'rgba(18,184,166,0.35)' : 'rgba(255,255,255,0.35)');
      c.fillStyle = g;
      c.globalAlpha = 0.95;
      _roundRect(x0 + i * (barW + gap), baseY - hgt / 2, barW, hgt, 6);
      c.fill();
    }
    c.globalAlpha = 1;

    // progress line with a glowing playhead
    final p = (t / r.duration).clamp(0.0, 1.0);
    c.fillStyle = 'rgba(255,255,255,0.25)'.toJS;
    _roundRect(90, 860, _w - 180, 6, 3);
    c.fill();
    c.fillStyle = teal.toJS;
    _roundRect(90, 860, (_w - 180) * p, 6, 3);
    c.fill();
    c.save();
    c.shadowColor = teal;
    c.shadowBlur = 18 + _beat * 20;
    c.fillStyle = '#FFFFFF'.toJS;
    c.beginPath();
    c.arc(90 + (_w - 180) * p, 863, 9 + _beat * 4, 0, math.pi * 2);
    c.fill();
    c.restore();
  }

  _TextLayout? _layout;

  /// Measures the text once: sizes shrink to fit so long titles / names stay
  /// inside the frame, and the whole block is centred in the space between the
  /// artwork and the footer.
  _TextLayout _buildLayout() {
    const maxW = _w - 120.0;
    final top = r.template == PromoTemplate.pulse ? 850.0 : 895.0;
    const bottom = _h - 110.0; // above the footer
    final items = <_TextLine>[];
    double gapAfterBadge = 0;

    // Badge
    String? badgeFont;
    double badgeW = 0;
    if (r.badge != null && r.badge!.trim().isNotEmpty) {
      badgeFont = '800 24px $_font';
      c.font = badgeFont;
      badgeW = c.measureText(r.badge!.toUpperCase()).width + 52;
      gapAfterBadge = 30;
    }

    // Title: largest size (64 → 40) that fits in two lines without cutting words.
    var titleSize = 64.0;
    late List<String> titleLines;
    while (true) {
      c.font = '800 ${titleSize}px $_font';
      titleLines = _wrap(r.title.trim(), maxW, 2);
      final fits =
          titleLines.every((l) => c.measureText(l).width <= maxW) && !(titleLines.lastOrNull?.endsWith('…') ?? false);
      if (fits || titleSize <= 40) break;
      titleSize -= 4;
    }
    for (final l in titleLines) {
      items.add(_TextLine(l, '800 ${titleSize}px $_font', titleSize * 1.15, '#FFFFFF'));
    }

    // Artist: one line, shrinks (36 → 24) before being shortened.
    var artistSize = 36.0;
    c.font = '600 ${artistSize}px $_font';
    while (c.measureText(r.artist).width > maxW && artistSize > 24) {
      artistSize -= 2;
      c.font = '600 ${artistSize}px $_font';
    }
    final artist = _wrap(r.artist, maxW, 1).firstOrNull ?? '';
    items.add(
        _TextLine(artist, '600 ${artistSize}px $_font', artistSize * 1.3, 'rgba(255,255,255,0.82)', gapBefore: 10));

    // Message: up to three lines.
    final msg = r.message?.trim() ?? '';
    if (msg.isNotEmpty) {
      const font = '500 28px $_font';
      c.font = font;
      final lines = _wrap(msg, maxW - 20, 3);
      for (var i = 0; i < lines.length; i++) {
        items.add(_TextLine(lines[i], font, 28 * 1.4, 'rgba(255,255,255,0.92)', gapBefore: i == 0 ? 24 : 0));
      }
    }

    final badgeH = badgeFont == null ? 0.0 : 48.0;
    final textH = items.fold<double>(0, (s, l) => s + l.gapBefore + l.height);
    final total = badgeH + gapAfterBadge + textH;
    final start = math.max(top, top + (bottom - top - total) / 2);
    return _TextLayout(badgeFont, badgeW, start, badgeH + gapAfterBadge, items);
  }

  /// Text block with staggered entrances: badge pops in, then each line slides
  /// up and fades in one after another. The badge also pulses on the beat.
  void _texts(double t) {
    final lay = _layout ??= _buildLayout();
    const cx = _w / 2;
    c.textAlign = 'center';
    c.textBaseline = 'middle';

    var y = lay.top;
    if (lay.badgeFont != null) {
      final pop = _easeBack((t - 0.35) / 0.5);
      if (pop > 0) {
        final s = pop * (1 + _beat * 0.07);
        c.save();
        c.globalAlpha = pop.clamp(0.0, 1.0);
        c.translate(cx, y + 24);
        c.scale(s, s);
        c.shadowColor = teal;
        c.shadowBlur = 16 + _beat * 18;
        c.fillStyle = teal.toJS;
        _roundRect(-lay.badgeW / 2, -24, lay.badgeW, 48, 24);
        c.fill();
        c.shadowBlur = 0;
        c.font = lay.badgeFont!;
        c.fillStyle = '#FFFFFF'.toJS;
        c.fillText(r.badge!.toUpperCase(), 0, 1);
        c.restore();
      }
    }
    y += lay.badgeBlock;

    for (var i = 0; i < lay.lines.length; i++) {
      final l = lay.lines[i];
      y += l.gapBefore;
      final e = _easeOut((t - 0.55 - i * 0.14) / 0.55);
      if (e > 0) {
        c.globalAlpha = e;
        c.font = l.font;
        c.fillStyle = l.color.toJS;
        c.fillText(l.text, cx, y + l.height / 2 + (1 - e) * 36);
      }
      y += l.height;
    }
    c.globalAlpha = 1;
  }

  void _footer(double t) {
    c.textAlign = 'center';
    c.textBaseline = 'middle';
    c.font = '600 24px $_font';
    c.fillStyle = 'rgba(255,255,255,0.55)'.toJS;
    c.fillText('SplitSure', _w / 2, _h - 64);
  }

  List<String> _wrap(String text, double maxW, int maxLines) {
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var line = '';
    for (final w in words) {
      final test = line.isEmpty ? w : '$line $w';
      if (c.measureText(test).width > maxW && line.isNotEmpty) {
        lines.add(line);
        line = w;
        if (lines.length == maxLines) break;
      } else {
        line = test;
      }
    }
    if (lines.length < maxLines && line.isNotEmpty) lines.add(line);
    if (lines.length == maxLines && words.join(' ') != lines.join(' ')) {
      var last = lines.last;
      while (last.isNotEmpty && c.measureText('$last…').width > maxW) {
        last = last.substring(0, last.length - 1);
      }
      lines[lines.length - 1] = '$last…';
    }
    return lines;
  }

  void _roundRect(double x, double y, double w, double h, double r) {
    final rr = math.min(r, math.min(w, h) / 2);
    c.beginPath();
    c.moveTo(x + rr, y);
    c.arcTo(x + w, y, x + w, y + h, rr);
    c.arcTo(x + w, y + h, x, y + h, rr);
    c.arcTo(x, y + h, x, y, rr);
    c.arcTo(x, y, x + w, y, rr);
    c.closePath();
  }
}

class _TextLine {
  final String text;
  final String font;
  final double height;
  final String color;
  final double gapBefore;
  const _TextLine(this.text, this.font, this.height, this.color, {this.gapBefore = 0});
}

class _TextLayout {
  final String? badgeFont;
  final double badgeW;
  final double top;
  final double badgeBlock; // badge height + gap below it
  final List<_TextLine> lines;
  const _TextLayout(this.badgeFont, this.badgeW, this.top, this.badgeBlock, this.lines);
}

class _Particle {
  final double x, y, speed, size, phase;
  final bool teal;
  const _Particle(this.x, this.y, this.speed, this.size, this.phase, this.teal);
}
