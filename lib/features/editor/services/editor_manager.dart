import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:munnin/features/editor/models/opened_file.dart';

class EditorManager extends ChangeNotifier {
  static final EditorManager instance = EditorManager._internal();
  EditorManager._internal();

  final List<OpenedFile> _openedFiles = [];
  String? _activeFilePath;

  List<OpenedFile> get openedFiles => List.unmodifiable(_openedFiles);
  String? get activeFilePath => _activeFilePath;

  OpenedFile? get activeFile {
    if (_activeFilePath == null) return null;
    try {
      return _openedFiles.firstWhere((f) => f.path == _activeFilePath);
    } catch (_) {
      return null;
    }
  }

  /// Ouvre un fichier. S'il est déjà ouvert, le met simplement au premier plan.
  Future<void> openFile(String path) async {
    // Vérifie si déjà ouvert
    final existingIndex = _openedFiles.indexWhere((f) => f.path == path);
    if (existingIndex != -1) {
      _activeFilePath = path;
      notifyListeners();
      return;
    }

    try {
      final file = File(path);
      if (!await file.exists()) return;

      final content = await file.readAsString();
      _openedFiles.add(OpenedFile(path: path, content: content));
      _activeFilePath = path;
      notifyListeners();
    } catch (e) {
      print("Erreur lors de l'ouverture du fichier : $e");
    }
  }

  /// Ferme un fichier
  void closeFile(String path) {
    final index = _openedFiles.indexWhere((f) => f.path == path);
    if (index == -1) return;

    _openedFiles.removeAt(index);

    // Ajuster le fichier actif si on a fermé celui en cours
    if (_activeFilePath == path) {
      if (_openedFiles.isNotEmpty) {
        // On active le précédent, ou le premier s'il n'y en a pas de précédent
        final newIndex = index > 0 ? index - 1 : 0;
        _activeFilePath = _openedFiles[newIndex].path;
      } else {
        _activeFilePath = null;
      }
    }
    notifyListeners();
  }

  /// Met à jour le contenu d'un fichier (rend dirty)
  void updateFileContent(String path, String newContent) {
    final file = _openedFiles.where((f) => f.path == path).firstOrNull;
    if (file != null && file.content != newContent) {
      file.content = newContent;
      file.isDirty = true;
      notifyListeners();
    }
  }

  /// Marque manuellement un fichier comme propre (utile pour les sauvegardes partielles)
  void markAsClean(String path) {
    final file = _openedFiles.where((f) => f.path == path).firstOrNull;
    if (file != null && file.isDirty) {
      file.isDirty = false;
      notifyListeners();
    }
  }

  /// Sauvegarde le fichier actif
  Future<void> saveActiveFile() async {
    final file = activeFile;
    if (file != null && file.isDirty) {
      await _saveFileToDisk(file);
    }
  }

  /// Sauvegarde tous les fichiers modifiés
  Future<void> saveAll() async {
    for (var file in _openedFiles.where((f) => f.isDirty)) {
      await _saveFileToDisk(file);
    }
  }

  Future<void> _saveFileToDisk(OpenedFile openedFile) async {
    try {
      final file = File(openedFile.path);
      await file.writeAsString(openedFile.content);
      openedFile.isDirty = false;
      notifyListeners();
    } catch (e) {
      print("Erreur lors de la sauvegarde de ${openedFile.path} : $e");
    }
  }

  /// Renomme un fichier ouvert
  void renameOpenedFile(String oldPath, String newPath) {
    final index = _openedFiles.indexWhere((f) => f.path == oldPath);
    if (index != -1) {
      final file = _openedFiles[index];
      _openedFiles[index] = OpenedFile(
        path: newPath,
        content: file.content,
        isDirty: file.isDirty,
        mode: file.mode,
      );
      if (_activeFilePath == oldPath) {
        _activeFilePath = newPath;
      }
      notifyListeners();
    }
  }

  /// Change le mode d'un fichier ouvert (markdown/render)
  void setFileMode(String path, EditorMode mode) {
    final file = _openedFiles.where((f) => f.path == path).firstOrNull;
    if (file != null && file.mode != mode) {
      file.mode = mode;
      notifyListeners();
    }
  }
  
  /// Change le mode de tous les fichiers
  void setAllFilesMode(EditorMode mode) {
    bool changed = false;
    for (var file in _openedFiles) {
      if (file.mode != mode) {
        file.mode = mode;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Ferme tous les fichiers (lors de la fermeture du wiki par exemple)
  void closeAll() {
    _openedFiles.clear();
    _activeFilePath = null;
    notifyListeners();
  }
}
