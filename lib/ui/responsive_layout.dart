import 'package:flutter/material.dart';
import 'package:munnin/ui/left_sidebar.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child; // La zone centrale (l'éditeur)
  final VoidCallback onThemeToggle;
  final VoidCallback onOpenEditor;
  
  // Point de rupture pour passer en mode "Téléphone"
  static const double mobileBreakpoint = 600.0;

  const ResponsiveLayout({
    super.key,
    required this.child,
    required this.onThemeToggle,
    required this.onOpenEditor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < mobileBreakpoint;
        final themeData = Theme.of(context);

        if (isMobile) {
          // Layout type Téléphone (Pas de barre à gauche)
          return child;
        } else {
          // Layout type Desktop (Barre à gauche)
          return Row(
            children: [
              LeftSidebar(
                onThemeToggle: onThemeToggle,
                onOpenEditor: onOpenEditor,
              ),
              VerticalDivider(width: 1, color: themeData.dividerColor),
              Expanded(child: child),
            ],
          );
        }
      },
    );
  }
}
