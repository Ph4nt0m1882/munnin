import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:munnin/features/editor/utils/icon_list.dart';

class IconPickerWidget extends StatefulWidget {
  final Function(String, String) onIconSelected; // (iconName, libraryPrefix) ou (character, 'symbol')
  
  const IconPickerWidget({super.key, required this.onIconSelected});

  static Future<void> show(BuildContext context, Function(String, String) onIconSelected) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 500,
          height: 600,
          child: IconPickerWidget(onIconSelected: onIconSelected),
        ),
      ),
    );
  }

  @override
  State<IconPickerWidget> createState() => _IconPickerWidgetState();
}

class _IconPickerWidgetState extends State<IconPickerWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Selected state
  String? _selectedIconName;
  IconData? _selectedIconData;
  String? _selectedSymbol;
  String _currentLibrary = 'lucide'; // 'lucide', 'simple', 'symbol'

  final List<String> _specialCharacters = [
    '©', '®', '™', '•', '←', '↑', '→', '↓', '↔', '↕',
    '♠', '♣', '♥', '♦', 'Ω', '∑', 'π', '∞', '≈', '≠',
    '≤', '≥', '√', '∫', 'Δ', 'µ', '°', '±', '÷', '×',
    '€', '£', '¥', '¢', '½', '¼', '¾', '²', '³', 'µ',
    '¶', '§', '¡', '¿', '«', '»', '…', '‰', '✓', '✗',
    '★', '☆', '☎', '☑', '☐', '☒', '✂', '✎', '✓', '✔',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIconName = null;
          _selectedIconData = null;
          _selectedSymbol = null;
          if (_tabController.index == 0) _currentLibrary = 'lucide';
          if (_tabController.index == 1) _currentLibrary = 'simple';
          if (_tabController.index == 2) _currentLibrary = 'symbol';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, IconData>> get _filteredLucide {
    if (_searchQuery.isEmpty) return lucideIconsMap.entries.toList();
    return lucideIconsMap.entries
        .where((e) => e.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<MapEntry<String, IconData>> get _filteredSimple {
    if (_searchQuery.isEmpty) return simpleIconsMap.entries.toList();
    return simpleIconsMap.entries
        .where((e) => e.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<String> get _filteredSymbols {
    // Basic filtering, usually symbols are visual, but we might just return all if there's no name
    return _specialCharacters;
  }

  void _onInsert() {
    if (_currentLibrary == 'symbol' && _selectedSymbol != null) {
      widget.onIconSelected(_selectedSymbol!, _currentLibrary);
      Navigator.pop(context);
    } else if (_selectedIconName != null) {
      widget.onIconSelected(_selectedIconName!, _currentLibrary);
      Navigator.pop(context);
    }
  }

  void _onCopy() {
    if (_currentLibrary == 'symbol' && _selectedSymbol != null) {
      Clipboard.setData(ClipboardData(text: _selectedSymbol!));
    } else if (_selectedIconName != null) {
      Clipboard.setData(ClipboardData(text: _selectedIconName!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Header
        Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Rechercher...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Lucide'),
                  Tab(text: 'Simple Icons'),
                  Tab(text: 'Symboles'),
                ],
              ),
            ],
          ),
        ),
        
        // Grid
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildIconGrid(_filteredLucide, 'lucide'),
              _buildIconGrid(_filteredSimple, 'simple'),
              _buildSymbolGrid(_filteredSymbols),
            ],
          ),
        ),
        
        // Bottom Action Panel
        if (_selectedIconName != null || _selectedSymbol != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                if (_currentLibrary != 'symbol' && _selectedIconData != null) ...[
                  Icon(_selectedIconData, size: 32, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _selectedIconName!,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else if (_currentLibrary == 'symbol' && _selectedSymbol != null) ...[
                  Text(
                    _selectedSymbol!,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Caractère Spécial',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: _onCopy,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _onInsert,
                  icon: const Icon(Icons.check),
                  label: const Text('Insérer'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildIconGrid(List<MapEntry<String, IconData>> icons, String library) {
    if (icons.isEmpty) {
      return const Center(child: Text('Aucune icône trouvée.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 60,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final iconEntry = icons[index];
        final isSelected = _selectedIconName == iconEntry.key && _currentLibrary == library;
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedIconName = iconEntry.key;
              _selectedIconData = iconEntry.value;
            });
          },
          onDoubleTap: () {
            setState(() {
              _selectedIconName = iconEntry.key;
              _selectedIconData = iconEntry.value;
            });
            _onInsert();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              ),
            ),
            child: Icon(
              iconEntry.value,
              color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymbolGrid(List<String> symbols) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 60,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: symbols.length,
      itemBuilder: (context, index) {
        final symbol = symbols[index];
        final isSelected = _selectedSymbol == symbol && _currentLibrary == 'symbol';
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedSymbol = symbol;
            });
          },
          onDoubleTap: () {
            setState(() {
              _selectedSymbol = symbol;
            });
            _onInsert();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              ),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: 24,
                color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
