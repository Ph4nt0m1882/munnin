import 'package:re_editor/re_editor.dart';

class MarkdownChunkAnalyzer implements CodeChunkAnalyzer {
  const MarkdownChunkAnalyzer();

  @override
  List<CodeChunk> run(CodeLines codeLines) {
    final List<CodeChunk> chunks = [];
    final List<int> detailsStack = [];
    int? codeBlockStart;

    // A map to store the open header lines by their level
    final Map<int, int> openHeaders = {};

    for (int i = 0; i < codeLines.length; i++) {
      final String line = codeLines[i].text.trim();

      // 1. Code blocks ```
      if (line.startsWith('```')) {
        if (codeBlockStart == null) {
          codeBlockStart = i;
        } else {
          chunks.add(CodeChunk(codeBlockStart, i));
          codeBlockStart = null;
        }
        continue; // Don't parse markdown inside code blocks
      }

      if (codeBlockStart != null) continue;

      // 2. <details> tags
      if (line.startsWith('<details>')) {
        detailsStack.add(i);
      } else if (line.startsWith('</details>')) {
        if (detailsStack.isNotEmpty) {
          final start = detailsStack.removeLast();
          chunks.add(CodeChunk(start, i));
        }
      }

      // 3. Headings #
      if (line.startsWith('#')) {
        final match = RegExp(r'^(#+)\s').firstMatch(line);
        if (match != null) {
          final level = match.group(1)!.length;

          // Close all open headers that have the same or higher level (i.e. number is same or greater)
          final keysToClose = openHeaders.keys
              .where((k) => k >= level)
              .toList();
          for (final key in keysToClose) {
            final startLine = openHeaders.remove(key)!;
            // The chunk ends at the line before this new heading
            if (i - 1 > startLine) {
              chunks.add(CodeChunk(startLine, i - 1));
            }
          }

          openHeaders[level] = i;
        }
      }
    }

    // Close any remaining headers at the end of the file
    for (final startLine in openHeaders.values) {
      if (codeLines.length - 1 > startLine) {
        chunks.add(CodeChunk(startLine, codeLines.length - 1));
      }
    }

    // Close any remaining details tags
    for (final startLine in detailsStack) {
      if (codeLines.length - 1 > startLine) {
        chunks.add(CodeChunk(startLine, codeLines.length - 1));
      }
    }

    if (codeBlockStart != null && codeLines.length - 1 > codeBlockStart) {
      chunks.add(CodeChunk(codeBlockStart, codeLines.length - 1));
    }

    return chunks;
  }
}
