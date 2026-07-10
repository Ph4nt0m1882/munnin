import 'dart:io';

void main() {
  final lucideFile = File(r'C:\Users\barre\AppData\Local\Pub\Cache\hosted\pub.dev\flutter_lucide-1.11.0\lib\src\flutter_lucide.dart');
  final simpleFile = File(r'C:\Users\barre\AppData\Local\Pub\Cache\hosted\pub.dev\simple_icons-16.23.0\lib\src\icon_data.g.dart');

  final output = StringBuffer();
  output.writeln('import \'package:flutter/widgets.dart\';');
  output.writeln('import \'package:flutter_lucide/flutter_lucide.dart\';');
  output.writeln('import \'package:simple_icons/simple_icons.dart\';\n');

  // Lucide Icons
  output.writeln('final Map<String, IconData> lucideIconsMap = {');
  if (lucideFile.existsSync()) {
    final content = lucideFile.readAsStringSync();
    final regex = RegExp(r'static const IconData ([a-zA-Z0-9_]+) = IconData');
    final matches = regex.allMatches(content);
    for (final match in matches) {
      final name = match.group(1);
      if (name != null && !name.startsWith('_')) {
        output.writeln('  \'lucide-$name\': LucideIcons.$name,');
      }
    }
  }
  output.writeln('};\n');

  // Simple Icons
  output.writeln('final Map<String, IconData> simpleIconsMap = {');
  if (simpleFile.existsSync()) {
    final content = simpleFile.readAsStringSync();
    final regex = RegExp(r'static const IconData ([a-zA-Z0-9_]+) =');
    final matches = regex.allMatches(content);
    for (final match in matches) {
      final name = match.group(1);
      if (name != null && !name.startsWith('_')) {
        output.writeln('  \'simple-$name\': SimpleIcons.$name,');
      }
    }
  }
  output.writeln('};');

  final outputFile = File('lib/features/editor/utils/icon_list.dart');
  outputFile.writeAsStringSync(output.toString());
  print('Generated ${outputFile.path}');
}
