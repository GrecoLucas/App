import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/list.dart';
import '../models/item.dart';

import '../utils/app_theme.dart';
import '../widgets/enhanced_add_product_dialog.dart';
import '../widgets/enhanced_product_card.dart';
import '../widgets/quick_add_favorites_dialog.dart';
import '../widgets/sort_options_widget.dart';
import '../services/storage_service.dart';
import '../services/snackbar_service.dart';
import '../services/pantry_service.dart';
import '../providers/app_settings_provider.dart';
import 'barcode_scanner_screen.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;
  final VoidCallback onUpdate;

  const ShoppingListDetailScreen({
    super.key,
    required this.shoppingList,
    required this.onUpdate,
  });

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {

  SortCriteria _currentSortCriteria = SortCriteria.smart;
  double _itemScale = 1.0;
  int _currentTab = 0; // 0: Comprando, 1: Comprado

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Função para o pull-to-refresh
  Future<void> _handleRefresh() async {
    widget.onUpdate();
  }

  // Carrega a preferência de ordenação salva
  void _loadSortPreference() async {
    final sortCriteria = await StorageService.loadSortPreference();
    setState(() {
      _currentSortCriteria = sortCriteria;
    });
  }

  // Atualiza o critério de ordenação
  void _updateSortCriteria(SortCriteria criteria) async {
    setState(() {
      _currentSortCriteria = criteria;
    });
    await StorageService.saveSortPreference(criteria);
  }

  void _updateItemScale(double newScale) {
    setState(() {
      _itemScale = newScale;
    });
  }

  // Adiciona um novo produto à lista
  void _addProduct() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddProductDialog(),
    );
    
    if (result != null) {
      final newItem = Item(
        name: result['name'], 
        price: result['price'],
        quantity: result['quantity'] ?? 1,
      );
      
      // Lista local apenas - adicionar diretamente
      setState(() {
        widget.shoppingList.addItem(newItem);
      });
      
      widget.onUpdate();
    }
  }

  // Edita um produto da lista
  void _editProduct(Item item) async {
    // Encontrar o índice atual do item na lista original
    final index = widget.shoppingList.items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      print('Item não encontrado na lista: ${item.id}');
      return;
    }
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductDialog(
        initialName: item.name,
        initialPrice: item.price,
        initialQuantity: item.quantity,
        isEditing: true,
      ),
    );
    
    if (result != null) {
      // Lista local apenas - aplicar mudanças diretamente
      setState(() {
        final itemToUpdate = widget.shoppingList.items.firstWhere((i) => i.id == item.id);
        itemToUpdate.name = result['name'];
        itemToUpdate.price = result['price'];
        itemToUpdate.quantity = result['quantity'] ?? 1;
      });
      
      widget.onUpdate();
    }
  }

  // Alterna o estado de conclusão de um item
  void _toggleItemCompletion(Item item) {
    setState(() {
      item.isCompleted = !item.isCompleted;
    });
    
    if (item.isCompleted) {
      SnackBarService.success(context, 'Adicionado do carrinho');
    } else {
      SnackBarService.success(context, 'Removido do carrinho');
    }
    
    widget.onUpdate();
  }

  // Envia itens marcados para a despensa (agora apenas os do carrinho que ainda não foram)
  void _addCheckedToPantry() async {
    final checkedItems = widget.shoppingList.items.where((i) => i.isCompleted && !i.isAddedToPantry).toList();
    
    if (checkedItems.isEmpty) {
      if (mounted) {
        SnackBarService.warning(context, 'Todos os itens do carrinho já foram adicionados à despensa');
      }
      return;
    }

    final count = await PantryService.addItemsFromList(checkedItems);
    
    // Marcar como enviados localmente
    setState(() {
      for (var item in checkedItems) {
        item.isAddedToPantry = true;
      }
    });
    
    if (mounted) {
      SnackBarService.success(context, '$count itens enviados para a despensa!');
    }
  }






  // Remove um produto da lista
  void _removeProduct(Item item) async {
    // Encontrar o índice atual do item na lista original
    final index = widget.shoppingList.items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      print('Item não encontrado na lista: ${item.id}');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                  Icons.delete_outline,
                  color: AppTheme.warningRed,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              const Text('Remover'),
            ],
          ),
          content: Text(
            'Remover "${item.name}" da lista?',
            style: AppStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Lista local apenas - remover diretamente
                setState(() {
                  widget.shoppingList.items.removeWhere((i) => i.id == item.id);
                });
                
                widget.onUpdate();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
  }

  // Adiciona múltiplos produtos favoritos à lista
  void _addFavoriteProducts() async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickAddFavoritesDialog(
        onItemsSelected: (items) async {
          if (items.isEmpty) return;
          
          List<Item> newItems = items.map((data) => Item(
            name: data['name'],
            price: data['price'],
            quantity: data['quantity'],
          )).toList();
          
          // Lista local apenas - adicionar diretamente
          setState(() {
            for (final item in newItems) {
              widget.shoppingList.addItem(item);
            }
          });
          
          widget.onUpdate();
          
          SnackBarService.success(context, '${items.length} item${items.length != 1 ? 's' : ''} adicionado${items.length != 1 ? 's' : ''} da lista de favoritos');
        },
      ),
    );
  }

  // Adiciona produto via scanner de código de barras
  void _addProductViaScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          onItemScanned: (scannedItem) {
            final name = scannedItem.name.length > 24 
                ? scannedItem.name.substring(0, 24) 
                : scannedItem.name;
            
            final newItem = Item(
              name: name,
              price: scannedItem.price,
              quantity: scannedItem.quantity,
            );
            
            // Lista local apenas - adicionar diretamente
            setState(() {
              widget.shoppingList.addItem(newItem);
            });
            
            widget.onUpdate();
          },
        ),
      ),
    );
  }

  Widget _buildBudgetProgress() {
    final budget = widget.shoppingList.budget!;
    final totalPrice = widget.shoppingList.totalPrice;
    final isExceeded = totalPrice > budget;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.darkGreen,
                  size: AppConstants.iconSmall,
                ),
                const SizedBox(width: 4),
                Text(
                  'Orçamento:',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkGreen,
                  ),
                ),
              ],
            ),
            Text(
              isExceeded 
                  ? '${totalPrice.toStringAsFixed(2)}/${budget.toStringAsFixed(2)}'
                  : '${totalPrice.toStringAsFixed(2)}/${budget.toStringAsFixed(2)}',
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isExceeded ? AppTheme.warningRed : AppTheme.darkGreen,
              ),
            ),
          ],
        ),
      ],
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
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(Icons.shopping_basket, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Text(
                widget.shoppingList.name,
                style: AppStyles.headingMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.shoppingList.items.isNotEmpty) ...[
            // Menu de Densidade/Tamanho dos Itens
            PopupMenuButton<double>(
              icon: const Icon(Icons.unfold_more, color: AppTheme.primaryGreen),
              tooltip: 'Visualização da lista',
              onSelected: _updateItemScale,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 0.8,
                  child: Row(
                    children: [
                      Icon(Icons.view_headline, size: 18),
                      SizedBox(width: 8),
                      Text('Compacto'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 1.0,
                  child: Row(
                    children: [
                      Icon(Icons.view_agenda, size: 18),
                      SizedBox(width: 8),
                      Text('Padrão'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 1.25,
                  child: Row(
                    children: [
                      Icon(Icons.view_stream, size: 18),
                      SizedBox(width: 8),
                      Text('Expandido'),
                    ],
                  ),
                ),
              ],
            ),
            SortOptionsWidget(
              currentCriteria: _currentSortCriteria,
              onSortChanged: _updateSortCriteria,
            ),
          ],
          const SizedBox(width: AppConstants.paddingSmall),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          _buildTabButtons(),
          Expanded(
            child: widget.shoppingList.items.isEmpty
                ? _buildEmptyState()
                : _buildProductsList(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'scanner_fab',
          onPressed: _addProductViaScanner,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.qr_code_scanner, color: Colors.white),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'add_fab',
          onPressed: _addProduct,
          backgroundColor: AppTheme.primaryGreen,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'favorites_fab',
          onPressed: _addFavoriteProducts,
          backgroundColor: AppTheme.warningRed,
          child: const Icon(Icons.favorite, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTabButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.softShadow], 
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(0, 'Na prateleira', Icons.storefront),
          ),
          Container(width: 1, height: 24, color: Colors.grey[300]),
          Expanded(
            child: _buildTabButton(1, 'No carrinho', Icons.shopping_cart),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _currentTab == index;
    final count = index == 0 
        ? widget.shoppingList.items.where((i) => !i.isCompleted).length
        : widget.shoppingList.items.where((i) => i.isCompleted).length;

    return InkWell(
      onTap: () => setState(() => _currentTab = index),
      borderRadius: index == 0 
          ? const BorderRadius.horizontal(left: Radius.circular(AppConstants.radiusLarge))
          : const BorderRadius.horizontal(right: Radius.circular(AppConstants.radiusLarge)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightGreen : Colors.transparent,
          borderRadius: index == 0 
              ? const BorderRadius.horizontal(left: Radius.circular(AppConstants.radiusLarge))
              : const BorderRadius.horizontal(right: Radius.circular(AppConstants.radiusLarge)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primaryGreen : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              '$label ($count)',
              style: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduzido margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppStyles.softShadow], // Sombra mais leve
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduzido padding
        child: Column(
          children: [
            // Linha única: Preço Total + Info Orçamento + Contagem
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Esquerda: Totais e Orçamento
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                           Text(
                            'Total: ',
                            style: AppStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                          ),
                          Consumer<AppSettingsProvider>(
                            builder: (context, settingsProvider, child) {
                              return FutureBuilder<String>(
                                future: settingsProvider.formatPriceWithConversion(widget.shoppingList.totalPrice),
                                builder: (context, snapshot) {
                                  final price = snapshot.data ?? settingsProvider.formatPriceSync(widget.shoppingList.totalPrice);
                                  return Text(
                                    price,
                                    style: AppStyles.headingMedium.copyWith(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      
                      // Info Orçamento Compacta
                      if (widget.shoppingList.budget != null) ...[
                        const SizedBox(height: 2),
                        Consumer<AppSettingsProvider>(
                          builder: (context, settingsProvider, child) {
                            final remainingBudget = widget.shoppingList.remainingBudget;
                            final isBudgetExceeded = widget.shoppingList.isBudgetExceeded;
                            
                            return FutureBuilder<String>(
                              future: settingsProvider.formatPriceWithConversion(remainingBudget.abs()),
                              builder: (context, snapshot) {
                                final val = snapshot.data ?? settingsProvider.formatPriceSync(remainingBudget.abs());
                                final displayText = isBudgetExceeded ? '$val acima' : '$val restante';
                                
                                return Text(
                                  displayText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isBudgetExceeded ? AppTheme.warningRed : AppTheme.darkGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Direita: Contagem de Itens (Badge Style)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.softGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.shoppingList.items.length}',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Barra de progreço do Orçamento (se houver)
            if (widget.shoppingList.budget != null) ...[
              const SizedBox(height: 12),
              _buildBudgetProgress(),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppTheme.primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
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
                            Container(
                              padding: const EdgeInsets.all(AppConstants.paddingLarge),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGreen,
                                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                              ),
                              child: Icon(
                                Icons.shopping_basket_outlined,
                                size: AppConstants.iconXLarge,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingLarge),
                            const Text(
                              'Lista vazia',
                              style: AppStyles.headingMedium,
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            const Text(
                              'Adicione produtos à sua lista de compras',
                              style: AppStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            const Text(
                              'Toque em "Adicionar" para começar!\n\nPuxe para baixo para atualizar.',
                              style: AppStyles.captionGrey,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

Widget _buildProductsList() {
    final sortedItems = widget.shoppingList.getSortedItems(_currentSortCriteria);
    final filteredItems = sortedItems.where((item) {
      if (_currentTab == 0) return !item.isCompleted;
      return item.isCompleted;
    }).toList();
    
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentTab == 0 ? Icons.shopping_cart_outlined : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _currentTab == 0 ? 'Tudo no carrinho!' : 'Nenhum item no carrinho',
              style: AppStyles.bodyLarge.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.primaryGreen,
      child: Column(
        children: [
          // Botão "Adicionar à Despensa" (Apenas na aba Carrinho e se houver itens válidos)
          if (_currentTab == 1) ...[
             Builder(
               builder: (context) {
                 final itemsToSend = filteredItems.where((i) => !i.isAddedToPantry).toList();
                 if (itemsToSend.isEmpty) return const SizedBox.shrink();

                 return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addCheckedToPantry,
                      icon: const Icon(Icons.kitchen, color: Colors.white),
                      label: Text(
                        'Adicionar itens na dispensa (${itemsToSend.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                );
               }
             ),
          ],
            
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredItems.length,
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge).copyWith(bottom: 100, top: 8),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                
                // Se o seu EnhancedProductCard aceitar uma escala de texto:
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(_itemScale),
                  ),
                  child: EnhancedProductCard(
                    item: item,
                    onEdit: () => _editProduct(item),
                    onDelete: () => _removeProduct(item),
                    onToggle: () => _toggleItemCompletion(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
