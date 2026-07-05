import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:munnin/src/rust/api/simple.dart';

class WelcomeScreen extends StatefulWidget {
  final ValueChanged<String> onWikiOpened;
  final List<String> recentWikis;

  const WelcomeScreen({
    super.key,
    required this.onWikiOpened,
    this.recentWikis = const [],
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _createNewWiki() async {
    // 1. Demander le nom du Wiki
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Wiki'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Nom du wiki',
          ),
          autofocus: true,
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    // 2. Sélectionner le dossier parent
    String? parentPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Sélectionner le dossier parent du Wiki',
    );

    if (parentPath == null) return;

    setState(() => _isLoading = true);

    try {
      // 3. Appeler Rust pour initialiser
      final newWikiPath = initWiki(parentPath: parentPath, name: name.trim());
      
      // 4. Ouvrir le wiki
      widget.onWikiOpened(newWikiPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 80,
            color: theme.colorScheme.primary.withAlpha(150),
          ),
          const SizedBox(height: 24),
          Text(
            'Bienvenue sur Munnin',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre base de connaissances personnelle.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 48),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton.icon(
              onPressed: _createNewWiki,
              icon: const Icon(Icons.add_box),
              label: const Text('Créer un Wiki'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          
          if (widget.recentWikis.isNotEmpty) ...[
            const SizedBox(height: 48),
            Text(
              'Wikis récents',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.recentWikis.length,
                itemBuilder: (context, index) {
                  final path = widget.recentWikis[index];
                  // Extraire juste le nom du dossier pour l'affichage
                  final name = path.split(RegExp(r'[/\\]')).last;
                  return Card(
                    color: theme.colorScheme.surface,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.folder, color: theme.colorScheme.primary),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => widget.onWikiOpened(path),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
