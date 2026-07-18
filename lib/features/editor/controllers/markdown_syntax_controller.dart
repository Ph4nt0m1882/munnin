import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:munnin/features/editor/services/editor_manager.dart';
import 'package:munnin/features/editor/services/link_preview_manager.dart';

class MarkdownSyntaxController extends TextEditingController {
  String? _hoveredUrl;

  String? _exitingUrl;

  MarkdownSyntaxController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final textStr = text;
    final currentFilePath = EditorManager.instance.activeFilePath ?? '';

    // Regex for HTTP links: http(s)://...
    // Regex for Markdown links: [title](url)
    // We will combine them or just parse sequentially.
    // To keep it simple, let's find Markdown links and plain HTTP links.
    final regex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)|https?:\/\/[^\s]+');
    final matches = regex.allMatches(textStr);

    if (matches.isEmpty) {
      return TextSpan(text: textStr, style: style);
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: textStr.substring(lastMatchEnd, match.start),
            style: style,
          ),
        );
      }

      final isMarkdownLink = match.group(1) != null;
      final fullMatch = match.group(0)!;
      final url = isMarkdownLink ? match.group(2)! : fullMatch;

      final isHovered = _hoveredUrl == url;

      spans.add(
        TextSpan(
          text: fullMatch,
          style: style?.copyWith(
            color: Colors.blue,
            decoration: isHovered
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
          onEnter: (PointerEnterEvent event) {
            _exitingUrl = null;
            if (_hoveredUrl != url) {
              _hoveredUrl = url;
              notifyListeners(); // Rebuild to show underline
              LinkPreviewManager().show(
                context,
                url,
                event.position,
                currentFilePath,
              );
            }
          },
          onExit: (PointerExitEvent event) async {
            final exitingUrl = url;
            _exitingUrl = exitingUrl;

            await Future.delayed(const Duration(milliseconds: 10));

            if (_exitingUrl == exitingUrl && _hoveredUrl == exitingUrl) {
              _hoveredUrl = null;
              notifyListeners(); // Rebuild to hide underline
              LinkPreviewManager().hide();
            }
          },
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < textStr.length) {
      spans.add(TextSpan(text: textStr.substring(lastMatchEnd), style: style));
    }

    return TextSpan(children: spans, style: style);
  }
}
