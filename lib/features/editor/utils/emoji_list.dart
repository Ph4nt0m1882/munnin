import 'package:unicode_emojis/unicode_emojis.dart';

/// Récupère une liste sécurisée d'émojis (version <= 12.0) pour éviter les problèmes d'affichage (tofu) sur les anciens OS.
List<Emoji> getSafeEmojis() {
  return UnicodeEmojis.allEmojis.where((emoji) {
    if (emoji.category.description == 'Flags') return false;
    try {
      final versionStr = emoji.addedIn;
      final version = double.parse(versionStr);
      return version <= 12.0;
    } catch (e) {
      return true; // En cas de doute, on garde.
    }
  }).toList();
}
