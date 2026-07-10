import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:munnin/features/editor/editor.dart';
import 'package:munnin/features/editor/widgets/icon_picker_widget.dart';
import 'package:munnin/features/editor/widgets/editor_toolbar.dart';

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({super.key});

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    EditorManager.instance.addListener(_onEditorStateChanged);
    _syncController();
  }

  @override
  void dispose() {
    EditorManager.instance.removeListener(_onEditorStateChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onEditorStateChanged() {
    _syncController();
    if (mounted) setState(() {});
  }

  void _syncController() {
    final activeFile = EditorManager.instance.activeFile;
    if (activeFile != null) {
      if (_textController.text != activeFile.content) {
        // Sauvegarde la position du curseur
        final selection = _textController.selection;
        _textController.text = activeFile.content;
        
        // Restaure si possible
        if (selection.isValid && selection.end <= _textController.text.length) {
          _textController.selection = selection;
        }
      }
    } else {
      _textController.clear();
    }
  }

  void _onContentChanged(String newText) {
    final activePath = EditorManager.instance.activeFilePath;
    if (activePath != null) {
      EditorManager.instance.updateFileContent(activePath, newText);
    }
  }

  void _insertText(String text) {
    final selection = _textController.selection;
    if (selection.start >= 0) {
      final newText = _textController.text.replaceRange(selection.start, selection.end, text);
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + text.length),
      );
      _onContentChanged(newText);
    } else {
      final newText = _textController.text + text;
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      _onContentChanged(newText);
    }
  }

  void _openIconPicker() {
    IconPickerWidget.show(context, (iconName, library) {
      _insertText(iconName);
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
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Global Editor Toolbar (always visible above tabs)
        EditorToolbar(
          onIconPickerPressed: _openIconPicker,
        ),
        
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
                ? MarkdownRenderer(
                    content: manager.activeFile?.content ?? '',
                    filePath: manager.activeFilePath,
                    onCheckboxToggled: (id, newState) async {
                      final activePath = manager.activeFilePath;
                      if (activePath == null) return;
                      final memoryContent = manager.activeFile?.content ?? '';
                      
                      final regExp = RegExp(r'^(\s*-\s+)\[([ xXvV\*])\]', multiLine: true);
                      final matches = regExp.allMatches(memoryContent).toList();
                      
                      if (id >= 0 && id < matches.length) {
                        final memMatch = matches[id];
                        final prefix = memMatch.group(1)!;
                        
                        // Calcul de la ligne exacte
                        int lineStart = memoryContent.lastIndexOf('\n', memMatch.start);
                        lineStart = lineStart == -1 ? 0 : lineStart + 1;
                        int lineEnd = memoryContent.indexOf('\n', memMatch.end);
                        if (lineEnd == -1) lineEnd = memoryContent.length;
                        final originalLine = memoryContent.substring(lineStart, lineEnd);
                        
                        int lineNumber = '\n'.allMatches(memoryContent.substring(0, memMatch.start)).length;

                        final wasDirty = manager.activeFile?.isDirty ?? false;

                        // Remplacement en mémoire
                        final newMemoryContent = memoryContent.replaceRange(memMatch.start, memMatch.end, '$prefix[$newState]');
                        EditorManager.instance.updateFileContent(activePath, newMemoryContent);
                        
                        // Tentative de sauvegarde silencieuse sur le disque
                        try {
                          final file = File(activePath);
                          if (await file.exists()) {
                            if (!wasDirty) {
                              // Le fichier n'avait aucune autre modification. On sauvegarde tout et on efface l'astérisque.
                              await file.writeAsString(newMemoryContent);
                              EditorManager.instance.markAsClean(activePath);
                            } else {
                              // Le fichier a d'autres modifications en cours. Sauvegarde partielle de la ligne uniquement.
                              final diskContent = await file.readAsString();
                              List<String> diskLines = diskContent.split('\n');
                              
                              if (lineNumber < diskLines.length) {
                                String cleanDiskLine = diskLines[lineNumber].replaceAll('\r', '');
                                String cleanOriginalLine = originalLine.replaceAll('\r', '');
                                
                                // Si la ligne correspond exactement, on remplace sur le disque
                                if (cleanDiskLine == cleanOriginalLine) {
                                  bool hasCr = diskLines[lineNumber].endsWith('\r');
                                  String newLine = cleanOriginalLine.replaceFirst(
                                    RegExp(r'\[([ xXvV\*])\]'), 
                                    '[$newState]'
                                  );
                                  if (hasCr) newLine += '\r';
                                  
                                  diskLines[lineNumber] = newLine;
                                  await file.writeAsString(diskLines.join('\n'));
                                }
                              }
                            }
                          }
                        } catch (e) {
                          print("Erreur de sauvegarde silencieuse: $e");
                        }
                      }
                    },
                  )
              : CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.keyI, control: true, shift: true): _openIconPicker,
                  },
                  child: Focus(
                    autofocus: true,
                    child: TextField(
                      controller: _textController,
                      onChanged: _onContentChanged,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Consolas', // Police monospaced pour markdown (à peaufiner plus tard)
                        fontSize: 14,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
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
    final bgColor = isActive ? theme.scaffoldBackgroundColor : theme.colorScheme.surface;
    final textColor = isActive ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodySmall?.color;
    
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
