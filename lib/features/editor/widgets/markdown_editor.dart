import 'package:flutter/material.dart';
import 'package:munnin/features/editor/editor.dart';

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
          child: Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
            Text(
              file.name + (file.isDirty ? ' *' : ''),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontStyle: file.isDirty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            const SizedBox(width: 8),
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
