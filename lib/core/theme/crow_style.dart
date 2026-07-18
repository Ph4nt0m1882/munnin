import 'package:flutter/material.dart';

/// Représente les couleurs de l'interface utilisateur
class CrowStyleUI {
  final Color background;
  final Color surface;
  final Color surfaceHighlight;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Brightness brightness;

  final String? baseThemeSeed; // "#000000"
  final String? contrastSeed; // "#6FC3DF"

  const CrowStyleUI({
    required this.background,
    required this.surface,
    required this.surfaceHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.brightness,
    this.baseThemeSeed,
    this.contrastSeed,
  });
}

/// Représente les règles de rendu (Markdown -> HTML) et le CSS associé
class CrowStyleRender {
  final Map<String, dynamic>
  elements; // ex: {'title': {'H1': '<span class="...">', ...}}
  final bool fullRender;
  final Map<String, dynamic> blocCode;
  final String rawCss;

  const CrowStyleRender({
    this.elements = const {},
    this.fullRender = true,
    this.blocCode = const {},
    this.rawCss = '',
  });
}

/// La définition complète d'un thème CrowStyle
class CrowStyle {
  final String id;
  final String name;
  final String? model; // ex: 'dark_HC'
  final CrowStyleUI ui;
  final CrowStyleRender render;

  const CrowStyle({
    required this.id,
    required this.name,
    this.model,
    required this.ui,
    this.render = const CrowStyleRender(),
  });
}
