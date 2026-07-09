import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:munnin/src/rust/frb_generated.dart';
import 'package:munnin/src/rust/api/settings.dart';
import 'package:munnin/core/theme/theme.dart';
import 'package:munnin/features/navigation/navigation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:munnin/src/rust/api/simple.dart';
import 'package:munnin/features/settings/settings.dart';
import 'package:munnin/features/editor/editor.dart';
import 'package:munnin/features/explorer/explorer.dart';
import 'package:munnin/core/commands/commands.dart';
import 'package:window_manager/window_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 700),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // Cacher la barre native
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MunninApp());
}

class MunninApp extends StatefulWidget {
  const MunninApp({super.key});

  @override
  State<MunninApp> createState() => _MunninAppState();
}

class _MunninAppState extends State<MunninApp> {
  int _themeIndex = 0; // 0 = Light, 1 = Dark, etc.
  bool _isSettingsOpen = false;
  String? _currentWikiPath; // Stocke le chemin du wiki ouvert
  List<String> _recentWikis = [];

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
    _registerCommands();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeys);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeys);
    super.dispose();
  }

  bool _handleGlobalKeys(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (HardwareKeyboard.instance.isControlPressed) {
        if (event.logicalKey == LogicalKeyboardKey.keyK) {
          CommandManager.instance.execute('app.command_palette');
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            CommandManager.instance.execute('file.save_all');
          } else {
            CommandManager.instance.execute('file.save');
          }
          return true;
        }
      }
    }
    return false;
  }

  void _registerCommands() {
    final cmdManager = CommandManager.instance;
    
    cmdManager.register(AppCommand(
      id: 'app.theme_settings',
      title: 'Changer le thème',
      description: 'Ouvrir les paramètres d\'apparence',
      icon: Icons.palette,
      execute: _openThemeSettings,
    ));

    cmdManager.register(AppCommand(
      id: 'app.command_palette',
      title: 'Afficher la palette de commandes',
      icon: Icons.search,
      shortcutLabel: 'Ctrl+K',
      execute: () {
        globalSearchFocusNode.requestFocus();
      },
    ));
    
    cmdManager.register(AppCommand(
      id: 'wiki.create',
      title: 'Nouveau Wiki...',
      description: 'Créer un nouveau répertoire de connaissances',
      icon: Icons.create_new_folder,
      execute: _createNewWiki,
    ));

    cmdManager.register(AppCommand(
      id: 'wiki.open',
      title: 'Ouvrir un Wiki...',
      description: 'Ouvrir un répertoire existant',
      icon: Icons.folder_open,
      execute: _openExistingWiki,
    ));

    cmdManager.register(AppCommand(
      id: 'file.save',
      title: 'Sauvegarder',
      description: 'Sauvegarde le fichier actif',
      icon: Icons.save,
      shortcutLabel: 'Ctrl+S',
      execute: () {
        EditorManager.instance.saveActiveFile();
      },
    ));

    cmdManager.register(AppCommand(
      id: 'file.save_all',
      title: 'Sauvegarder tout',
      description: 'Sauvegarde tous les fichiers modifiés',
      icon: Icons.save_alt,
      shortcutLabel: 'Ctrl+Shift+S',
      execute: () {
        EditorManager.instance.saveAll();
      },
    ));
  }

  Future<void> _createNewWiki() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Wiki'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nom du wiki'),
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

    String? parentPath = await FilePicker.getDirectoryPath(
      dialogTitle: 'Sélectionner le dossier parent du Wiki',
    );

    if (parentPath == null) return;

    try {
      final newWikiPath = initWiki(parentPath: parentPath, name: name.trim());
      _openWiki(newWikiPath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openExistingWiki() async {
    String? path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Ouvrir un Wiki existant',
    );

    if (path != null) {
      _openWiki(path);
    }
  }

  void _loadInitialSettings() {
    final settings = loadSettings();
    setState(() {
      _themeIndex = settings.themeIndex;
      _recentWikis = settings.recentWikis;
    });
  }

  void _setTheme(int index) {
    setState(() {
      _themeIndex = index;
    });
    saveTheme(index: index);
  }
  
  void _openThemeSettings() {
    setState(() {
      _isSettingsOpen = true;
    });
  }

  void _closeThemeSettings() {
    setState(() {
      _isSettingsOpen = false;
    });
  }

  void _openWiki(String path) {
    setState(() {
      _currentWikiPath = path;
    });
    addRecentWiki(wikiPath: path);
    _loadInitialSettings(); // Rafraîchit l'historique
  }

  void _openEditor() {
    // Force la vue éditeur (ferme potentiellement d'autres choses plus tard)
  }

  @override
  Widget build(BuildContext context) {
    final currentCrowStyle = BuiltinThemes.all[_themeIndex];
    final themeData = ThemeManager.buildThemeData(currentCrowStyle);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Munnin Wiki',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < ResponsiveLayout.mobileBreakpoint;
          
          return Scaffold(
                appBar: const CustomTopBar(),
                // Si mobile, on affiche la BottomBar, sinon rien (car Desktop utilise la LeftSidebar)
                bottomNavigationBar: isMobile 
                  ? MobileBottomNavigation(
                      onThemeToggle: _openThemeSettings,
                      onOpenEditor: _openEditor,
                    ) 
                  : null,
                // Le body utilise un Stack pour permettre aux fenêtres de flotter au-dessus de l'éditeur
                body: Stack(
                  children: [
                    // Couche 0 : Le Layout de fond (Editeur ou Accueil)
                    ResponsiveLayout(
                      onThemeToggle: _openThemeSettings,
                      onOpenEditor: _openEditor,
                      rightSidebar: _currentWikiPath != null
                        ? FileExplorer(
                            rootPath: _currentWikiPath!,
                            onFileSelected: (path) {
                              EditorManager.instance.openFile(path);
                            },
                          )
                        : null,
                      child: _currentWikiPath == null 
                        ? WelcomeScreen(
                            onWikiOpened: _openWiki,
                            recentWikis: _recentWikis,
                          )
                        : const MarkdownEditor(),
                    ),
                    
                    // Couche 1 : Les Fenêtres Flottantes (In-App Windows)
                    if (_isSettingsOpen)
                      DraggableWindow(
                        title: 'Paramètres',
                        onClose: _closeThemeSettings,
                        child: ThemeSelectionScreen(
                          initialIndex: _themeIndex,
                          onThemeSelected: _setTheme,
                        ),
                      ),
                  ],
                ),
              );
            }
          ),
    );
  }
}
