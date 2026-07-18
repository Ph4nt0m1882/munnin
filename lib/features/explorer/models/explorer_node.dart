import 'dart:io';

/// Représente un nœud dans l'arbre de l'explorateur (dossier ou fichier).
class ExplorerNode {
  /// L'entité physique sur le disque.
  final FileSystemEntity entity;

  /// La profondeur du nœud dans l'arborescence (pour l'indentation).
  final int depth;

  /// Indique si le dossier est actuellement déployé.
  final bool isExpanded;

  /// Indique si l'entité est un dossier.
  final bool isDirectory;

  const ExplorerNode({
    required this.entity,
    required this.depth,
    required this.isExpanded,
    required this.isDirectory,
  });
}
