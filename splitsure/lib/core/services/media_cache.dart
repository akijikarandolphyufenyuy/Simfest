// In-memory cache of media files (music, cover art, generated videos) for the
// current browser session (Flutter Web).
//
// A file the user just picked or just generated is kept as a Blob under its
// public URL, so the promo-video renderer and the share panel use the local
// copy instead of downloading it again from storage. Files that are not cached
// yet are fetched once and shared by every caller.
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

final _blobs = <String, web.Blob>{};
final _pending = <String, Future<web.Blob?>>{};

/// Keeps [blob] as the local copy of [url].
void rememberMediaBlob(String url, web.Blob blob) => _blobs[url] = blob;

/// Keeps [bytes] as the local copy of [url].
void rememberMediaBytes(String url, Uint8List bytes, String contentType) =>
    _blobs[url] = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: contentType));

/// The local copy of [url], downloading it once if needed. Null if it cannot be fetched.
Future<web.Blob?> cachedMedia(String? url) {
  if (url == null) return Future.value(null);
  final hit = _blobs[url];
  if (hit != null) return Future.value(hit);
  return _pending[url] ??= () async {
    try {
      final res = await web.window.fetch(url.toJS).toDart;
      if (!res.ok) return null;
      final blob = await res.blob().toDart;
      _blobs[url] = blob;
      return blob;
    } catch (_) {
      return null;
    } finally {
      _pending.remove(url);
    }
  }();
}

/// Starts downloading [urls] in the background so they are ready when needed.
void prefetchMedia(Iterable<String?> urls) {
  for (final u in urls) {
    cachedMedia(u);
  }
}
