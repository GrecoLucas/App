import 'dart:io';
import 'package:flutter/material.dart';
import '../models/favorite_item.dart';
import '../services/favorite_items_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cyclic_quantity_selector.dart';
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
    
    if (mounted) {
      setState(() {
        _favoriteItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    }
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
    setState(() {
      if (_selectedItems.containsKey(item.id)) {
        _selectedItems.remove(item.id);
      } else {
        _selectedItems[item.id] = FavoriteItemSelection(
          favoriteItem: item,
          price: item.defaultPrice,
          quantity: item.defaultQuantity,
        );
      }
    });
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
        final name = selection.favoriteItem.name.length > 24 
            ? selection.favoriteItem.name.substring(0, 24) 
            : selection.favoriteItem.name;
            
        return {
          'name': name,
          'price': selection.price,
          'quantity': selection.quantity,
        };
      }).toList();

      // Incrementa o uso dos itens selecionados
      for (final selection in _selectedItems.values) {
        await FavoriteItemsService.incrementItemUsage(selection.favoriteItem.name);
      }

      widget.onItemsSelected(itemsToAdd);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.5,
        maxHeight: screenHeight * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: bottomPadding + AppConstants.getResponsivePadding(context, AppConstants.paddingSmall),
        top: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
        left: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
        right: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle visual
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Icon(
                  Icons.playlist_add,
                  color: Colors.white,
                  size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                ),
              ),
              SizedBox(width: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicionar Favoritos',
                      style: AppStyles.headingMedium.copyWith(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.headingMedium.fontSize! * 1.1),
                      ),
                    ),
                    if (_selectedItems.isNotEmpty)
                      Text(
                        '${_selectedItems.length} selecionado(s)',
                        style: AppStyles.captionGrey.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),
          _buildSearchBar(),
          SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredItems.isEmpty 
                ? _buildEmptyState()
                : _buildFavoritesList(),
          ),

          if (_selectedItems.isNotEmpty) ...[
            SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),
            _buildActionButtons(context),
          ],
        ],
      ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(height: 16),
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
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isSelected = _selectedItems.containsKey(item.id);
        return _buildFavoriteItemCard(item, isSelected);
      },
    );
  }

  Widget _buildFavoriteItemCard(FavoriteItem item, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Checkbox customizado
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryGreen : Colors.grey[400]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isSelected 
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                    ),
                    const SizedBox(width: 12),
                    
                    // Ícone do item
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppTheme.softGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shopping_basket,
                        color: isSelected ? AppTheme.primaryGreen : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Informações
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppStyles.bodyLarge.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppTheme.darkGreen : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Qtd: ${item.defaultQuantity}',
                                style: AppStyles.captionGrey,
                              ),
                              if (item.defaultPrice > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '€${item.defaultPrice.toStringAsFixed(2)}',
                                  style: AppStyles.captionGrey.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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

  Widget _buildEditControls(FavoriteItem item) {
    final selection = _selectedItems[item.id]!;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1, // Redução de flex para 1 para dividir o espaço uniformemente e evitar overflow
            child: TextFormField(
              initialValue: selection.price > 0 ? selection.price.toStringAsFixed(2) : '',
              decoration: InputDecoration(
                labelText: 'Preço',
                prefixText: '€ ',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final price = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                _updateSelectedItem(item.id, price, selection.quantity);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CyclicQuantitySelector(
              value: selection.quantity,
              height: 48, // Alinha com a altura do campo de texto
              onChanged: (value) {
                _updateSelectedItem(item.id, selection.price, value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _addSelectedItems,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          elevation: 2,
        ),
        child: Text(
          'Adicionar ${_selectedItems.length} item(s) - Total: €${_selectedItems.values.fold<double>(0.0, (sum, s) => sum + (s.price * s.quantity)).toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
