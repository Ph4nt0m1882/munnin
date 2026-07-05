import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:munnin/src/rust/frb_generated.dart';
import 'package:munnin/src/rust/api/settings.dart';
import 'package:munnin/theme/builtin_themes.dart';
import 'package:munnin/theme/theme_manager.dart';
import 'package:munnin/ui/top_bar.dart';
import 'package:munnin/ui/responsive_layout.dart';
import 'package:munnin/ui/bottom_navigation.dart';
import 'package:munnin/ui/settings/theme_selection_screen.dart';
import 'package:munnin/ui/layout/draggable_window.dart';
import 'package:munnin/ui/editor/welcome_screen.dart';
import 'package:munnin/core/commands/app_command.dart';
import 'package:munnin/core/commands/command_manager.dart';
import 'package:munnin/ui/commands/top_bar_search.dart';
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
      if (HardwareKeyboard.instance.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyK) {
        CommandManager.instance.execute('app.command_palette');
        return true;
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
    
    // On pourra rajouter wiki.create une fois qu'on saura appeler le picker sans WelcomeScreen
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
                      child: _currentWikiPath == null 
                        ? WelcomeScreen(
                            onWikiOpened: _openWiki,
                            recentWikis: _recentWikis,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Wiki ouvert !',
                                  style: themeData.textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _currentWikiPath!,
                                  style: themeData.textTheme.bodyLarge?.copyWith(
                                    color: themeData.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
