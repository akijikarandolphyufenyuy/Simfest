import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import 'media_cache.dart';

SupabaseClient get _client => Supabase.instance.client;

/// Opens a file/photo picker only after the current tap has finished.
///
/// On the web the picker is a browser file dialog; opening it in the middle of
/// Flutter's pointer handling makes the mouse tracker re-enter itself, which
/// throws "Assertion failed: mouse_tracker.dart:199" in debug runs and leaves
/// hover/clicks misbehaving. The short delay stays well inside the browser's
/// user-activation window, so the dialog still opens.
Future<T> afterTap<T>(Future<T> Function() open) async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return open();
}

/// Proper MIME type for an image extension ("jpg" → "image/jpeg").
String imageMime(String ext) {
  final e = ext.toLowerCase();
  return switch (e) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => 'image/$e',
  };
}

/// Proper MIME type for an audio extension ("mp3" → "audio/mpeg").
String audioMime(String ext) => switch (ext.toLowerCase()) {
      'mp3' => 'audio/mpeg',
      'm4a' || 'aac' => 'audio/mp4',
      'wav' => 'audio/wav',
      'ogg' || 'oga' => 'audio/ogg',
      'flac' => 'audio/flac',
      final e => 'audio/$e',
    };

/// Pick and upload a profile avatar. Returns the public URL.
Future<String?> uploadAvatar() async {
  final picker = ImagePicker();
  final picked = await afterTap(() => picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80));
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  final uid = _client.auth.currentUser!.id;
  final ext = picked.name.split('.').last;
  final path = '$uid/avatar.$ext';

  await _client.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: imageMime(ext), upsert: true),
      );

  return _client.storage.from('avatars').getPublicUrl(path);
}

/// Pick and upload cover art for an agreement or campaign. Returns the public URL.
Future<String?> uploadCoverArt({required String bucket, required String folder}) async {
  final picker = ImagePicker();
  final picked = await afterTap(() => picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85));
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  final ext = picked.name.split('.').last;
  final path = '$folder/cover_${DateTime.now().millisecondsSinceEpoch}.$ext';

  await _client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: imageMime(ext), upsert: true),
      );

  final url = _client.storage.from(bucket).getPublicUrl(path);
  rememberMediaBytes(url, bytes, imageMime(ext)); // the promo video reuses it
  return url;
}

/// Pick and upload a music file for a campaign. Returns the public URL.
///
/// The picked file is also kept in memory so the promo video can be rendered
/// from it right away, without downloading the song again.
Future<String?> uploadMusicFile({required String folder, void Function(double progress)? onProgress}) async {
  final result = await afterTap(() => FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: true,
      ));
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) return null;

  final ext = (file.extension ?? 'mp3').toLowerCase();
  final type = audioMime(ext);
  final path = '$folder/music_${DateTime.now().millisecondsSinceEpoch}.$ext';
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: type));

  final url = await uploadBlob(
    bucket: 'campaign-assets',
    path: path,
    blob: blob,
    contentType: type,
    onProgress: onProgress,
  );
  rememberMediaBlob(url, blob);
  return url;
}

/// Uploads raw bytes (e.g. a generated video) and returns the public URL.
Future<String> uploadBytes({
  required String bucket,
  required String path,
  required Uint8List bytes,
  required String contentType,
}) async {
  await _client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
  return _client.storage.from(bucket).getPublicUrl(path);
}

/// Uploads a browser [blob] straight to storage and returns the public URL.
///
/// The file is sent as-is through a signed upload URL (no copy into Dart
/// memory, no multipart re-encoding) and real progress (0..1) is reported.
/// Falls back to the regular client upload if the direct request fails.
Future<String> uploadBlob({
  required String bucket,
  required String path,
  required web.Blob blob,
  required String contentType,
  void Function(double progress)? onProgress,
}) async {
  final store = _client.storage.from(bucket);
  try {
    final signed = await store.createSignedUploadUrl(path, upsert: true);
    await _putWithProgress(signed.signedUrl, blob, contentType, onProgress);
  } catch (_) {
    final buf = await blob.arrayBuffer().toDart;
    await store.uploadBinary(
      path,
      buf.toDart.asUint8List(),
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
  }
  onProgress?.call(1);
  return store.getPublicUrl(path);
}

Future<void> _putWithProgress(
  String url,
  web.Blob blob,
  String contentType,
  void Function(double progress)? onProgress,
) {
  final done = Completer<void>();
  final xhr = web.XMLHttpRequest()..open('PUT', url);
  xhr.setRequestHeader('content-type', contentType);
  xhr.setRequestHeader('x-upsert', 'true');
  xhr.setRequestHeader('cache-control', 'max-age=3600');
  xhr.upload.onprogress = ((web.ProgressEvent e) {
    if (e.lengthComputable && e.total > 0) onProgress?.call(e.loaded / e.total);
  }).toJS;
  xhr.onload = ((web.Event _) {
    if (done.isCompleted) return;
    if (xhr.status >= 200 && xhr.status < 300) {
      done.complete();
    } else {
      done.completeError(StateError('Upload failed (${xhr.status})'));
    }
  }).toJS;
  xhr.onerror = ((web.Event _) {
    if (!done.isCompleted) done.completeError(StateError('Network error during upload'));
  }).toJS;
  xhr.send(blob);
  return done.future;
}
