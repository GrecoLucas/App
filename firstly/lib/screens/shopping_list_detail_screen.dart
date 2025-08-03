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
import '../services/list_sharing_service.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
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
  SortCriteria _currentSortCriteria = SortCriteria.alphabetical;
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 15); // Polling a cada 15 segundos
  ShoppingList? _currentList; // Lista local para controlar atualizações

  @override
  void initState() {
    super.initState();
    _currentList = widget.shoppingList;
    _loadSortPreference();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Carrega a preferência de ordenação salva
  void _loadSortPreference() async {
    final sortCriteria = await StorageService.loadSortPreference();
    setState(() {
      _currentSortCriteria = sortCriteria;
    });
  }

  // Inicia o polling para atualizar a lista específica
  void _startPolling() {
    // Só fazer polling se a lista tem ID do Supabase (é compartilhada)
    if (_currentList?.id != null) {
      _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
        _refreshCurrentList();
      });
    }
  }

  // Pausa temporariamente o polling para evitar conflitos
  void _pausePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Reinicia o polling após operações
  void _resumePolling() {
    if (_pollingTimer == null) {
      _startPolling();
    }
  }

  // Atualiza apenas a lista atual do Supabase
  Future<void> _refreshCurrentList() async {
    if (_currentList?.id == null) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.isLoggedIn && authProvider.currentUser != null) {
        final userLists = await ListSharingService.loadUserLists(
          authProvider.currentUser!['id'].toString(),
        );
        
        // Encontrar a lista específica pelo ID
        final updatedList = userLists.firstWhere(
          (list) => list.id == _currentList!.id,
          orElse: () => _currentList!,
        );
        
        if (mounted && _hasListChanged(updatedList)) {
          setState(() {
            _currentList = updatedList;
            // Atualizar também a lista original de forma mais cuidadosa
            _syncListChanges(updatedList);
          });
          widget.onUpdate();
        }
      }
    } catch (e) {
      // Falhar silenciosamente durante o polling
      print('Erro no polling da lista: $e');
    }
  }

  // Sincroniza mudanças da lista remota com a local preservando referências
  void _syncListChanges(ShoppingList updatedList) {
    // Atualizar propriedades básicas
    widget.shoppingList.name = updatedList.name;
    widget.shoppingList.budget = updatedList.budget;
    
    // Criar um mapa dos itens remotos por ID para acesso rápido
    final remoteItemsMap = <String, Item>{};
    for (final remoteItem in updatedList.items) {
      remoteItemsMap[remoteItem.id] = remoteItem;
    }
    
    // Criar um mapa dos itens locais por ID
    final localItemsMap = <String, Item>{};
    for (final localItem in widget.shoppingList.items) {
      localItemsMap[localItem.id] = localItem;
    }
    
    // Remover itens que não existem mais
    widget.shoppingList.items.removeWhere((localItem) => !remoteItemsMap.containsKey(localItem.id));
    
    // Atualizar ou adicionar itens
    for (final remoteItem in updatedList.items) {
      if (localItemsMap.containsKey(remoteItem.id)) {
        // Atualizar item existente preservando referência
        final localItem = localItemsMap[remoteItem.id]!;
        localItem.name = remoteItem.name;
        localItem.price = remoteItem.price;
        localItem.quantity = remoteItem.quantity;
        localItem.isCompleted = remoteItem.isCompleted;
        localItem.addedBy = remoteItem.addedBy;
        localItem.supabaseId = remoteItem.supabaseId;
      } else {
        // Adicionar novo item
        widget.shoppingList.items.add(remoteItem);
      }
    }
    
    // Reordenar a lista para manter a ordem original
    widget.shoppingList.items.sort((a, b) {
      final aIndex = updatedList.items.indexWhere((item) => item.id == a.id);
      final bIndex = updatedList.items.indexWhere((item) => item.id == b.id);
      return aIndex.compareTo(bIndex);
    });
  }

  // Verifica se a lista mudou
  bool _hasListChanged(ShoppingList newList) {
    if (_currentList == null) return true;
    
    if (newList.name != _currentList!.name ||
        newList.items.length != _currentList!.items.length ||
        newList.budget != _currentList!.budget) {
      return true;
    }
    
    // Verificar se os itens mudaram (incluindo supabaseId)
    for (int i = 0; i < newList.items.length; i++) {
      if (i >= _currentList!.items.length) return true;
      
      final newItem = newList.items[i];
      final oldItem = _currentList!.items[i];
      
      if (newItem.name != oldItem.name ||
          newItem.price != oldItem.price ||
          newItem.quantity != oldItem.quantity ||
          newItem.isCompleted != oldItem.isCompleted ||
          newItem.supabaseId != oldItem.supabaseId ||
          newItem.addedBy != oldItem.addedBy) {
        return true;
      }
    }
    
    return false;
  }

  // Função para o pull-to-refresh
  Future<void> _handleRefresh() async {
    await _refreshCurrentList();
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
      
      // Pausar o polling durante a adição para evitar conflitos
      _pausePolling();
      
      try {
        // Se a lista tem ID do Supabase, sincronizar primeiro
        if (widget.shoppingList.id != null) {
          try {
            print('Adicionando item ao Supabase - Lista ID: ${widget.shoppingList.id}');
            print('Item: ${newItem.name}');
            
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await ListSharingService.addItemToList(
              widget.shoppingList.id!,
              newItem,
              addedByUserId: authProvider.currentUser?['id']?.toString(),
            );
            
            print('Item adicionado com sucesso no Supabase');
            
            // Adicionar localmente apenas após sucesso da sincronização
            setState(() {
              widget.shoppingList.addItem(newItem);
            });
            
          } catch (error) {
            print('Erro ao sincronizar item: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao sincronizar item: $error'),
                  backgroundColor: AppTheme.warningRed,
                ),
              );
            }
            return; // Não continuar se falhou a sincronização
          }
        } else {
          // Lista local apenas - adicionar diretamente
          setState(() {
            widget.shoppingList.addItem(newItem);
          });
        }
        
        widget.onUpdate();
      } finally {
        // Reiniciar o polling após a adição
        _resumePolling();
      }
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
      // Pausar o polling durante a edição para evitar conflitos
      _pausePolling();
      
      try {
        // Se a lista tem ID do Supabase, sincronizar primeiro
        if (widget.shoppingList.id != null && item.supabaseId != null) {
          // Atualizar valores locais temporariamente para sincronização
          final originalName = item.name;
          final originalPrice = item.price;
          final originalQuantity = item.quantity;
          
          item.name = result['name'];
          item.price = result['price'];
          item.quantity = result['quantity'] ?? 1;
          
          try {
            await ListSharingService.updateItemInList(
              widget.shoppingList.id!,
              item.supabaseId!,
              item,
            );
            
            print('Item sincronizado com sucesso no Supabase');
            
            // Atualizar a interface apenas após sucesso da sincronização
            setState(() {
              final itemToUpdate = widget.shoppingList.items.firstWhere((i) => i.id == item.id);
              itemToUpdate.name = result['name'];
              itemToUpdate.price = result['price'];
              itemToUpdate.quantity = result['quantity'] ?? 1;
            });
            
          } catch (error) {
            // Reverter mudanças locais em caso de erro
            item.name = originalName;
            item.price = originalPrice;
            item.quantity = originalQuantity;
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao sincronizar edição: $error'),
                  backgroundColor: AppTheme.warningRed,
                ),
              );
            }
            return; // Não continuar se falhou a sincronização
          }
        } else {
          // Lista local apenas - aplicar mudanças diretamente
          setState(() {
            final itemToUpdate = widget.shoppingList.items.firstWhere((i) => i.id == item.id);
            itemToUpdate.name = result['name'];
            itemToUpdate.price = result['price'];
            itemToUpdate.quantity = result['quantity'] ?? 1;
          });
        }
        
        widget.onUpdate();
        
        // Recarregar a lista completa se for compartilhada
        if (widget.shoppingList.id != null) {
          await _refreshCurrentList();
        }
      } finally {
        // Reiniciar o polling após a edição
        _resumePolling();
      }
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
                // Pausar o polling durante a remoção para evitar conflitos
                _pausePolling();
                
                try {
                  // Se a lista tem ID do Supabase, sincronizar primeiro
                  if (widget.shoppingList.id != null && item.supabaseId != null) {
                    try {
                      await ListSharingService.removeItemFromList(
                        widget.shoppingList.id!,
                        item.supabaseId!,
                      );
                      
                      print('Item removido com sucesso do Supabase');
                      
                      // Remover localmente apenas após sucesso da sincronização
                      setState(() {
                        widget.shoppingList.items.removeWhere((i) => i.id == item.id);
                      });
                      
                    } catch (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao sincronizar remoção: $error'),
                            backgroundColor: AppTheme.warningRed,
                          ),
                        );
                      }
                      Navigator.pop(context);
                      return; // Não continuar se falhou a sincronização
                    }
                  } else {
                    // Lista local apenas - remover diretamente
                    setState(() {
                      widget.shoppingList.items.removeWhere((i) => i.id == item.id);
                    });
                  }
                  
                  widget.onUpdate();
                  Navigator.pop(context);
                  
                  // Recarregar a lista completa se for compartilhada
                  if (widget.shoppingList.id != null) {
                    await _refreshCurrentList();
                  }
                } finally {
                  // Reiniciar o polling após a remoção
                  _resumePolling();
                }
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
          
          // Pausar o polling durante a adição para evitar conflitos
          _pausePolling();
          
          try {
            // Esta função será chamada quando os itens forem selecionados
            for (final itemData in items) {
              final newItem = Item(
                name: itemData['name'], 
                price: itemData['price'],
                quantity: itemData['quantity'] ?? 1,
              );
              print('Preparando item: ${newItem.name}, preço: ${newItem.price}, quantidade: ${newItem.quantity}');
              newItems.add(newItem);
            }
            
            // Se a lista tem ID do Supabase, sincronizar primeiro
            if (widget.shoppingList.id != null) {
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                for (final item in newItems) {
                  await ListSharingService.addItemToList(
                    widget.shoppingList.id!,
                    item,
                    addedByUserId: authProvider.currentUser?['id']?.toString(),
                  );
                }
                
                // Adicionar localmente apenas após sucesso da sincronização
                setState(() {
                  for (final item in newItems) {
                    widget.shoppingList.addItem(item);
                  }
                });
                
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao sincronizar favoritos: $error'),
                      backgroundColor: AppTheme.warningRed,
                    ),
                  );
                }
                return; // Não continuar se falhou a sincronização
              }
            } else {
              // Lista local apenas - adicionar diretamente
              setState(() {
                for (final item in newItems) {
                  widget.shoppingList.addItem(item);
                }
              });
            }
            
            widget.onUpdate();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${items.length} item${items.length != 1 ? 's' : ''} adicionado${items.length != 1 ? 's' : ''} da lista de favoritos'),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          } finally {
            // Reiniciar o polling após a adição
            _resumePolling();
          }
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
      
      // Pausar o polling durante a adição para evitar conflitos
      _pausePolling();
      
      try {
        // Se a lista tem ID do Supabase, sincronizar primeiro
        if (widget.shoppingList.id != null) {
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            await ListSharingService.addItemToList(
              widget.shoppingList.id!,
              newItem,
              addedByUserId: authProvider.currentUser?['id']?.toString(),
            );
            
            // Adicionar localmente apenas após sucesso da sincronização
            setState(() {
              widget.shoppingList.addItem(newItem);
            });
            
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao sincronizar item escaneado: $error'),
                  backgroundColor: AppTheme.warningRed,
                ),
              );
            }
            return; // Não continuar se falhou a sincronização
          }
        } else {
          // Lista local apenas - adicionar diretamente
          setState(() {
            widget.shoppingList.addItem(newItem);
          });
        }
        
        widget.onUpdate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${scannedItem.name} adicionado via scanner'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      } finally {
        // Reiniciar o polling após a adição
        _resumePolling();
      }
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
          if (widget.shoppingList.items.isNotEmpty)
            SortOptionsWidget(
              currentCriteria: _currentSortCriteria,
              onSortChanged: _updateSortCriteria,
            ),
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
                    onPressed: _shareList,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Compartilhar'),
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
            );
          },
        ),
      ),
    );
  }

  // Função para compartilhar a lista
  void _shareList() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar logado para compartilhar listas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ShareListDialog(
        shoppingList: widget.shoppingList,
        currentUserId: authProvider.currentUser!['id'].toString(),
        onListShared: () {
          widget.onUpdate(); // Atualizar a tela principal
          setState(() {}); // Atualizar a tela atual
        },
      ),
    );
  }
}

