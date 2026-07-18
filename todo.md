# Munnin - TODO & Roadmap

Ce document rassemble les prochaines évolutions majeures prévues pour le projet Munnin.

## 📝 1. L'Éditeur de Texte Riche (Priorité Haute)
Amélioration de l'expérience d'écriture avec un véritable éditeur de texte.
- [ ] Remplacer le `TextField` standard par un éditeur supportant le texte riche (soit coloration syntaxique Markdown, soit rendu WYSIWYG type Flutter Quill).
- [ ] Intégrer la logique d'analyse via Rust (`pulldown-cmark`) pour transformer le texte édité en blocs ("chunks") et garantir une sauvegarde en pur Markdown (`.md`).
- [ ] Implémenter l'annulation/rétablissement (Undo/Redo via `Ctrl+Z` / `Ctrl+Y`).

## 🔍 2. Moteur de Recherche Globale
Permettre de retrouver ses connaissances instantanément.
- [ ] Connecter la "Command Palette" (`Ctrl+K`) à un véritable moteur de recherche textuelle.
- [ ] Créer une fonction Rust optimisée pour lire et chercher (Regex) à haute vitesse dans tous les fichiers `.md` du dossier du wiki.
- [ ] Afficher les résultats avec mise en surbrillance du texte pertinent directement depuis l'interface Flutter.
- [ ] (Long terme) Implémenter un modèle d'Embeddings local en Rust pour la "Smart Research" (recherche vectorielle et sémantique de type RAG).

## 🔗 3. Système de Liens Wiki & Backlinks
Transformer les notes isolées en un réseau de connaissances connecté.
- [ ] Permettre la création de liens internes avec la syntaxe `[[Nom de la note]]`.
- [ ] Gérer le clic sur ces liens pour ouvrir l'onglet correspondant (ou créer le fichier s'il n'existe pas encore).
- [ ] (Optionnel) Implémenter un panneau "Backlinks" pour voir quelles autres notes pointent vers la note actuellement ouverte.
- [ ] (Long terme) Créer une vue "Graphe" globale des interconnexions (style Obsidian).

## 🛠 4. Améliorations de l'Architecture et du Pont Rust
- [ ] Déplacer les opérations de création/suppression de fichiers de Dart vers le backend Rust pour centraliser la sécurité et la logique métier de la gestion de fichiers (via `flutter_rust_bridge`).
- [ ] Intégrer un système de logs (en Dart et en Rust) pour arrêter l'usage des simples `print()` en développement.
