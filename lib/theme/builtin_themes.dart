import 'package:flutter/material.dart';
import 'crow_style.dart';

class BuiltinThemes {
  static const CrowStyle light = CrowStyle(
    id: 'builtin_light',
    name: 'Light',
    ui: CrowStyleUI(
      brightness: Brightness.light,
      background: Color(0xFFF8FAFC),
      surface: Color(0xFFFFFFFF),
      surfaceHighlight: Color(0xFFE2E8F0),
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF64748B),
      accent: Color(0xFF0284C7),
    ),
  );

  static const CrowStyle dark = CrowStyle(
    id: 'builtin_dark',
    name: 'Dark',
    ui: CrowStyleUI(
      brightness: Brightness.dark,
      background: Color(0xFF0F172A),
      surface: Color(0xFF1E293B),
      surfaceHighlight: Color(0xFF334155),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      accent: Color(0xFF38BDF8),
    ),
  );

  static const CrowStyle lightHC = CrowStyle(
    id: 'builtin_light_hc',
    name: 'Light High Contrast',
    ui: CrowStyleUI(
      brightness: Brightness.light,
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      surfaceHighlight: Color(0xFF000000), // Bordures très contrastées
      textPrimary: Color(0xFF000000),
      textSecondary: Color(0xFF000000),
      accent: Color(0xFF0000EE), // Bleu pur web
    ),
  );

  static const CrowStyle darkHC = CrowStyle(
    id: 'builtin_dark_hc',
    name: 'Dark High Contrast',
    ui: CrowStyleUI(
      brightness: Brightness.dark,
      background: Color(0xFF000000),
      surface: Color(0xFF000000),
      surfaceHighlight: Color(0xFFFFFFFF), // Bordures très contrastées
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFFFFFFF),
      accent: Color(0xFF00FF00), // Vert fluo
    ),
  );

  static const List<CrowStyle> all = [light, dark, lightHC, darkHC];
}
