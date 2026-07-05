import 'package:flutter/material.dart';
import 'package:munnin/theme/crow_style.dart';
import 'package:munnin/theme/theme_manager.dart';

class ThemePreviewCard extends StatelessWidget {
  final CrowStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemePreviewCard({
    super.key,
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // On génère le ThemeData spécifique à cette carte
    final previewTheme = ThemeManager.buildThemeData(style);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? previewTheme.colorScheme.primary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: previewTheme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        // L'astuce magique : On force tout ce sous-arbre à utiliser "previewTheme" !
        child: Theme(
          data: previewTheme,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9), // Légèrement inférieur pour s'adapter à la bordure
            child: Container(
              color: previewTheme.scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fausse TopBar
                  Container(
                    height: 32,
                    color: previewTheme.colorScheme.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      style.name,
                      style: previewTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Faux Contenu
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 12,
                            decoration: BoxDecoration(
                              color: previewTheme.textTheme.bodyLarge?.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 140,
                            height: 8,
                            decoration: BoxDecoration(
                              color: previewTheme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Spacer(),
                          // Faux bouton
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: previewTheme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Actif',
                                style: TextStyle(
                                  color: previewTheme.colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
