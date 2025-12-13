import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scanned_item.dart';
import '../models/favorite_item.dart';
import '../services/barcode_service.dart';
import '../services/favorite_items_service.dart';
import '../services/app_settings_service.dart';
import '../providers/app_settings_provider.dart';
import '../utils/app_theme.dart';
import '../services/snackbar_service.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<ScannedItem> _scannedItems = [];
  List<FavoriteItem> _favoriteItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Carregar itens escaneados do banco de dados
    final scannedItems = await BarcodeService.getAllScannedItems();
    
    // Carregar itens favoritos
    final favoriteItems = await FavoriteItemsService.loadFavoriteItems();
    
    setState(() {
      _scannedItems = scannedItems;
      _favoriteItems = favoriteItems;
      _isLoading = false;
    });
  }

  void _deleteScannedItem(ScannedItem item) async {
    final confirmed = await _showDeleteConfirmationDialog(
      'Remover Item Escaneado',
      'Remover "${item.name}" dos itens salvos?',
    );

    if (confirmed == true) {
      await BarcodeService.removeScannedItem(item.id);
      _loadData(); // Recarregar os dados
      _showSnackBar('${item.name} removido dos itens salvos');
    }
  }

  void _deleteFavoriteItem(FavoriteItem item) async {
    final confirmed = await _showDeleteConfirmationDialog(
      'Remover Favorito',
      'Remover "${item.name}" dos favoritos?',
    );

    if (confirmed == true) {
      await FavoriteItemsService.removeFavoriteItem(item.id);
      _loadData();
      _showSnackBar('${item.name} removido dos favoritos');
    }
  }

  void _clearAllScannedItems() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'Limpar Todos os Itens',
      'Remover todos os itens escaneados? Esta ação não pode ser desfeita.',
    );

    if (confirmed == true) {
      await BarcodeService.clearAllScannedItems();
      _loadData(); // Recarregar os dados
      _showSnackBar('Todos os itens escaneados foram removidos');
    }
  }

  void _clearAllFavorites() async {
    final confirmed = await _showDeleteConfirmationDialog(
      'Limpar Todos os Favoritos',
      'Remover todos os itens favoritos? Esta ação não pode ser desfeita.',
    );

    if (confirmed == true) {
      await FavoriteItemsService.clearAllFavorites();
      _loadData();
      _showSnackBar('Todos os favoritos foram removidos');
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(
                Icons.warning_amber,
                color: AppTheme.warningRed,
                size: AppConstants.iconMedium,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
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
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    SnackBarService.success(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.white,
                size: AppConstants.iconMedium,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            const Text('Configurações'),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.qr_code),
              text: 'Itens Salvos',
            ),
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Favoritos',
            ),
            Tab(
              icon: Icon(Icons.tune),
              text: 'Preferências',
            ),
          ],
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryGreen,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScannedItemsTab(),
                _buildFavoriteItemsTab(),
                _buildPreferencesTab(),
              ],
            ),
    );
  }

  Widget _buildScannedItemsTab() {
    return Column(
      children: [
        if (_scannedItems.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            child: ElevatedButton.icon(
              onPressed: _clearAllScannedItems,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpar Todos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
              ),
            ),
          ),
        Expanded(
          child: _scannedItems.isEmpty
              ? _buildEmptyState(
                  icon: Icons.qr_code_scanner,
                  title: 'Nenhum item salvo',
                  message: 'Itens escaneados via QR code aparecerão aqui',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: _scannedItems.length,
                  itemBuilder: (context, index) {
                    final item = _scannedItems[index];
                    return _buildScannedItemCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFavoriteItemsTab() {
    return Column(
      children: [
        if (_favoriteItems.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            child: ElevatedButton.icon(
              onPressed: _clearAllFavorites,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpar Todos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
              ),
            ),
          ),
        Expanded(
          child: _favoriteItems.isEmpty
              ? _buildEmptyState(
                  icon: Icons.favorite_border,
                  title: 'Nenhum favorito',
                  message: 'Itens favoritos aparecerão aqui',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: _favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = _favoriteItems[index];
                    return _buildFavoriteItemCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
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
                    icon,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    title,
                    style: AppStyles.headingMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    message,
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

  Widget _buildScannedItemCard(ScannedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: const Icon(
                Icons.qr_code,
                color: Color(0xFF2196F3),
                size: AppConstants.iconLarge,
              ),
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
                      Text(
                        item.formattedPrice,
                        style: AppStyles.captionGrey.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text(
                        'Qtd: ${item.quantity}',
                        style: AppStyles.captionGrey,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text(
                        item.formattedDate,
                        style: AppStyles.captionGrey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Código: ${item.barcode}',
                    style: AppStyles.captionGrey.copyWith(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _deleteScannedItem(item),
              icon: Icon(
                Icons.delete_outline,
                color: Colors.grey[600],
                size: AppConstants.iconMedium,
              ),
              tooltip: 'Remover',
            ),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: AppTheme.primaryGreen,
                size: 28,
              ),
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
                        Consumer<AppSettingsProvider>(
                          builder: (context, settingsProvider, child) {
                            return FutureBuilder<String>(
                              future: settingsProvider.formatPriceWithConversion(item.defaultPrice),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(
                                    snapshot.data!,
                                    style: AppStyles.captionGrey.copyWith(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }
                                return Text(
                                  '${settingsProvider.primaryCurrency.symbol} ${item.defaultPrice.toStringAsFixed(2)}',
                                  style: AppStyles.captionGrey.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            );
                          },
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
            IconButton(
              onPressed: () => _deleteFavoriteItem(item),
              icon: Icon(
                Icons.delete_outline,
                color: Colors.grey[600],
                size: AppConstants.iconMedium,
              ),
              tooltip: 'Remover',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return Consumer<AppSettingsProvider>(
      builder: (context, settingsProvider, child) {
        if (!settingsProvider.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção Moeda 
              _buildPreferenceSection(
                icon: Icons.paid,
                title: 'Moeda',
                child: _buildPrimaryCurrencySelector(settingsProvider),
              ),
              
              // Espaço extra no final para evitar overflow
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreferenceSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: AppConstants.iconSmall,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Text(
                title,
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          child,
        ],
      ),
    );
  }
  Widget _buildPrimaryCurrencySelector(AppSettingsProvider settingsProvider) {
    return Column(
      children: Currency.values.where((currency) => currency != Currency.none).map((currency) {
        final isSelected = settingsProvider.primaryCurrency == currency;
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
          child: RadioListTile<Currency>(
            title: Text(
              currency.displayName,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              'Símbolo: ${currency.symbol}',
              style: AppStyles.captionGrey.copyWith(
                color: isSelected ? AppTheme.primaryGreen : Colors.grey,
              ),
            ),
            value: currency,
            groupValue: settingsProvider.primaryCurrency,
            activeColor: AppTheme.primaryGreen,
            onChanged: (Currency? value) async {
              if (value != null) {
                await settingsProvider.setPrimaryCurrency(value);
                _showSnackBar('Moeda alterada para ${value.displayName}');
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
