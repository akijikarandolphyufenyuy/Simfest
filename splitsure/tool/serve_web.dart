// Minimal static server for a Flutter web build (local testing only).
// Usage: dart run tool/serve_web.dart build/web 8765
import 'dart:io';

const _types = {
  'html': 'text/html; charset=utf-8',
  'js': 'application/javascript',
  'mjs': 'application/javascript',
  'json': 'application/json',
  'wasm': 'application/wasm',
  'css': 'text/css',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'svg': 'image/svg+xml',
  'ico': 'image/x-icon',
  'ttf': 'font/ttf',
  'otf': 'font/otf',
  'woff': 'font/woff',
  'woff2': 'font/woff2',
  'bin': 'application/octet-stream',
  'frag': 'application/octet-stream',
};

Future<void> main(List<String> args) async {
  final root = Directory(args.isNotEmpty ? args[0] : 'build/web').absolute.path;
  final port = args.length > 1 ? int.parse(args[1]) : 8765;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Serving $root on http://localhost:$port');
  await for (final req in server) {
    var path = Uri.decodeComponent(req.uri.path);
    if (path.endsWith('/')) path += 'index.html';
    final file = File('$root$path');
    final res = req.response..headers.set('Cache-Control', 'no-store');
    if (!file.path.startsWith(root) || !await file.exists()) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      continue;
    }
    final ext = path.split('.').last.toLowerCase();
    res.headers.contentType = ContentType.parse(_types[ext] ?? 'application/octet-stream');
    await res.addStream(file.openRead());
    await res.close();
  }
}
