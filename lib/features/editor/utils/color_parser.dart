import 'package:flutter/material.dart';

/// Parse une chaîne de couleur (ex: 'green', 'red', '#00FF00', '00FF00') en objet Color
Color parseColor(String colorStr, {Color fallback = Colors.grey}) {
  final str = colorStr.trim().toLowerCase();

  // Couleurs nommées standards
  const namedColors = {
    'red': Colors.red,
    'green': Colors.green,
    'blue': Colors.blue,
    'yellow': Colors.yellow,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'cyan': Colors.cyan,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
    'brown': Colors.brown,
    'grey': Colors.grey,
    'gray': Colors.grey,
    'black': Colors.black,
    'white': Colors.white,
    'transparent': Colors.transparent,
  };

  if (namedColors.containsKey(str)) {
    return namedColors[str]!;
  }

  // Couleurs hexadécimales
  String hexStr = str;
  if (hexStr.startsWith('#')) {
    hexStr = hexStr.substring(1);
  }
  if (hexStr.length == 6) {
    hexStr = 'FF$hexStr'; // Ajoute l'opacité (alpha) si manquante
  }

  if (hexStr.length == 8) {
    try {
      return Color(int.parse(hexStr, radix: 16));
    } catch (e) {
      // Échec du parsing
    }
  }

  return fallback;
}
