import 'dart:io';
import 'package:flutter/material.dart';
import '../models/favorite_item.dart';
import '../services/favorite_items_service.dart';
import '../utils/app_theme.dart';
import 'favorite_item_image.dart';

class FavoriteItemsDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onItemSelected;

  const FavoriteItemsDialog({
    super.key,
    required this.onItemSelected,
  });

  @override
  State<FavoriteItemsDialog> createState() => _FavoriteItemsDialogState();
}

class _FavoriteItemsDialogState extends State<FavoriteItemsDialog> {
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
    await FavoriteItemsService.removeFavoriteItem(item.id);
    _loadFavoriteItems();
  }

  void _selectItem(FavoriteItem item) async {
    await FavoriteItemsService.incrementItemUsage(item.name);
    widget.onItemSelected(item.toItemData());
    Navigator.of(context).pop();
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
            _buildSortOptions(),
            SizedBox(height: AppConstants.paddingMedium),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty 
                  ? _buildEmptyState()
                  : _buildFavoritesList(),
            ),
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
            Icons.favorite,
            color: Colors.white,
            size: 24,
          ),
        ),
        SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          child: Text(
            'Itens Favoritos',
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

  Widget _buildSortOptions() {
    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: FavoriteSortCriteria.values.map((criteria) {
          final isSelected = criteria == _currentSortCriteria;
          return Padding(
            padding: EdgeInsets.only(right: AppConstants.paddingSmall),
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
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            _searchController.text.isNotEmpty 
              ? 'Tente buscar por outro termo'
              : 'Adicione itens aos favoritos para acesso rápido',
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
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
        return _buildFavoriteItemCard(item);
      },
    );
  }

  Widget _buildFavoriteItemCard(FavoriteItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectItem(item),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                FavoriteItemImage(
                  imagePath: item.imagePath,
                  width: 48,
                  height: 48,
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
                            style: AppStyles.captionGrey.copyWith(
                              color: Colors.grey[600],
                            ),
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
                            style: AppStyles.captionGrey.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteFavoriteItem(item),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  tooltip: 'Remover dos favoritos',
                ),
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
        size: 24,
      ),
    );
  }
}
