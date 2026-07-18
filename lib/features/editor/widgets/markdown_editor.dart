import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:munnin/features/editor/editor.dart';
import 'package:munnin/features/editor/widgets/icon_picker_widget.dart';
import 'package:munnin/features/editor/widgets/editor_toolbar.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/styles/monokai-sublime.dart';
import 'package:munnin/features/editor/utils/markdown_chunk_analyzer.dart';
import 'package:munnin/features/editor/widgets/hover_chunk_indicator.dart';
import 'package:munnin/features/editor/utils/patched_markdown_syntax.dart';
import 'package:munnin/features/editor/widgets/local_search_widget.dart';
import 'package:munnin/core/commands/commands.dart';

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({super.key});

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late CodeLineEditingController _textController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController = CodeLineEditingController.fromText('');
    // Listen for code changes internally
    _textController.addListener(_onCodeChanged);

    EditorManager.instance.addListener(_onEditorStateChanged);
    _syncController();
  }

  @override
  void dispose() {
    EditorManager.instance.removeListener(_onEditorStateChanged);
    _textController.removeListener(_onCodeChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onEditorStateChanged() {
    _syncController();
    if (mounted) setState(() {});
  }

  void _onCodeChanged() {
    final activePath = EditorManager.instance.activeFilePath;
    if (activePath != null) {
      if (_textController.text != EditorManager.instance.activeFile?.content) {
        EditorManager.instance.updateFileContent(
          activePath,
          _textController.text,
        );
      }
    }
  }

  CodeLineSelection _getSelectionFromOffsets(int start, int end) {
    final lines = _textController.codeLines;
    int currentOffset = 0;

    int baseIndex = 0;
    int baseOffset = 0;
    int extentIndex = 0;
    int extentOffset = 0;

    for (int i = 0; i < lines.length; i++) {
      final lineLength = lines[i].text.length + 1; // +1 pour le \n

      if (start >= currentOffset && start < currentOffset + lineLength) {
        baseIndex = i;
        baseOffset = start - currentOffset;
      }

      if (end >= currentOffset && end <= currentOffset + lineLength) {
        extentIndex = i;
        extentOffset = end - currentOffset;
        if (extentOffset == lineLength) {
          extentOffset = lines[i].text.length;
        }
      }
      currentOffset += lineLength;
    }

    return CodeLineSelection(
      baseIndex: baseIndex,
      baseOffset: baseOffset,
      extentIndex: extentIndex,
      extentOffset: extentOffset,
    );
  }

  void _syncController() {
    final activeFile = EditorManager.instance.activeFile;
    if (activeFile != null) {
      if (_textController.text != activeFile.content) {
        _textController.text = activeFile.content;
      }

      if (activeFile.teleportTarget != null) {
        final target = activeFile.teleportTarget!;
        activeFile.teleportTarget = null; // On consomme la cible

        // On attend la prochaine frame pour que le layout soit fait
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _textController.selection = _getSelectionFromOffsets(
              target.startOffset,
              target.endOffset,
            );
          }
        });
      }
    } else {
      _textController.text = '';
    }
  }

  void _insertText(String textToInsert) {
    final selection = _textController.value.selection;
    if (selection.baseIndex >= 0 && selection.extentIndex >= 0) {
      final lines = _textController.codeLines;

      int absoluteBase = 0;
      for (int i = 0; i < selection.baseIndex; i++) {
        absoluteBase += lines[i].text.length + 1;
      }
      absoluteBase += selection.baseOffset;

      int absoluteExtent = 0;
      for (int i = 0; i < selection.extentIndex; i++) {
        absoluteExtent += lines[i].text.length + 1;
      }
      absoluteExtent += selection.extentOffset;

      final start = absoluteBase < absoluteExtent
          ? absoluteBase
          : absoluteExtent;
      final end = absoluteBase > absoluteExtent ? absoluteBase : absoluteExtent;

      final currentText = _textController.text;
      if (start >= 0 && end <= currentText.length) {
        final newText = currentText.replaceRange(start, end, textToInsert);
        _textController.text = newText;
      }
    } else {
      final newText = _textController.text + textToInsert;
      _textController.text = newText;
    }
  }

  void _openIconPicker() {
    IconPickerWidget.show(context, (iconName, library) {
      final currentPosition = _textController.selection.baseOffset;

      final content = (library == 'symbol' || library == 'emoji')
          ? iconName
          : ':$library-$iconName:';

      if (currentPosition >= 0) {
        _insertText(content);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = EditorManager.instance;
    final openedFiles = manager.openedFiles;

    if (openedFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_document, size: 64, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              'Aucun fichier ouvert',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Global Editor Toolbar (always visible above tabs)
        EditorToolbar(onIconPickerPressed: _openIconPicker),

        // Tabs
        Container(
          height: 40,
          color: theme.colorScheme.surface,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: openedFiles.length,
            itemBuilder: (context, index) {
              final file = openedFiles[index];
              final isActive = file.path == manager.activeFilePath;

              return _EditorTab(
                file: file,
                isActive: isActive,
                onTap: () => manager.openFile(file.path),
                onClose: () => manager.closeFile(file.path),
              );
            },
          ),
        ),

        // Editor Area
        Expanded(
          child: Material(
            color: theme.scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: manager.activeFile?.mode == EditorMode.render
                  ? CallbackShortcuts(
                      bindings: {
                        const SingleActivator(
                          LogicalKeyboardKey.keyF,
                          control: true,
                        ): () {
                          CommandManager.instance.execute(
                            'app.command_palette',
                          );
                        },
                      },
                      child: Focus(
                        autofocus: true,
                        child: MarkdownRenderer(
                          content: manager.activeFile?.content ?? '',
                          filePath: manager.activeFilePath,
                          onCheckboxToggled: (id, newState) async {
                            final activePath = manager.activeFilePath;
                            if (activePath == null) return;
                            final memoryContent =
                                manager.activeFile?.content ?? '';

                            final regExp = RegExp(
                              r'^(\s*-\s+)\[([ xXvV\*])\]',
                              multiLine: true,
                            );
                            final matches = regExp
                                .allMatches(memoryContent)
                                .toList();
                            if (id >= 0 && id < matches.length) {
                              final memMatch = matches[id];
                              final prefix = memMatch.group(1)!;

                              // Calcul de la ligne exacte
                              int lineStart = memoryContent.lastIndexOf(
                                '\n',
                                memMatch.start,
                              );
                              lineStart = lineStart == -1 ? 0 : lineStart + 1;
                              int lineEnd = memoryContent.indexOf(
                                '\n',
                                memMatch.end,
                              );
                              if (lineEnd == -1) lineEnd = memoryContent.length;
                              final originalLine = memoryContent.substring(
                                lineStart,
                                lineEnd,
                              );

                              int lineNumber = '\n'
                                  .allMatches(
                                    memoryContent.substring(0, memMatch.start),
                                  )
                                  .length;

                              final wasDirty =
                                  manager.activeFile?.isDirty ?? false;

                              // Remplacement en mémoire
                              final newMemoryContent = memoryContent
                                  .replaceRange(
                                    memMatch.start,
                                    memMatch.end,
                                    '$prefix[$newState]',
                                  );
                              EditorManager.instance.updateFileContent(
                                activePath,
                                newMemoryContent,
                              );

                              // Tentative de sauvegarde silencieuse sur le disque
                              try {
                                final file = File(activePath);
                                if (await file.exists()) {
                                  if (!wasDirty) {
                                    // Le fichier n'avait aucune autre modification. On sauvegarde tout et on efface l'astérisque.
                                    await file.writeAsString(newMemoryContent);
                                    EditorManager.instance.markAsClean(
                                      activePath,
                                    );
                                  } else {
                                    // Le fichier a d'autres modifications en cours. Sauvegarde partielle de la ligne uniquement.
                                    final diskContent = await file
                                        .readAsString();
                                    List<String> diskLines = diskContent.split(
                                      '\n',
                                    );

                                    if (lineNumber < diskLines.length) {
                                      String cleanDiskLine =
                                          diskLines[lineNumber].replaceAll(
                                            '\r',
                                            '',
                                          );
                                      String cleanOriginalLine = originalLine
                                          .replaceAll('\r', '');

                                      // Si la ligne correspond exactement, on remplace sur le disque
                                      if (cleanDiskLine == cleanOriginalLine) {
                                        bool hasCr = diskLines[lineNumber]
                                            .endsWith('\r');
                                        String newLine = cleanOriginalLine
                                            .replaceFirst(
                                              RegExp(r'\[([ xXvV\*])\]'),
                                              '[$newState]',
                                            );
                                        if (hasCr) newLine += '\r';

                                        diskLines[lineNumber] = newLine;
                                        await file.writeAsString(
                                          diskLines.join('\n'),
                                        );
                                      }
                                    }
                                  }
                                }
                              } catch (e) {
                                debugPrint(
                                  "Erreur de sauvegarde silencieuse: $e",
                                );
                              }
                            }
                          },
                        ),
                      ),
                    )
                  : CallbackShortcuts(
                      bindings: {
                        const SingleActivator(
                          LogicalKeyboardKey.keyI,
                          control: true,
                          shift: true,
                        ): _openIconPicker,
                      },
                      child: Focus(
                        autofocus: true,
                        child: CodeEditor(
                          controller: _textController,
                          style: CodeEditorStyle(
                            fontFamily: 'Consolas',
                            fontSize: 14,
                            fontHeight: 1.5,
                            codeTheme: CodeHighlightTheme(
                              languages: {
                                'markdown': CodeHighlightThemeMode(
                                  mode: getPatchedMarkdownSyntax(),
                                ),
                              },
                              theme: monokaiSublimeTheme,
                            ),
                          ),
                          wordWrap: true,
                          indicatorBuilder:
                              (
                                context,
                                editingController,
                                chunkController,
                                notifier,
                              ) {
                                return Row(
                                  children: [
                                    DefaultCodeLineNumber(
                                      controller: editingController,
                                      notifier: notifier,
                                    ),
                                    HoverCodeChunkIndicator(
                                      controller: chunkController,
                                      notifier: notifier,
                                    ),
                                  ],
                                );
                              },
                          chunkAnalyzer: const MarkdownChunkAnalyzer(),
                          findBuilder: (context, controller, readOnly) =>
                              LocalSearchWidget(
                                controller: controller,
                                readOnly: readOnly,
                              ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorTab extends StatelessWidget {
  final OpenedFile file;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _EditorTab({
    required this.file,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isActive
        ? theme.scaffoldBackgroundColor
        : theme.colorScheme.surface;
    final textColor = isActive
        ? theme.textTheme.bodyLarge?.color
        : theme.textTheme.bodySmall?.color;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            right: BorderSide(color: theme.dividerColor, width: 1),
            top: BorderSide(
              color: isActive ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône de mode
            InkWell(
              onTap: () {
                final newMode = file.mode == EditorMode.markdown
                    ? EditorMode.render
                    : EditorMode.markdown;
                EditorManager.instance.setFileMode(file.path, newMode);
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(
                  file.mode == EditorMode.render ? Icons.preview : Icons.code,
                  size: 14,
                  color: textColor?.withValues(alpha: 0.8),
                ),
              ),
            ),
            // Nom du fichier
            Text(
              file.name + (file.isDirty ? ' *' : ''),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontStyle: file.isDirty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(width: 8),
            // Bouton fermer
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: textColor?.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
