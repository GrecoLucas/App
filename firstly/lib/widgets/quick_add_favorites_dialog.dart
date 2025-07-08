import 'package:flutter/material.dart';
import '../models/favorite_item.dart';
import '../services/favorite_items_service.dart';
import '../utils/app_theme.dart';
import 'favorite_item_image.dart';

class QuickAddFavoritesDialog extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onItemsSelected;

  const QuickAddFavoritesDialog({
    super.key,
    required this.onItemsSelected,
  });

  @override
  State<QuickAddFavoritesDialog> createState() => _QuickAddFavoritesDialogState();
}

class _QuickAddFavoritesDialogState extends State<QuickAddFavoritesDialog> {
  List<FavoriteItem> _favoriteItems = [];
  Map<String, FavoriteItemSelection> _selectedItems = {};
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  List<FavoriteItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteItems();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFavoriteItems() async {
    setState(() => _isLoading = true);
    final items = await FavoriteItemsService.getSortedFavoriteItems(FavoriteSortCriteria.mostUsed);
    print('Carregados ${items.length} itens favoritos: ${items.map((e) => e.name).toList()}');
    
    setState(() {
      _favoriteItems = items;
      _filteredItems = items;
      _isLoading = false;
    });
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _favoriteItems.where((item) =>
        item.name.toLowerCase().contains(query)
      ).toList();
    });
  }

  void _toggleItemSelection(FavoriteItem item) {
    print('Toggling selection for item: ${item.name}');
    setState(() {
      if (_selectedItems.containsKey(item.id)) {
        print('Removendo item ${item.name} da seleção');
        _selectedItems.remove(item.id);
      } else {
        print('Adicionando item ${item.name} à seleção');
        _selectedItems[item.id] = FavoriteItemSelection(
          favoriteItem: item,
          price: item.defaultPrice,
          quantity: item.defaultQuantity,
        );
      }
    });
    print('Total de itens selecionados: ${_selectedItems.length}');
  }

  void _updateSelectedItem(String itemId, double price, int quantity) {
    setState(() {
      if (_selectedItems.containsKey(itemId)) {
        _selectedItems[itemId]!.price = price;
        _selectedItems[itemId]!.quantity = quantity;
      }
    });
  }

  void _addSelectedItems() async {
    if (_selectedItems.isNotEmpty) {
      final itemsToAdd = _selectedItems.values.map((selection) {
        return {
          'name': selection.favoriteItem.name,
          'price': selection.price,
          'quantity': selection.quantity,
        };
      }).toList();

      print('Adicionando ${itemsToAdd.length} itens favoritos: $itemsToAdd');

      // Incrementa o uso dos itens selecionados
      for (final selection in _selectedItems.values) {
        await FavoriteItemsService.incrementItemUsage(selection.favoriteItem.name);
      }

      widget.onItemsSelected(itemsToAdd);
      Navigator.of(context).pop();
    } else {
      print('Nenhum item selecionado para adicionar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      child: Container(
        height: dialogHeight,
        width: double.maxFinite,
        padding: EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: AppConstants.paddingMedium),
            _buildSearchBar(),
            SizedBox(height: AppConstants.paddingMedium),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty 
                  ? _buildEmptyState()
                  : _buildFavoritesList(),
            ),
            if (_selectedItems.isNotEmpty) ...[
              SizedBox(height: AppConstants.paddingMedium),
              _buildSelectedItemsPreview(),
              SizedBox(height: AppConstants.paddingMedium),
            ],
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          ),
          child: const Icon(
            Icons.playlist_add,
            color: Colors.white,
            size: 24,
          ),
        ),
        SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          child: Text(
            'Adicionar Favoritos',
            style: AppStyles.headingMedium,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: AppConstants.paddingMedium),
          Text(
            _searchController.text.isNotEmpty 
              ? 'Nenhum favorito encontrado'
              : 'Nenhum item favorito ainda',
            style: AppStyles.bodyLarge.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isSelected = _selectedItems.containsKey(item.id);
        return _buildFavoriteItemCard(item, isSelected);
      },
    );
  }

  Widget _buildFavoriteItemCard(FavoriteItem item, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.lightGreen : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleItemSelection(item),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleItemSelection(item),
                      activeColor: AppTheme.primaryGreen,
                    ),
                    SizedBox(width: AppConstants.paddingSmall),
                    FavoriteItemImage(
                      imagePath: item.imagePath,
                      width: 40,
                      height: 40,
                      borderRadius: AppConstants.radiusSmall,
                    ),
                    SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppTheme.darkGreen : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
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
                                SizedBox(width: AppConstants.paddingSmall),
                              ],
                              Text(
                                'Qtd: ${item.defaultQuantity}',
                                style: AppStyles.captionGrey,
                              ),
                              SizedBox(width: AppConstants.paddingSmall),
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.amber[600],
                              ),
                              SizedBox(width: 2),
                              Text(
                                '${item.usageCount}',
                                style: AppStyles.captionGrey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  _buildEditControls(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: const Icon(
        Icons.shopping_basket,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildEditControls(FavoriteItem item) {
    final selection = _selectedItems[item.id]!;
    return Container(
      margin: EdgeInsets.only(top: AppConstants.paddingMedium),
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: selection.price > 0 ? selection.price.toStringAsFixed(2) : '',
              decoration: InputDecoration(
                labelText: 'Preço',
                prefixText: '€ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingSmall,
                  vertical: AppConstants.paddingSmall,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final price = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                _updateSelectedItem(item.id, price, selection.quantity);
              },
            ),
          ),
          SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selection.quantity,
              decoration: InputDecoration(
                labelText: 'Qtd',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingSmall,
                  vertical: AppConstants.paddingSmall,
                ),
              ),
              items: List.generate(20, (index) => index + 1)
                  .map((quantity) => DropdownMenuItem<int>(
                        value: quantity,
                        child: Text('$quantity'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateSelectedItem(item.id, selection.price, value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItemsPreview() {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppTheme.primaryGreen),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            color: AppTheme.primaryGreen,
            size: AppConstants.iconMedium,
          ),
          SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Text(
              '${_selectedItems.length} item${_selectedItems.length != 1 ? 's' : ''} selecionado${_selectedItems.length != 1 ? 's' : ''}',
              style: AppStyles.bodyMedium.copyWith(
                color: AppTheme.darkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'Total: €${_selectedItems.values.fold<double>(0.0, (sum, selection) => sum + (selection.price * selection.quantity)).toStringAsFixed(2)}',
            style: AppStyles.bodyMedium.copyWith(
              color: AppTheme.darkGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
        SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _selectedItems.isNotEmpty ? () {
              print('Botão "Adicionar" pressionado com ${_selectedItems.length} itens selecionados');
              _addSelectedItems();
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
            ),
            child: Text(
              'Adicionar ${_selectedItems.length} item${_selectedItems.length != 1 ? 's' : ''}',
            ),
          ),
        ),
      ],
    );
  }
}

class FavoriteItemSelection {
  final FavoriteItem favoriteItem;
  double price;
  int quantity;

  FavoriteItemSelection({
    required this.favoriteItem,
    required this.price,
    required this.quantity,
  });
}
