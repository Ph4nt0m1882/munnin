enum EditorMode {
  markdown,
  render
}

class OpenedFile {
  final String path;
  String content;
  bool isDirty;
  EditorMode mode;
  
  // Nom du fichier pour l'affichage dans l'onglet
  String get name {
    final fileName = path.split(RegExp(r'[/\\]')).last;
    if (fileName.toLowerCase().endsWith('.md')) {
      return fileName.substring(0, fileName.length - 3);
    }
    return fileName;
  }

  OpenedFile({
    required this.path,
    required this.content,
    this.isDirty = false,
    this.mode = EditorMode.markdown,
  });
}
