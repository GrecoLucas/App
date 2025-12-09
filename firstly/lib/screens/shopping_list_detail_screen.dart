import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/list.dart';
import '../models/item.dart';
import '../models/scanned_item.dart';
import '../utils/app_theme.dart';
import '../widgets/enhanced_add_product_dialog.dart';
import '../widgets/enhanced_product_card.dart';
import '../widgets/quick_add_favorites_dialog.dart';
import '../widgets/sort_options_widget.dart';
import '../services/storage_service.dart';
import '../services/storage_service.dart';
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
  // Adiciona um novo produto à lista
  void _addProduct() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Marcado como comprado'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    
    widget.onUpdate();
  }

  // Alterna o estado de todos os itens
  void _toggleAllItems() {
    final allCompleted = widget.shoppingList.items.every((item) => item.isCompleted);
    
    setState(() {
      for (var item in widget.shoppingList.items) {
        item.isCompleted = !allCompleted;
      }
    });
    
    widget.onUpdate();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(allCompleted ? 'Todos os itens desmarcados' : 'Todos os itens marcados'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  // Envia itens marcados para a despensa
  void _addCheckedToPantry() async {
    final checkedItems = widget.shoppingList.items.where((i) => i.isCompleted).toList();
    
    if (checkedItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marque itens para enviar à despensa'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final count = await PantryService.addItemsFromList(checkedItems);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count itens enviados para a despensa!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              const Text('Remover Produto'),
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
    showDialog<void>(
      context: context,
      builder: (context) => QuickAddFavoritesDialog(
        onItemsSelected: (items) async {
          print('Recebidos ${items.length} itens favoritos: $items');
          List<Item> newItems = [];
          
            // Lista local apenas - adicionar diretamente
            setState(() {
              for (final item in newItems) {
                widget.shoppingList.addItem(item);
              }
            });
            
            widget.onUpdate();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${items.length} item${items.length != 1 ? 's' : ''} adicionado${items.length != 1 ? 's' : ''} da lista de favoritos'),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          },
      ),
    );
  }


  // Adiciona produto via scanner de código de barras
  void _addProductViaScanner() async {
    final scannedItem = await Navigator.push<ScannedItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (scannedItem != null) {
      final newItem = Item(
        name: scannedItem.name,
        price: scannedItem.price,
        quantity: scannedItem.quantity,
      );
      
      // Lista local apenas - adicionar diretamente
      setState(() {
        widget.shoppingList.addItem(newItem);
      });
      
      widget.onUpdate();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${scannedItem.name} adicionado via scanner'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Widget _buildBudgetProgress() {
    final budget = widget.shoppingList.budget!;
    final totalPrice = widget.shoppingList.totalPrice;
    final percentage = (totalPrice / budget).clamp(0.0, 1.0);
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
        const SizedBox(height: AppConstants.paddingSmall),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage > 1.0 ? 1.0 : percentage,
            child: Container(
              decoration: BoxDecoration(
                gradient: isExceeded 
                    ? LinearGradient(
                        colors: [AppTheme.warningRed, AppTheme.warningRed.withOpacity(0.8)],
                      )
                    : LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                      ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        if (isExceeded) ...[
          const SizedBox(height: AppConstants.paddingSmall),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.warningRed.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ((totalPrice - budget) / budget).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.warningRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
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
              child: const Icon(
                Icons.shopping_basket,
                color: Colors.white,
                size: 20,
              ),
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
            IconButton(
              icon: Icon(
                widget.shoppingList.items.every((i) => i.isCompleted) 
                    ? Icons.remove_done
                    : Icons.done_all,
                color: AppTheme.primaryGreen,
              ),
              onPressed: _toggleAllItems,
              tooltip: widget.shoppingList.items.every((i) => i.isCompleted)
                  ? 'Desmarcar todos'
                  : 'Marcar todos',
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
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: widget.shoppingList.items.isEmpty
                ? _buildEmptyState()
                : _buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.mediumShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.euro,
                          color: AppTheme.primaryGreen,
                          size: AppConstants.iconSmall,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Total da Lista:',
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Consumer<AppSettingsProvider>(
                      builder: (context, settingsProvider, child) {
                        return FutureBuilder<String>(
                          future: settingsProvider.formatPriceWithConversion(widget.shoppingList.totalPrice),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                snapshot.data!,
                                style: AppStyles.headingLarge.copyWith(
                                  color: AppTheme.primaryGreen,
                                ),
                              );
                            }
                            return Text(
                              '€${widget.shoppingList.totalPrice.toStringAsFixed(2)}',
                              style: AppStyles.headingLarge.copyWith(
                                color: AppTheme.primaryGreen,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    // Mostrar progresso do orçamento se definido
                    if (widget.shoppingList.budget != null) ...[
                      const SizedBox(height: AppConstants.paddingSmall),
                      Consumer<AppSettingsProvider>(
                        builder: (context, settingsProvider, child) {
                          final remainingBudget = widget.shoppingList.remainingBudget;
                          final isBudgetExceeded = widget.shoppingList.isBudgetExceeded;
                          
                          return FutureBuilder<String>(
                            future: settingsProvider.formatPriceWithConversion(remainingBudget.abs()),
                            builder: (context, snapshot) {
                              String displayText;
                              if (snapshot.hasData) {
                                displayText = isBudgetExceeded 
                                    ? '${snapshot.data} acima do orçamento'
                                    : '${snapshot.data} restante';
                              } else {
                                displayText = isBudgetExceeded
                                    ? '€${remainingBudget.abs().toStringAsFixed(2)} acima do orçamento'
                                    : '€${remainingBudget.toStringAsFixed(2)} restante';
                              }
                              
                              return Text(
                                displayText,
                                style: AppStyles.captionGrey.copyWith(
                                  color: isBudgetExceeded
                                      ? AppTheme.warningRed
                                      : AppTheme.darkGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: AppConstants.iconMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.shoppingList.items.length}',
                        style: AppStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.shoppingList.items.length == 1 ? 'produto' : 'produtos',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Mostrar barra de progresso do orçamento se definido
            if (widget.shoppingList.budget != null) ...[
              const SizedBox(height: AppConstants.paddingLarge),
              _buildBudgetProgress(),
            ],
            // Botões de ação fixos
            const SizedBox(height: AppConstants.paddingLarge),
            // Primeira linha de botões
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addFavoriteProducts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.favorite, size: 18),
                    label: const Text('Favoritos'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addProductViaScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Scanner'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            
            // Segunda linha de botões
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addCheckedToPantry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.kitchen, size: 18),
                    label: const Text('Despensa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
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
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final sortedItems = widget.shoppingList.getSortedItems(_currentSortCriteria);
    
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.primaryGreen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            final item = sortedItems[index];
            
            return EnhancedProductCard(
              item: item,
              onEdit: () => _editProduct(item),
              onDelete: () => _removeProduct(item),
              onToggle: () => _toggleItemCompletion(item),
            );
          },
        ),
      ),
    );
  }
}


