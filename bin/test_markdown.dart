import 'package:markdown/markdown.dart' as md;

void main() {
  String html = md.markdownToHtml('> [!NOTE]\n> Ceci est une note standard.', extensionSet: md.ExtensionSet.gitHubFlavored);
  print(html);
}