// Widget do diálogo de compartilhamento
class _ShareListDialog extends StatefulWidget {
  final ShoppingList shoppingList;
  final String currentUserId;
  final VoidCallback onListShared;

  const _ShareListDialog({
    required this.shoppingList,
    required this.currentUserId,
    required this.onListShared,
  });

  @override
  State<_ShareListDialog> createState() => _ShareListDialogState();
}

class _ShareListDialogState extends State<_ShareListDialog> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  List<String> _collaborators = [];

  @override
  void initState() {
    super.initState();
    _loadCollaborators();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // Carregar lista de colaboradores
  Future<void> _loadCollaborators() async {
    if (widget.shoppingList.id != null && widget.shoppingList.isShared) {
      try {
        final collaborators = await ListSharingService.getListCollaborators(
          widget.shoppingList.id!,
        );
        setState(() {
          _collaborators = collaborators;
        });
      } catch (error) {
        // Erro ao carregar colaboradores (não crítico)
      }
    }
  }

  // Compartilhar com novo usuário
  Future<void> _shareWithUser() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome do usuário'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Se a lista ainda não foi salva no Supabase, salvar primeiro
      if (widget.shoppingList.id == null) {
        final savedList = await ListSharingService.saveListToSupabase(
          widget.shoppingList,
          widget.currentUserId,
        );
        widget.shoppingList.id = savedList.id;
        widget.shoppingList.ownerId = savedList.ownerId;
      }

      await ListSharingService.shareListWithUser(
        widget.shoppingList.id!,
        username,
        widget.currentUserId,
      );

      widget.shoppingList.isShared = true;
      _collaborators.add(username);
      _usernameController.clear();
      
      widget.onListShared();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lista compartilhada com $username!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Remover usuário da lista
  Future<void> _removeUser(String username) async {
    try {
      await ListSharingService.removeUserFromList(
        widget.shoppingList.id!,
        username,
      );

      setState(() {
        _collaborators.remove(username);
      });

      if (_collaborators.isEmpty) {
        widget.shoppingList.isShared = false;
      }

      widget.onListShared();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$username removido da lista'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover usuário: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.share, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Compartilhar "${widget.shoppingList.name}"',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informação sobre o compartilhamento
            if (widget.shoppingList.id == null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta lista será salva na nuvem ao compartilhar pela primeira vez.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Campo para adicionar usuário
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nome do usuário',
                hintText: 'Digite o nome de usuário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_add),
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _shareWithUser(),
            ),
            const SizedBox(height: 16),
            
            // Botão para compartilhar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _shareWithUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.share),
                label: Text(_isLoading ? 'Compartilhando...' : 'Compartilhar'),
              ),
            ),
            
            // Lista de colaboradores
            if (_collaborators.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Usuários com acesso:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: _collaborators.length,
                  itemBuilder: (context, index) {
                    final username = _collaborators[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(username),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeUser(username),
                          tooltip: 'Remover acesso',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
