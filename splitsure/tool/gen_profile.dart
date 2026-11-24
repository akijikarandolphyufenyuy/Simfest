import 'dart:io';
void main() {
  final f = File(r'lib/features/profile/screens/profile_screen.dart');
  f.writeAsStringSync(src);
  stdout.writeln('done');
}
const src = r'''\nimport placeholder;\n''';