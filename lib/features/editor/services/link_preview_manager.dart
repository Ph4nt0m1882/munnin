import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:io';
import 'package:path/path.dart' as p;

class LinkMetadata {
  final String title;
  final String description;
  final String? imageUrl;
  final bool isLocal;

  LinkMetadata({
    required this.title,
    required this.description,
    this.imageUrl,
    this.isLocal = false,
  });
}

class LinkPreviewManager {
  static final LinkPreviewManager _instance = LinkPreviewManager._internal();
  factory LinkPreviewManager() => _instance;
  LinkPreviewManager._internal();

  OverlayEntry? _overlayEntry;
  final Map<String, LinkMetadata> _cache = {};

  void show(
    BuildContext context,
    String url,
    Offset position,
    String currentFilePath,
  ) {
    hide(); // Hide any existing preview

    _overlayEntry = OverlayEntry(
      builder: (context) =>
          _buildOverlayContent(context, url, position, currentFilePath),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlayContent(
    BuildContext context,
    String url,
    Offset position,
    String currentFilePath,
  ) {
    // Determine screen size to avoid overflowing
    final size = MediaQuery.of(context).size;

    // Default offset relative to the cursor
    double left = position.dx + 15;
    double top = position.dy + 20;

    // Fixed card size
    const double cardWidth = 300;
    const double cardHeight = 250;

    // Adjust if overflowing right
    if (left + cardWidth > size.width) {
      left = position.dx - cardWidth - 15;
    }

    // Adjust if overflowing bottom
    if (top + cardHeight > size.height) {
      top = position.dy - cardHeight - 20;
    }

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: IgnorePointer(
          // Ignore pointer so it doesn't block clicks to the editor
          child: FutureBuilder<LinkMetadata>(
            future: _fetchMetadata(url, currentFilePath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildCard(
                  context,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return const SizedBox.shrink(); // Hide silently on error
              } else if (snapshot.hasData) {
                final data = snapshot.data!;
                return _buildCard(
                  context,
                  child: _buildPreviewCard(context, data, url),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: 300, child: child),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    LinkMetadata data,
    String url,
  ) {
    final theme = Theme.of(context);

    Widget imageWidget = const SizedBox.shrink();
    if (data.imageUrl != null && data.imageUrl!.isNotEmpty) {
      final isDirectImage =
          data.description == 'Image web' || data.description == 'Image locale';
      final boxFit = isDirectImage ? BoxFit.contain : BoxFit.cover;

      if (data.isLocal) {
        imageWidget = Container(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          child: Image.file(
            File(data.imageUrl!),
            width: double.infinity,
            height: 140,
            fit: boxFit,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 140,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.broken_image, size: 40)),
            ),
          ),
        );
      } else {
        imageWidget = Container(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          child: Image.network(
            data.imageUrl!,
            width: double.infinity,
            height: 140,
            fit: boxFit,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 140,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.broken_image, size: 40)),
            ),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.imageUrl != null && data.imageUrl!.isNotEmpty) imageWidget,
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                data.description.isNotEmpty ? data.description : url,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<LinkMetadata> _fetchMetadata(
    String url,
    String currentFilePath,
  ) async {
    if (_cache.containsKey(url)) {
      return _cache[url]!;
    }

    LinkMetadata metadata;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      final lowerUrl = url.toLowerCase();
      final isWebImage =
          lowerUrl.endsWith('.png') ||
          lowerUrl.endsWith('.jpg') ||
          lowerUrl.endsWith('.jpeg') ||
          lowerUrl.endsWith('.gif') ||
          lowerUrl.endsWith('.webp');

      if (isWebImage) {
        String filename = url;
        try {
          filename = Uri.parse(url).pathSegments.last;
        } catch (e) {
          // ignore
        }

        metadata = LinkMetadata(
          title: filename,
          description: 'Image web',
          imageUrl: url,
        );
      } else {
        try {
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 3));
          if (response.statusCode == 200) {
            final document = parse(response.body);

            String title =
                _getMetaContent(document, 'og:title') ??
                document.querySelector('title')?.text ??
                url;
            String description =
                _getMetaContent(document, 'og:description') ??
                _getMetaContent(document, 'description') ??
                '';
            String? imageUrl = _getMetaContent(document, 'og:image');

            // Convert relative image URLs to absolute
            if (imageUrl != null && imageUrl.startsWith('/')) {
              final uri = Uri.parse(url);
              imageUrl = '${uri.scheme}://${uri.host}$imageUrl';
            }

            metadata = LinkMetadata(
              title: title,
              description: description,
              imageUrl: imageUrl,
            );
          } else {
            metadata = LinkMetadata(
              title: url,
              description: 'Statut: ${response.statusCode}',
            );
          }
        } catch (e) {
          metadata = LinkMetadata(
            title: url,
            description: 'Impossible de prévisualiser ce lien.',
          );
        }
      }
    } else {
      // Local link
      try {
        final dir = p.dirname(currentFilePath);
        final targetPath = p.normalize(p.join(dir, url));
        final file = File(targetPath);

        if (await file.exists()) {
          final isImage =
              targetPath.toLowerCase().endsWith('.png') ||
              targetPath.toLowerCase().endsWith('.jpg') ||
              targetPath.toLowerCase().endsWith('.jpeg') ||
              targetPath.toLowerCase().endsWith('.gif') ||
              targetPath.toLowerCase().endsWith('.webp');

          metadata = LinkMetadata(
            title: p.basename(targetPath),
            description: isImage ? 'Image locale' : 'Fichier local',
            imageUrl: isImage ? targetPath : null,
            isLocal: true,
          );
        } else {
          metadata = LinkMetadata(
            title: url,
            description: 'Fichier introuvable',
          );
        }
      } catch (e) {
        metadata = LinkMetadata(title: url, description: 'Lien local invalide');
      }
    }

    _cache[url] = metadata;
    return metadata;
  }

  String? _getMetaContent(dynamic document, String property) {
    var meta = document.querySelector('meta[property="$property"]');
    if (meta != null) return meta.attributes['content'];

    meta = document.querySelector('meta[name="$property"]');
    if (meta != null) return meta.attributes['content'];

    return null;
  }
}
