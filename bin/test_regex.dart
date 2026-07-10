void main() {
  String html = '\n<p>[!NOTE]\nCeci est une note standard.</p>\n';
  final regexStandard = RegExp(r'^(\s*<p>\s*)?\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION|DANGER)\]([^\n<]*)(.*)', dotAll: true, caseSensitive: false);
  final match = regexStandard.firstMatch(html);
  if (match != null) {
    print("Match found!");
    print("Group 1 (prefix): '${match.group(1)}'");
    print("Group 2 (type): '${match.group(2)}'");
    print("Group 3 (title): '${match.group(3)}'");
    print("Group 4 (remaining): '${match.group(4)}'");
  } else {
    print("NO MATCH");
  }
}
