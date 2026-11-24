import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import '../../../core/localization/l10n/app_localizations.dart';
import '../../../core/services/media_cache.dart';
import '../models/campaign.dart';
import 'social_captions.dart';
import 'promo_video_service.dart';

/// Where Reach content can be posted.
///
/// Direct posting through TikTok / Instagram / Facebook APIs needs a developer app
/// approved by each platform. Until then SplitSure uses the official route every
/// phone supports: the system share sheet hands the video + caption straight to
/// the platform's app. On a computer the caption is copied, the video downloaded
/// and the platform's upload page opened.
export 'social_captions.dart';

/// Outcome of [shareToPlatform], used to tell the user what happened.
enum ShareOutcome { sharedToApp, openedWebPage, cancelled }

bool get _isTouchDevice {
  final ua = web.window.navigator.userAgent.toLowerCase();
  return ua.contains('android') || ua.contains('iphone') || ua.contains('ipad') || ua.contains('mobile');
}

final _videoCache = <String, web.File>{};

/// Downloads the video once and keeps it ready so sharing is instant.
Future<web.File?> prefetchVideo(String? url, String name) async {
  if (url == null) return null;
  final hit = _videoCache[url];
  if (hit != null) return hit;
  try {
    // Freshly generated videos are already in memory; others are fetched once.
    final blob = await cachedMedia(url);
    if (blob == null) return null;
    final type = blob.type.isEmpty ? (url.contains('.webm') ? 'video/webm' : 'video/mp4') : blob.type;
    final ext = type.contains('webm') ? 'webm' : 'mp4';
    final file = web.File([blob].toJS, '$name.$ext', web.FilePropertyBag(type: type));
    return _videoCache[url] = file;
  } catch (_) {
    return null;
  }
}

/// Shares the content to [p]. Always copies the caption first so it can be pasted.
///
/// Must be called straight from a tap: browsers only allow sharing / opening pages
/// in direct response to the user (the video should be prefetched with [prefetchVideo]).
Future<ShareOutcome> shareToPlatform(
  SocialPlatform p, {
  required String caption,
  required String songTitle,
  String? videoUrl,
  String? link,
  web.File? video,
}) async {
  await Clipboard.setData(ClipboardData(text: caption));
  final nav = web.window.navigator;

  // Phones: system share sheet with the video file (TikTok, Instagram, WhatsApp... appear there).
  if (_isTouchDevice) {
    try {
      final data = web.ShareData(title: songTitle, text: caption);
      if (video != null) {
        final withFile = web.ShareData(title: songTitle, text: caption, files: [video].toJS);
        if (nav.canShare(withFile)) {
          await nav.share(withFile).toDart;
          return ShareOutcome.sharedToApp;
        }
      }
      if (nav.canShare(data)) {
        await nav.share(data).toDart;
        return ShareOutcome.sharedToApp;
      }
    } catch (e) {
      // AbortError = the user closed the share sheet.
      if (e.toString().contains('AbortError')) return ShareOutcome.cancelled;
    }
  }

  // Computers (or no share sheet): open the platform's page and download the video.
  web.window.open(p.uploadPage(caption, link), '_blank');
  if (p.needsVideo && videoUrl != null) {
    if (video != null) {
      final buf = await video.arrayBuffer().toDart;
      downloadBytes(buf.toDart.asUint8List(), video.type, video.name);
    } else {
      await downloadUrl(videoUrl, '${_safe(songTitle)}-promo.mp4');
    }
  }
  return ShareOutcome.openedWebPage;
}

String _safe(String s) => s.replaceAll(RegExp(r'[^\w\- ]'), '').trim().replaceAll(' ', '-');

/// "Content pack": the video plus a text file with every platform's caption, for posting by hand.
Future<void> downloadContentPack(Campaign c, AppLocalizations l10n, {String? artist, web.File? video}) async {
  final b = StringBuffer()
    ..writeln('SplitSure Reach - ${c.songTitle}')
    ..writeln('=' * 40)
    ..writeln();
  for (final p in SocialPlatform.values) {
    b
      ..writeln('[${p.label}]')
      ..writeln(captionFor(p, c, l10n, artist: artist))
      ..writeln()
      ..writeln('-' * 40)
      ..writeln();
  }
  if (c.generatedHashtags != null) {
    b
      ..writeln('[Hashtags]')
      ..writeln(c.generatedHashtags);
  }
  final base = _safe(c.songTitle).isEmpty ? 'campaign' : _safe(c.songTitle);
  downloadBytes(Uint8List.fromList(utf8.encode(b.toString())), 'text/plain;charset=utf-8', '$base-captions.txt');
  if (video != null) {
    final buf = await video.arrayBuffer().toDart;
    downloadBytes(buf.toDart.asUint8List(), video.type, video.name);
  } else if (c.videoUrl != null) {
    await downloadUrl(c.videoUrl!, '$base-promo.mp4');
  }
}
