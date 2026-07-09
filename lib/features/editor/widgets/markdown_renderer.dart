import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:munnin/features/editor/utils/custom_markdown_syntax.dart';

/// Widget responsable du rendu HTML à partir du Markdown brut.
class MarkdownRenderer extends StatelessWidget {
  /// Le texte brut en Markdown.
  final String content;
  
  final String? rootPath;
  
  /// Callback déclenché lorsqu'une case à cocher est cliquée.
  final void Function(int id, String newState)? onCheckboxToggled;

  const MarkdownRenderer({
    super.key,
    required this.content,
    this.rootPath,
    this.onCheckboxToggled,
  });

  @override
  Widget build(BuildContext context) {
    // 0. Pré-traitement pour intercepter les cases à cocher personnalisées
    int checkboxId = 0;
    final String preprocessedContent = content.replaceAllMapped(
      RegExp(r'^(\s*-\s+)\[([ xXvV\*])\]', multiLine: true), 
      (match) {
        final prefix = match.group(1)!;
        final state = match.group(2)!.toLowerCase();
        return '$prefix<munnin-checkbox id="${checkboxId++}" state="$state"></munnin-checkbox>';
      }
    );

    // 1. Conversion Markdown -> HTML
    final String htmlContent = md.markdownToHtml(
      preprocessedContent,
      extensionSet: md.ExtensionSet.gitHubWeb, // Support des tables, etc.
      inlineSyntaxes: [
        DoubleBangImageSyntax(), // Notre syntaxe custom !![]()
      ],
    );

    final theme = Theme.of(context);

    // 2. Rendu Flutter
    return SingleChildScrollView(
      child: Html(
        data: htmlContent,
        style: {
          "body": Style(
            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
            fontSize: FontSize(14.0),
            color: theme.textTheme.bodyMedium?.color,
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          "h1": Style(color: theme.colorScheme.primary),
          "h2": Style(color: theme.colorScheme.primary),
          "a": Style(
            color: theme.colorScheme.secondary,
            textDecoration: TextDecoration.none,
          ),
          "code": Style(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
            fontFamily: 'Consolas',
          ),
          "pre": Style(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            padding: HtmlPaddings.all(8),
            fontFamily: 'Consolas',
          ),
          "hr": Style(
            border: Border(bottom: BorderSide(color: theme.dividerColor, width: 2)),
            margin: Margins.symmetric(vertical: 16),
          ),
          "blockquote": Style(
            margin: Margins.symmetric(vertical: 8),
            padding: HtmlPaddings.symmetric(horizontal: 16, vertical: 8),
            border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            fontStyle: FontStyle.italic,
          ),
          ".task-list-item": Style(
            listStyleType: ListStyleType.none,
          ),
          "table": Style(
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 1),
            margin: Margins.only(bottom: 16.0),
            backgroundColor: theme.colorScheme.surface,
          ),
          "th": Style(
            padding: HtmlPaddings.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            border: Border(bottom: BorderSide(color: theme.dividerColor, width: 2)),
            fontWeight: FontWeight.bold,
          ),
          "td": Style(
            padding: HtmlPaddings.symmetric(horizontal: 16, vertical: 12),
            border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5), width: 1)),
          ),
        },
        extensions: [
          TagExtension(
            tagsToExtend: {"table"},
            builder: (extensionContext) {
              final element = extensionContext.element;
              if (element == null) return const SizedBox.shrink();

              final rows = element.getElementsByTagName("tr");
              if (rows.isEmpty) return const SizedBox.shrink();

              final tableRows = <TableRow>[];
              bool isEven = false;

              for (var row in rows) {
                final cells = row.children.where((e) => e.localName == 'td' || e.localName == 'th').toList();
                if (cells.isEmpty) continue;

                final tableCells = <Widget>[];
                for (var cell in cells) {
                  final isHeader = cell.localName == 'th';
                  
                  // Récupère l'alignement depuis l'attribut markdown généré
                  final alignAttr = cell.attributes['align'] ?? '';
                  final styleAttr = cell.attributes['style'] ?? '';
                  TextAlign textAlign = TextAlign.left;
                  if (alignAttr == 'right' || styleAttr.contains('right')) textAlign = TextAlign.right;
                  else if (alignAttr == 'center' || styleAttr.contains('center')) textAlign = TextAlign.center;

                  tableCells.add(
                    Container(
                      color: isHeader 
                          ? theme.colorScheme.surfaceContainerHighest
                          : (isEven ? theme.colorScheme.surfaceContainerLow : theme.colorScheme.surface),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      alignment: textAlign == TextAlign.center ? Alignment.center : (textAlign == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
                      child: DefaultTextStyle.merge(
                        textAlign: textAlign,
                        style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal),
                        child: Html(
                          data: cell.innerHtml,
                          // Applique les mêmes styles de base pour que les textes riches fonctionnent
                          style: {
                            "body": Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              textAlign: textAlign,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            "p": Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              textAlign: textAlign,
                            ),
                          },
                        ),
                      ),
                    ),
                  );
                }
                tableRows.add(TableRow(children: tableCells));
                
                // Alterne les couleurs uniquement après l'en-tête
                if (row.parent?.localName == 'tbody') {
                   isEven = !isEven;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Table(
                    border: TableBorder.all(
                      color: theme.scaffoldBackgroundColor, // Couleur de fond de page
                      width: 2,
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    // Colonnes qui prennent tout l'espace disponible
                    defaultColumnWidth: const FlexColumnWidth(1.0),
                    children: tableRows,
                  ),
                ),
              );
            },
          ),
          // Gère les checkboxes interactives pré-traitées
          TagExtension(
            tagsToExtend: {"munnin-checkbox"},
            builder: (extensionContext) {
              final idStr = extensionContext.attributes['id'];
              final state = extensionContext.attributes['state'] ?? ' ';
              final id = int.tryParse(idStr ?? '') ?? -1;

              IconData iconData;
              Color iconColor;

              if (state == 'v') {
                iconData = Icons.check_box;
                iconColor = Colors.green;
              } else if (state == 'x') {
                iconData = Icons.disabled_by_default; // Case pleine avec croix
                iconColor = Colors.red;
              } else if (state == '*') {
                iconData = Icons.disabled_by_default;
                iconColor = theme.colorScheme.primary;
              } else {
                iconData = Icons.check_box_outline_blank;
                iconColor = theme.colorScheme.primary;
              }

              return GestureDetector(
                onTap: () {
                  if (onCheckboxToggled != null) {
                    onCheckboxToggled!(id, state == '*' ? ' ' : '*');
                  }
                },
                onDoubleTap: () {
                  if (onCheckboxToggled != null) {
                    onCheckboxToggled!(id, state == 'v' ? ' ' : 'v');
                  }
                },
                onSecondaryTap: () {
                  if (onCheckboxToggled != null) {
                    onCheckboxToggled!(id, state == 'x' ? ' ' : 'x');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Icon(
                      iconData,
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                ),
              );
            },
          ),
          // Gère notre balise <munnin-img> générée par le parser
          TagExtension(
            tagsToExtend: {"munnin-img"},
            builder: (extensionContext) {
              final src = extensionContext.attributes['src'] ?? '';
              final alt = extensionContext.attributes['alt'] ?? '';

              // Par exemple, on peut afficher une boîte spéciale avec une bordure
              // ou un bouton pour "télécharger l'image".
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.tertiary, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.download, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Image spéciale : $alt\n($src)',
                        style: TextStyle(color: theme.colorScheme.tertiary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Gère les images standards markdown
          TagExtension(
            tagsToExtend: {"img"},
            builder: (extensionContext) {
              final src = extensionContext.attributes['src'];
              final alt = extensionContext.attributes['alt'] ?? '';
              return _buildImageWidget(src, alt, theme);
            },
          ),
        ],
        onLinkTap: (url, attributes, element) async {
          if (url == null) return;
          
          // Vérifie si c'est un lien web classique ou un lien de fichier explicite
          if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('file://')) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          } 
          // Vérifie si c'est un chemin absolu Windows (ex: C:\Dossier ou \\Serveur\Dossier)
          else if (url.contains(RegExp(r'^[a-zA-Z]:\\')) || url.startsWith(r'\\')) {
            final uri = Uri.file(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          } 
          // Sinon c'est probablement un lien wiki interne (relatif)
          else {
            print("Lien wiki interne (à gérer plus tard) : $url");
          }
        },
      ),
    );
  }

  Widget _buildImageWidget(String? src, String alt, ThemeData theme) {
    if (src == null || src.isEmpty) {
      return const SizedBox.shrink();
    }

    // Image Web
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(src, errorBuilder: (context, error, stackTrace) => _buildErrorImage(src, theme));
    }

    // Image locale
    String imagePath = src;
    if (rootPath != null && !File(src).isAbsolute && !src.startsWith('file://')) {
      // Si on a un chemin racine, on résout le chemin relatif proprement
      final parentDir = File(rootPath!).parent.path;
      // Ajoute le séparateur à la fin pour que Uri.resolve fonctionne comme un dossier
      final dirUri = Uri.file(parentDir + Platform.pathSeparator);
      imagePath = dirUri.resolve(src).toFilePath();
    } else if (src.startsWith('file://')) {
      imagePath = Uri.parse(src).toFilePath();
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(file, errorBuilder: (context, error, stackTrace) => _buildErrorImage(src, theme));
    } else {
      return _buildErrorImage(src, theme);
    }
  }

  Widget _buildErrorImage(String src, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.error),
        borderRadius: BorderRadius.circular(4),
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Text(
            "Image introuvable : $src",
            style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
