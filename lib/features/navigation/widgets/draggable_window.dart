import 'package:flutter/material.dart';
import 'dart:math';

class DraggableWindow extends StatefulWidget {
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final double initialWidth;
  final double initialHeight;

  const DraggableWindow({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.initialWidth = 800,
    this.initialHeight = 600,
  });

  @override
  State<DraggableWindow> createState() => _DraggableWindowState();
}

class _DraggableWindowState extends State<DraggableWindow> {
  late double _top;
  late double _left;
  late double _width;
  late double _height;
  bool _isMaximized = false;

  // Sauvegarde des dimensions avant de maximiser
  late double _prevTop;
  late double _prevLeft;
  late double _prevWidth;
  late double _prevHeight;

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      _width = min(widget.initialWidth, size.width * 0.9);
      _height = min(widget.initialHeight, size.height * 0.9);
      // Centrer par défaut
      _top = max(0.0, (size.height - _height) / 2);
      _left = max(0.0, (size.width - _width) / 2);
      _isInitialized = true;
    }
  }

  void _toggleMaximize() {
    setState(() {
      if (_isMaximized) {
        // Restaurer
        _top = _prevTop;
        _left = _prevLeft;
        _width = _prevWidth;
        _height = _prevHeight;
        _isMaximized = false;
      } else {
        // Sauvegarder
        _prevTop = _top;
        _prevLeft = _left;
        _prevWidth = _width;
        _prevHeight = _height;

        // Maximiser (on prend toute la taille du Stack parent)
        final size = MediaQuery.of(context).size;
        _top = 0;
        _left = 0;
        _width = size.width;
        _height = size.height;
        _isMaximized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      top: _top,
      left: _left,
      width: _width,
      height: _height,
      child: Material(
        elevation: _isMaximized ? 0 : 12,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(_isMaximized ? 0 : 8),
            border: _isMaximized
                ? null
                : Border.all(color: theme.dividerColor, width: 1),
            boxShadow: _isMaximized
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: Column(
            children: [
              // Barre de titre avec Drag
              GestureDetector(
                onPanUpdate: _isMaximized
                    ? null
                    : (details) {
                        setState(() {
                          _top += details.delta.dy;
                          _left += details.delta.dx;
                        });
                      },
                onDoubleTap: _toggleMaximize,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_isMaximized ? 0 : 8),
                    ),
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 16,
                        icon: Icon(
                          _isMaximized
                              ? Icons.close_fullscreen
                              : Icons.crop_square,
                        ),
                        onPressed: _toggleMaximize,
                        tooltip: _isMaximized ? 'Restaurer' : 'Agrandir',
                      ),
                      IconButton(
                        iconSize: 16,
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                        tooltip: 'Fermer',
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              // Contenu principal + Resize handle
              Expanded(
                child: Stack(
                  children: [
                    // Le contenu de la fenêtre
                    Positioned.fill(child: widget.child),

                    // Zone de redimensionnement (coin en bas à droite)
                    if (!_isMaximized)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _width = max(300.0, _width + details.delta.dx);
                              _height = max(200.0, _height + details.delta.dy);
                            });
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeUpLeftDownRight,
                            child: Container(
                              width: 16,
                              height: 16,
                              color: Colors
                                  .transparent, // Invisible mais cliquable
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
