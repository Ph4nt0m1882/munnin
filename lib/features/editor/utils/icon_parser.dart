import 'package:flutter/material.dart';
import 'package:munnin/features/editor/utils/icon_list.dart';

/// Parse une chaîne d'icône (ex: 'play', 'gitea', 'info') en IconData
IconData parseIcon(String iconStr, {IconData fallback = Icons.info}) {
  final str = iconStr.trim().toLowerCase();
  
  if (lucideIconsMap.containsKey(str)) {
    return lucideIconsMap[str]!;
  }

  if (simpleIconsMap.containsKey(str)) {
    return simpleIconsMap[str]!;
  }

  // Fallback for some common names if they differ
  final commonIcons = {
    'note': lucideIconsMap['lucide-info']!,
    'tip': lucideIconsMap['lucide-lightbulb']!,
    'important': lucideIconsMap['lucide-circle_alert']!,
    'warning': lucideIconsMap['lucide-triangle_alert']!,
    'caution': lucideIconsMap['lucide-octagon']!,
    'danger': lucideIconsMap['lucide-flame']!,
    'success': lucideIconsMap['lucide-circle_check']!,
    'error': lucideIconsMap['lucide-circle_x']!,
  };

  if (commonIcons.containsKey(str)) {
    return commonIcons[str]!;
  }
  
  return fallback;
}
