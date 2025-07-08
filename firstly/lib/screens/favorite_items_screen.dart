import 'package:flutter/material.dart';
import '../models/favorite_item.dart';
import '../services/favorite_items_service.dart';
import '../utils/app_theme.dart';
import '../widgets/favorite_item_image.dart';

class FavoriteItemsScreen extends StatefulWidget {
  const FavoriteItemsScreen({super.key});

  @override
  State<FavoriteItemsScreen> createState() => _FavoriteItemsScreenState();
}

class _FavoriteItemsScreenState extends State<FavoriteItemsScreen> {
  List<FavoriteItem> _favoriteItems = [];
  List<FavoriteItem> _filteredItems = [];
  FavoriteSortCriteria _currentSortCriteria = FavoriteSortCriteria.mostUsed;
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteItems();
    _loadSortPreference();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFavoriteItems() async {
    setState(() => _isLoading = true);
    final items = await FavoriteItemsService.getSortedFavoriteItems(_currentSortCriteria);
    setState(() {
      _favoriteItems = items;
      _filteredItems = items;
      _isLoading = false;
    });
  }

  void _loadSortPreference() async {
    final criteria = await FavoriteItemsService.loadFavoriteSortPreference();
    setState(() => _currentSortCriteria = criteria);
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _favoriteItems.where((item) =>
        item.name.toLowerCase().contains(query)
      ).toList();
    });
  }

  void _updateSortCriteria(FavoriteSortCriteria criteria) async {
    setState(() => _currentSortCriteria = criteria);
    await FavoriteItemsService.saveFavoriteSortPreference(criteria);
    _loadFavoriteItems();
  }

  void _deleteFavoriteItem(FavoriteItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Favorito'),
        content: Text('Remover "${item.name}" dos favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FavoriteItemsService.removeFavoriteItem(item.id);
      _loadFavoriteItems();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} removido dos favoritos'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _editFavoriteItem(FavoriteItem item) async {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(
      text: item.defaultPrice > 0 ? item.defaultPrice.toStringAsFixed(2) : '',
    );
    int selectedQuantity = item.defaultQuantity;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Favorito'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Produto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Preço Padrão',
                    prefixText: '€ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedQuantity,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade Padrão',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(20, (index) => index + 1)
                      .map((quantity) => DropdownMenuItem<int>(
                            value: quantity,
                            child: Text('$quantity'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedQuantity = value ?? 1;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final price = double.tryParse(
                    priceController.text.replaceAll(',', '.').replaceAll('€', '').trim(),
                  ) ?? 0.0;
                  
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'price': price,
                    'quantity': selectedQuantity,
                  });
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      // Atualizar o item favorito
      item.name = result['name'];
      item.defaultPrice = result['price'];
      item.defaultQuantity = result['quantity'];
      
      await FavoriteItemsService.saveFavoriteItems(_favoriteItems);
      _loadFavoriteItems();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} atualizado'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  void _clearAllFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Favoritos'),
        content: const Text('Remover todos os itens favoritos? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar Tudo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FavoriteItemsService.clearAllFavorites();
      _loadFavoriteItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os favoritos foram removidos'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _getSortLabel(FavoriteSortCriteria criteria) {
    switch (criteria) {
      case FavoriteSortCriteria.alphabetical:
        return 'A-Z';
      case FavoriteSortCriteria.mostUsed:
        return 'Mais Usados';
      case FavoriteSortCriteria.recentlyUsed:
        return 'Recentes';
      case FavoriteSortCriteria.recentlyAdded:
        return 'Adicionados';
      case FavoriteSortCriteria.priceAscending:
        return 'Preço ↑';
      case FavoriteSortCriteria.priceDescending:
        return 'Preço ↓';
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
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            const Text('Itens Favoritos'),
          ],
        ),
        actions: [
          if (_favoriteItems.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_all') {
                  _clearAllFavorites();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Limpar Todos'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Barra de busca e filtros
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar favoritos...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppTheme.softGrey,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Container(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: FavoriteSortCriteria.values.map((criteria) {
                      final isSelected = criteria == _currentSortCriteria;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
                        child: FilterChip(
                          label: Text(
                            _getSortLabel(criteria),
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.primaryGreen,
                              fontSize: AppConstants.fontSmall,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => _updateSortCriteria(criteria),
                          selectedColor: AppTheme.primaryGreen,
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de favoritos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : _buildFavoritesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingXLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
                boxShadow: const [AppStyles.softShadow],
              ),
              child: Column(
                children: [
                  Icon(
                    _searchController.text.isNotEmpty 
                        ? Icons.search_off 
                        : Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    _searchController.text.isNotEmpty 
                        ? 'Nenhum favorito encontrado'
                        : 'Nenhum item favorito ainda',
                    style: AppStyles.headingMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    _searchController.text.isNotEmpty 
                        ? 'Tente buscar por outro termo'
                        : 'Adicione itens aos favoritos ao criar listas de compras para acesso rápido',
                    style: AppStyles.bodyMedium.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Text(
              '${_filteredItems.length} item${_filteredItems.length != 1 ? 's' : ''} favorito${_filteredItems.length != 1 ? 's' : ''}',
              style: AppStyles.captionGrey,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return _buildFavoriteItemCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItemCard(FavoriteItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Row(
            children: [
              FavoriteItemImage(
                imagePath: item.imagePath,
                width: 56,
                height: 56,
                borderRadius: AppConstants.radiusMedium,
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.defaultPrice > 0) ...[
                          Text(
                            '€${item.defaultPrice.toStringAsFixed(2)}',
                            style: AppStyles.captionGrey.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                        ],
                        Text(
                          'Qtd: ${item.defaultQuantity}',
                          style: AppStyles.captionGrey,
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${item.usageCount} usos',
                          style: AppStyles.captionGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _editFavoriteItem(item),
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    onPressed: () => _deleteFavoriteItem(item),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    tooltip: 'Remover',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: const Icon(
        Icons.shopping_basket,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
