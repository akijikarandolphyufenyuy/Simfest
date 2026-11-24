// Adds or updates translation keys in both ARB files.
//
// Usage: dart run tool/add_l10n.dart <table.txt>
// Each non-empty, non-# line:  key | English | Français | placeholders
//   placeholders (optional): "name" or "name:int,other" (default type String)
// Use \n for a line break inside a text. Run `flutter gen-l10n` afterwards.
import 'dart:convert';
import 'dart:io';

const _dir = 'lib/core/localization/l10n';

void main(List<String> args) {
  final rows = File(args.first)
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty && !l.trimLeft().startsWith('#'))
      .map((l) => l.split('|').map((c) => c.trim()).toList());

  Map<String, dynamic> load(String f) => jsonDecode(File('$_dir/$f').readAsStringSync()) as Map<String, dynamic>;
  final en = load('app_en.arb');
  final fr = load('app_fr.arb');
  var added = 0, updated = 0;

  for (final r in rows) {
    if (r.length < 3) {
      stderr.writeln('Skipping malformed row: ${r.join(' | ')}');
      continue;
    }
    final key = r[0];
    en.containsKey(key) ? updated++ : added++;
    en[key] = r[1].replaceAll(r'\n', '\n');
    fr[key] = r[2].replaceAll(r'\n', '\n');
    if (r.length > 3 && r[3].isNotEmpty) {
      en['@$key'] = {
        'placeholders': {
          for (final p in r[3].split(','))
            p.split(':').first.trim(): {'type': p.contains(':') ? p.split(':').last.trim() : 'String'}
        }
      };
    }
  }

  const enc = JsonEncoder.withIndent('  ');
  File('$_dir/app_en.arb').writeAsStringSync('${enc.convert(en)}\n');
  File('$_dir/app_fr.arb').writeAsStringSync('${enc.convert(fr)}\n');
  stdout.writeln('added $added, updated $updated');
}
