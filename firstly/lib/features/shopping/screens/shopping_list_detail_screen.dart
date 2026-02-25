import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/list.dart';
import '../../../core/models/item.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/enhanced_add_product_dialog.dart';
import '../widgets/enhanced_product_card.dart';
import '../../favorites/widgets/quick_add_favorites_dialog.dart';
import '../widgets/sort_options_widget.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../pantry/services/pantry_service.dart';
import '../../../services/pending_items_service.dart';
import '../../../core/models/pending_item.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../scanner/screens/barcode_scanner_screen.dart';

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
  int _globalPendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    _loadPendingCount();
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
    final remainingBudget = widget.shoppingList.remainingBudget;
    
    // Calcular progresso (0.0 a 1.0)
    double progress = 0.0;
    if (budget > 0) {
      progress = (totalPrice / budget).clamp(0.0, 1.0);
    }
    
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
                const SizedBox(width: 4),
                Text(
                  '${totalPrice.toStringAsFixed(2)}/${budget.toStringAsFixed(2)}',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isExceeded ? AppTheme.warningRed : AppTheme.darkGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Barra de progresso e texto restante (Em Horizontal usando ROW)
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isExceeded ? AppTheme.warningRed : AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Consumer<AppSettingsProvider>(
              builder: (context, settingsProvider, child) {
                return FutureBuilder<String>(
                  future: settingsProvider.formatPriceWithConversion(remainingBudget.abs()),
                  builder: (context, snapshot) {
                    final val = snapshot.data ?? settingsProvider.formatPriceSync(remainingBudget.abs());
                    final displayText = isExceeded ? '$val acima' : 'restam $val';
                    
                    return Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isExceeded ? AppTheme.warningRed : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                );
              },
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
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  // Carrega a contagem de itens pendentes globais
  void _loadPendingCount() async {
    final count = await PendingItemsService.getPendingCount();
    if (mounted) {
      setState(() {
        _globalPendingCount = count;
      });
    }
  }

  // Envia um item da lista para a lista global de pendentes (comprar mais tarde)
  void _toggleItemPending(Item item) async {
    // Criar item pendente global
    final pendingItem = PendingItem(
      name: item.name,
      price: item.price,
      quantity: item.quantity,
    );
    await PendingItemsService.addPendingItem(pendingItem);

    // Remover da lista atual
    setState(() {
      widget.shoppingList.items.removeWhere((i) => i.id == item.id);
    });
    _loadPendingCount();
    widget.onUpdate();

    if (mounted) {
      SnackBarService.success(context, '"${item.name}" movido para comprar mais tarde');
    }
  }

  // Mostra popup com itens pendentes globais
  void _showPendingItems() async {
    final pendingItems = await PendingItemsService.loadPendingItems();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PendingItemsSheet(
          initialItems: pendingItems,
          onAddToList: (PendingItem pendingItem) async {
            // Adicionar à lista atual
            final newItem = Item(
              name: pendingItem.name,
              price: pendingItem.price,
              quantity: pendingItem.quantity,
            );
            setState(() {
              widget.shoppingList.addItem(newItem);
            });
            // Remover dos pendentes globais
            await PendingItemsService.removePendingItem(pendingItem.id);
            _loadPendingCount();
            widget.onUpdate();
            if (mounted) {
              SnackBarService.success(context, '"${pendingItem.name}" adicionado à lista');
            }
          },
          onRemove: (PendingItem pendingItem) async {
            await PendingItemsService.removePendingItem(pendingItem.id);
            _loadPendingCount();
          },
          onAddAllToList: (List<PendingItem> items) async {
            for (final pendingItem in items) {
              final newItem = Item(
                name: pendingItem.name,
                price: pendingItem.price,
                quantity: pendingItem.quantity,
              );
              widget.shoppingList.addItem(newItem);
            }
            setState(() {});
            await PendingItemsService.removePendingItems(
              items.map((i) => i.id).toList(),
            );
            _loadPendingCount();
            widget.onUpdate();
            if (mounted) {
              SnackBarService.success(context, '${items.length} itens adicionados à lista');
            }
          },
        );
      },
    ).then((_) => _loadPendingCount());
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      heroTag: 'scanner_fab',
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
          // Histórico (Pendentes - Menor)
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none, // Evita cortar a notificação (bolinha vermelha)
            children: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.black54, size: 24),
                tooltip: 'Comprar mais tarde',
                onPressed: _showPendingItems,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              if (_globalPendingCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.warningRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        '$_globalPendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Favoritos (Menor)
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black54, size: 24),
            tooltip: 'Favoritos',
            onPressed: _addFavoriteProducts,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          
          const Spacer(), // Empurra para a direita
          
          // Adicionar (+) Menor ao lado do Scanner Maior
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _addProduct,
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
            child: _buildTabButton(0, 'No carrinho', Icons.shopping_cart),
          ),
          Container(width: 1, height: 24, color: Colors.grey[300]),
          Expanded(
            child: _buildTabButton(1, 'Comprado', Icons.check),
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
                      
                      // Removida informação de orçamento (Vai para baixo de tudo para não chocar com a UI)
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
                    onTogglePending: () => _toggleItemPending(item),
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

// Widget separado para o bottom sheet de itens pendentes (com estado próprio)
class _PendingItemsSheet extends StatefulWidget {
  final List<PendingItem> initialItems;
  final Future<void> Function(PendingItem) onAddToList;
  final Future<void> Function(PendingItem) onRemove;
  final Future<void> Function(List<PendingItem>) onAddAllToList;

  const _PendingItemsSheet({
    required this.initialItems,
    required this.onAddToList,
    required this.onRemove,
    required this.onAddAllToList,
  });

  @override
  State<_PendingItemsSheet> createState() => _PendingItemsSheetState();
}

class _PendingItemsSheetState extends State<_PendingItemsSheet> {
  late List<PendingItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.watch_later,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comprar mais tarde',
                        style: AppStyles.headingMedium,
                      ),
                      Text(
                        '${_items.length} ${_items.length == 1 ? 'item pendente' : 'itens pendentes'}',
                        style: AppStyles.captionGrey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Botão "Adicionar todos" (se houver itens)
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final itemsToAdd = List<PendingItem>.from(_items);
                    await widget.onAddAllToList(itemsToAdd);
                    setState(() => _items.clear());
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: Text(
                    'Adicionar todos à lista (${_items.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          // Lista de itens pendentes
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum item pendente',
                    style: AppStyles.bodyLarge.copyWith(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use os 3 pontos em um item\npara marcar como "comprar mais tarde"',
                    style: AppStyles.captionGrey,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: AppStyles.bodyLarge,
                    ),
                    subtitle: Consumer<AppSettingsProvider>(
                      builder: (context, settingsProvider, child) {
                        return Text(
                          settingsProvider.formatPriceSync(item.price * item.quantity),
                          style: AppStyles.captionGrey.copyWith(color: AppTheme.primaryGreen),
                        );
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botão para adicionar à lista atual
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryGreen),
                          tooltip: 'Adicionar à lista',
                          onPressed: () async {
                            await widget.onAddToList(item);
                            setState(() => _items.removeWhere((i) => i.id == item.id));
                          },
                        ),
                        // Botão para remover dos pendentes
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.warningRed),
                          tooltip: 'Remover',
                          onPressed: () async {
                            await widget.onRemove(item);
                            setState(() => _items.removeWhere((i) => i.id == item.id));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
