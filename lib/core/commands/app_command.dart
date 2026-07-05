import 'package:flutter/material.dart';

class AppCommand {
  final String id;
  final String title;
  final String? description;
  final IconData? icon;
  final String? shortcutLabel; // Ex: 'Ctrl+K'
  final VoidCallback execute;

  const AppCommand({
    required this.id,
    required this.title,
    this.description,
    this.icon,
    this.shortcutLabel,
    required this.execute,
  });
}
