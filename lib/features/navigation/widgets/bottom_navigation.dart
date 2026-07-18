import 'package:flutter/material.dart';

class MobileBottomNavigation extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final VoidCallback onOpenEditor;

  const MobileBottomNavigation({
    super.key,
    required this.onThemeToggle,
    required this.onOpenEditor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      backgroundColor: theme.colorScheme.surface,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurface,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_open),
          label: 'Fichiers',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Recherche'),
        BottomNavigationBarItem(
          icon: Icon(Icons.color_lens_outlined),
          label: 'Thème',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Paramètres',
        ),
      ],
      onTap: (index) {
        if (index == 0) {
          onOpenEditor();
        } else if (index == 2) {
          onThemeToggle();
        }
      },
    );
  }
}
