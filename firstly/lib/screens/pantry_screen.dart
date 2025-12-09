import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import '../utils/app_theme.dart';

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
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar à Despensa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Item',
                hintText: 'Ex: Arroz',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantidade',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final qty = int.tryParse(quantityController.text) ?? 1;
                final newItem = PantryItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  quantity: qty,
                  addedDate: DateTime.now(),
                );
                
                
                final currentItems = await PantryService.loadPantryItems();
                final existingIndex = currentItems.indexWhere(
                  (i) => i.name.toLowerCase() == newItem.name.toLowerCase()
                );
                
                if (existingIndex >= 0) {
                  currentItems[existingIndex].quantity += newItem.quantity;
                  await PantryService.savePantryItems(currentItems);
                } else {
                   await PantryService.savePantryItems([...currentItems, newItem]);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _loadItems();
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} removido')),
        );
      }
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewItem,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
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
                              if (value != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Consumo automático: -1 a cada $value dias'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
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
