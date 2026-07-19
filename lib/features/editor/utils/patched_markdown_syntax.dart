import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/languages/markdown.dart';

/// Returns a patched version of the markdown language definition
/// that fixes the bug where code blocks are misidentified as Setext headers
/// if they are immediately followed by `---`.
Mode getPatchedMarkdownSyntax() {
  final Mode patched = langMarkdown;

  if (patched.contains != null) {
    // Add custom syntax for WikiLinks and Footnotes at the beginning
    patched.contains!.insertAll(0, [
      Mode(
        className: 'symbol', // purple in Monokai
        begin: r'\[\[',
        end: r'\]\]',
        relevance: 0,
      ),
      Mode(
        className: 'type', // light blue in Monokai
        begin: r'\[\^',
        end: r'\]',
        relevance: 0,
      ),
    ]);

    for (var i = 0; i < patched.contains!.length; i++) {
      final mode = patched.contains![i];
      if (mode.className == 'section' && mode.variants != null) {
        for (var variant in mode.variants!) {
          if (variant.begin is String &&
              (variant.begin as String).startsWith('(?=^.+?\\n[=-]{2,}')) {
            // Modify the regex so the line must not start with a fenced code block (3+ backticks or tildes)
            // This allows inline code (1 or 2 backticks) in Setext headers.
            variant.begin = "(?=^(?!`{3,}|~{3,}).+?\\n[=-]{2,}\$)";
          }
        }
      }
    }
  }

  return patched;
}
