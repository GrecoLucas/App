import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../scanner/screens/barcode_scanner_screen.dart';
import '../../favorites/widgets/quick_add_favorites_dialog.dart';
import '../widgets/enhanced_add_pantry_item_dialog.dart';

enum PantrySortOption { name, quantityAsc, quantityDesc }

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  List<PantryItem> _pantryItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<PantryItem> _filteredItems = [];
  PantrySortOption _currentSortOption = PantrySortOption.name;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadItems() async {
    setState(() => _isLoading = true);
    final items = await PantryService.loadPantryItems();
    
    // Sort logic
    _sortItems(items);
    
    setState(() {
      _pantryItems = items;
      _filteredItems = items;
      _isLoading = false;
    });
    _filterItems();
  }

  void _sortItems(List<PantryItem> items) {
    switch (_currentSortOption) {
      case PantrySortOption.name:
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case PantrySortOption.quantityAsc:
        items.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case PantrySortOption.quantityDesc:
        items.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
    }
  }

  void _filterItems() {
    List<PantryItem> result;
    if (_searchController.text.isEmpty) {
      result = List.from(_pantryItems);
    } else {
      result = _pantryItems
          .where((item) => item.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    }
    _sortItems(result);
    setState(() => _filteredItems = result);
  }

  void _addNewItem() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnhancedAddPantryItemDialog(),
    );

    if (result == true && mounted) {
      _loadItems();
    }
  }

  void _updateQuantity(PantryItem item, int change) async {
    final newQuantity = item.quantity + change;
    if (newQuantity < 0) {
      _deleteItem(item);
    } else {
      item.quantity = newQuantity;
      await PantryService.updateItem(item);
      _loadItems();
    }
  }

  void _deleteItem(PantryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover item?'),
        content: Text('Deseja remover "${item.name}" da despensa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await PantryService.removeItem(item.id);
      _loadItems();
    }
  }

  // Adiciona produto via scanner de código de barras à despensa
  void _addProductViaScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          onItemScanned: (scannedItem) async {
            final name = scannedItem.name.length > 24 
                ? scannedItem.name.substring(0, 24) 
                : scannedItem.name;
            
            // Verifica se já existe na despensa
            final currentItems = await PantryService.loadPantryItems();
            final existingIndex = currentItems.indexWhere(
              (i) => i.name.toLowerCase() == name.toLowerCase()
            );
            
            if (existingIndex >= 0) {
              // Atualiza quantidade
              currentItems[existingIndex].quantity += scannedItem.quantity;
              await PantryService.savePantryItems(currentItems);
              
              
              if (mounted) {
                SnackBarService.success(context, 'Quantidade de "$name" atualizada na despensa!');
              }
            } else {
              // Adiciona novo item
               final newItem = PantryItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                quantity: scannedItem.quantity,
                addedDate: DateTime.now(),
              );
               await PantryService.savePantryItems([...currentItems, newItem]);
               
               if (mounted) {
                // ignore: use_build_context_synchronously
                SnackBarService.success(context, '"$name" adicionado à despensa!');
              }
            }
            
            if (mounted) {
              _loadItems();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.kitchen, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Despensa'),
          ],
        ),
        actions: [
          PopupMenuButton<PantrySortOption>(
            icon: const Icon(Icons.sort, color: Colors.black87),
            onSelected: (PantrySortOption result) {
              setState(() {
                _currentSortOption = result;
              });
              _filterItems(); // Re-sort and filter
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<PantrySortOption>>[
              const PopupMenuItem<PantrySortOption>(
                value: PantrySortOption.name,
                child: Text('Nome (A-Z)'),
              ),
              const PopupMenuItem<PantrySortOption>(
                value: PantrySortOption.quantityAsc,
                child: Text('Quantidade (Crescente)'),
              ),
              const PopupMenuItem<PantrySortOption>(
                value: PantrySortOption.quantityDesc,
                child: Text('Quantidade (Decrescente)'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar na despensa...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.softGrey,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredItems.isEmpty
                      ? _buildEmptyState()
                      : _buildItemList(),
              ),
            ],
          ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      heroTag: 'scanner_fab_pantry',
      onPressed: _addProductViaScanner,
      backgroundColor: Colors.blue, // Scanner Azul
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      color: Colors.white,
      shadowColor: Colors.black26,
      elevation: 12,
      height: 58, // Diminuir o espaço gasto
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Favoritos
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black54, size: 24),
            tooltip: 'Favoritos',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => QuickAddFavoritesDialog(
                  onItemsSelected: (items) async {
                    if (items.isEmpty) return;
                    
                    final currentItems = await PantryService.loadPantryItems();
                    
                    for (final data in items) {
                       final newItem = PantryItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString() + data['name'],
                          name: data['name'],
                          quantity: data['quantity'],
                          addedDate: DateTime.now(),
                       );
                       
                       // Busca independentemente de case sensitive
                       final existingIndex = currentItems.indexWhere(
                          (i) => i.name.toLowerCase() == newItem.name.toLowerCase()
                       );
                          
                       if (existingIndex >= 0) {
                           currentItems[existingIndex].quantity += newItem.quantity;
                       } else {
                           currentItems.add(newItem);
                       }
                    }
                    await PantryService.savePantryItems(currentItems);
                    
                    if (mounted) {
                       _loadItems();
                       SnackBarService.success(context, '${items.length} item${items.length != 1 ? 's' : ''} adicionado${items.length != 1 ? 's' : ''} à despensa');
                    }
                  },
                ),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          
          const Spacer(), // Empurra para a direita
          
          // Adicionar (+) ao lado do Scanner Maior
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _addNewItem,
              icon: const Icon(Icons.add, color: Colors.white, size: 22),
              tooltip: 'Adicionar manual',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 64), // Espaço reservado para o FAB (FloatingActionButtonScanner)
        ],
      ),
    );
  }





  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Nenhum item encontrado'
                : 'Sua despensa está vazia',
            style: AppStyles.headingMedium.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        
        // Define background color based on quantity
        Color cardColor = Colors.white;
        if (item.quantity == 0) {
          cardColor = AppTheme.warningRed.withOpacity(0.1);
        } else {
          cardColor = AppTheme.lightGreen;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adicionado em: ${item.addedDate.day}/${item.addedDate.month}',
                        style: AppStyles.captionGrey,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.softGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dropdown para consumo automático
                      Tooltip(
                        message: 'Diminuir 1 unidade a cada X dias',
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: item.autoConsumeDays,
                            icon: const Icon(Icons.timer, size: 16, color: Colors.grey),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            borderRadius: BorderRadius.circular(12),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Off', style: TextStyle(fontSize: 12)),
                              ),
                              ...List.generate(10, (i) {
                                final days = i + 1;
                                return DropdownMenuItem<int?>(
                                  value: days,
                                  child: Text('${days}d', style: const TextStyle(fontSize: 12)),
                                );
                              }),
                            ],
                            onChanged: (value) async {
                              item.autoConsumeDays = value;
                              // Reset the timer when setting changed
                              item.lastAutoConsumeDate = value != null ? DateTime.now() : null;
                              await PantryService.updateItem(item);
                              setState(() {}); // Refresh UI
                            },
                          ),
                        ),
                      ),
                      Container(width: 1, height: 24, color: Colors.grey[300]),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: () => _updateQuantity(item, -1),
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: () => _updateQuantity(item, 1),
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
