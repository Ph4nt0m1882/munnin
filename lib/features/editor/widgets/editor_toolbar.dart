import 'package:flutter/material.dart';

class EditorToolbar extends StatefulWidget {
  final VoidCallback onIconPickerPressed;

  const EditorToolbar({super.key, required this.onIconPickerPressed});

  @override
  State<EditorToolbar> createState() => _EditorToolbarState();
}

class _EditorToolbarState extends State<EditorToolbar> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: theme.colorScheme.surfaceContainer,
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: _isExpanded ? 12.0 : 4.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expand/Collapse Button
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
            ),
            tooltip: _isExpanded ? 'Réduire la barre' : 'Déployer la barre',
            onPressed: _toggleExpanded,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
          const SizedBox(width: 16),

          // Toolbar Actions
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ToolbarItem(
                  icon: Icons.emoji_emotions_outlined,
                  label: 'Symboles',
                  isExpanded: _isExpanded,
                  onPressed: widget.onIconPickerPressed,
                  tooltip: 'Insérer un symbole ou une icône (Ctrl+Maj+I)',
                ),
                // Future toolbar items can be added here
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onPressed;
  final String tooltip;

  const _ToolbarItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 12.0 : 6.0,
            vertical: isExpanded ? 8.0 : 4.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent, // Can be changed on hover
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isExpanded ? 24.0 : 18.0,
                color: theme.colorScheme.onSurface,
              ),
              if (isExpanded) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
