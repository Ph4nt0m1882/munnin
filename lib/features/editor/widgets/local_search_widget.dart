import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

class LocalSearchWidget extends StatelessWidget implements PreferredSizeWidget {
  final CodeFindController controller;
  final bool readOnly;

  const LocalSearchWidget({
    super.key,
    required this.controller,
    required this.readOnly,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(controller.value?.replaceMode == true ? 70 : 35);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CodeFindValue?>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (value == null) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final bool isReplaceMode = value.replaceMode;

        return Container(
          width: 320,
          margin: const EdgeInsets.only(top: 8, right: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row de Find
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      icon: Icon(
                        isReplaceMode
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        color: theme.iconTheme.color,
                      ),
                      onPressed: () => controller.toggleMode(),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 24,
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller.findInputController,
                              focusNode: controller.findInputFocusNode,
                              decoration: const InputDecoration(
                                hintText: 'Rechercher',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                              ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          _buildToggleButton(
                            icon: Icons.text_format,
                            tooltip: 'Match Case',
                            isActive: value.option.caseSensitive,
                            onPressed: () => controller.toggleCaseSensitive(),
                          ),
                          _buildToggleButton(
                            icon: Icons.code,
                            tooltip: 'Regular Expression',
                            isActive: value.option.regex,
                            onPressed: () => controller.toggleRegex(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    Icons.arrow_upward,
                    'Précédent',
                    () => controller.previousMatch(),
                  ),
                  _buildActionButton(
                    Icons.arrow_downward,
                    'Suivant',
                    () => controller.nextMatch(),
                  ),
                  _buildActionButton(
                    Icons.close,
                    'Fermer',
                    () => controller.close(),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              // Row de Replace
              if (isReplaceMode && !readOnly)
                Row(
                  children: [
                    const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        height: 24,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: TextField(
                          controller: controller.replaceInputController,
                          focusNode: controller.replaceInputFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Remplacer',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      Icons.find_replace,
                      'Remplacer',
                      () => controller.replaceMatch(),
                    ),
                    _buildActionButton(
                      Icons.plumbing,
                      'Remplacer tout',
                      () => controller.replaceAllMatches(),
                    ),
                    const SizedBox(
                      width: 28,
                    ), // Espace pour aligner avec le bouton close en haut
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.all(2),
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              child: Icon(
                icon,
                size: 14,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.iconTheme.color?.withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}
