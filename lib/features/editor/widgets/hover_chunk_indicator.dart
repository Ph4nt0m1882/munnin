import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

class HoverCodeChunkIndicator extends StatefulWidget {
  final CodeChunkController controller;
  final CodeIndicatorValueNotifier notifier;

  const HoverCodeChunkIndicator({
    super.key,
    required this.controller,
    required this.notifier,
  });

  @override
  State<HoverCodeChunkIndicator> createState() =>
      _HoverCodeChunkIndicatorState();
}

class _HoverCodeChunkIndicatorState extends State<HoverCodeChunkIndicator> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: DefaultCodeChunkIndicator(
        width: 20,
        controller: widget.controller,
        notifier: widget.notifier,
        painter: _HoverChunkIndicatorPainter(
          isHovering: _isHovering,
          color: Colors.grey.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _HoverChunkIndicatorPainter implements CodeChunkIndicatorPainter {
  final bool isHovering;
  final Color color;
  final Size size;

  late final Paint _paint;

  _HoverChunkIndicatorPainter({required this.isHovering, required this.color})
    : size = const Size(7, 7) {
    _paint = Paint()..color = color;
  }

  @override
  void paintCollapseIndicator(Canvas canvas, Size container) {
    // Only show collapse indicator when hovering
    if (!isHovering || container.isEmpty) {
      return;
    }
    final Path path = Path();
    path.moveTo(
      (container.width - size.width) / 2,
      (container.height - size.height) / 2,
    );
    path.lineTo(
      (container.width + size.width) / 2,
      (container.height - size.height) / 2,
    );
    path.lineTo(container.width / 2, (container.height + size.height) / 2);
    path.lineTo(
      (container.width - size.width) / 2,
      (container.height - size.height) / 2,
    );
    canvas.drawPath(path, _paint);
  }

  @override
  void paintExpandIndicator(Canvas canvas, Size container) {
    // Always show expand indicator when folded
    if (container.isEmpty) {
      return;
    }
    final Path path = Path();
    path.moveTo(
      (container.width - size.width) / 2,
      (container.height - size.height) / 2,
    );
    path.lineTo((container.width + size.width) / 2, container.height / 2);
    path.lineTo(
      (container.width - size.width) / 2,
      (container.height + size.height) / 2,
    );
    path.lineTo(
      (container.width - size.width) / 2,
      (container.height - size.height) / 2,
    );
    canvas.drawPath(path, _paint);
  }
}
