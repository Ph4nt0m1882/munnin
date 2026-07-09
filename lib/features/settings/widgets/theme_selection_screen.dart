import 'package:flutter/material.dart';
import 'package:munnin/core/theme/theme.dart';
import 'package:munnin/features/settings/settings.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int> onThemeSelected;

  const ThemeSelectionScreen({
    super.key,
    required this.initialIndex,
    required this.onThemeSelected,
  });

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres d\'Apparence',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez le thème de l\'application. Les thèmes "HC" sont à haut contraste.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                childAspectRatio: 1.2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: BuiltinThemes.all.length,
              itemBuilder: (context, index) {
                final style = BuiltinThemes.all[index];
                return ThemePreviewCard(
                  style: style,
                  isSelected: _currentIndex == index,
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                    widget.onThemeSelected(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
