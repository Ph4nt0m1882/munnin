import 'package:markdown/markdown.dart';

/// Syntaxe personnalisée pour intercepter `!![alt](src)`
/// et générer une balise HTML custom `<munnin-img src="..." alt="..."></munnin-img>`
class DoubleBangImageSyntax extends InlineSyntax {
  // Regex pour attraper !![alt](src)
  // Group 1: alt text
  // Group 2: src URL
  DoubleBangImageSyntax() : super(r'!!\[(.*?)\]\((.*?)\)');

  @override
  bool onMatch(InlineParser parser, Match match) {
    final alt = match[1] ?? '';
    final src = match[2] ?? '';

    // Générer un élément HTML custom
    final el = Element.empty('munnin-img');
    el.attributes['alt'] = alt;
    el.attributes['src'] = src;

    parser.addNode(el);
    return true;
  }
}
