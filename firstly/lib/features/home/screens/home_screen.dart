import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../shopping/models/list.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../shopping/widgets/list_sort_options_widget.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../shopping/screens/shopping_list_detail_screen.dart';
import '../../pantry/screens/pantry_screen.dart';
import '../../favorites/screens/favorite_items_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/screens/help_screen.dart';
import '../../scanner/screens/scanner_page.dart';
import '../../shopping/widgets/shopping_list_dialog.dart';

enum ListSortCriteria {
  nameAscending,
  nameDescending,
  dateNewest,
  dateOldest,
  totalValueAscending,
  totalValueDescending,
  itemCountAscending,
  itemCountDescending,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<ShoppingList> shoppingLists = [];
  late AnimationController _animationController;
  bool _isLoading = true;
  ListSortCriteria _currentListSortCriteria = ListSortCriteria.dateNewest;
  Timer? _pollingTimer;
  double? _globalBudget;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationMedium,
      vsync: this,
    );
    _loadShoppingLists();
    _loadGlobalBudget();
    // _startPolling();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Carrega as listas salvas do armazenamento local
  Future<void> _loadShoppingLists() async {
    try {
      final loadedLists = await StorageService.loadShoppingLists();
      setState(() {
        shoppingLists = loadedLists;
        _isLoading = false;
      });
      
      // Aplica a ordenação padrão
      _sortLists(_currentListSortCriteria);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função para o pull-to-refresh
  Future<void> _handleRefresh() async {
    await _loadShoppingLists();
  }



  // Salva as listas no armazenamento local
  Future<void> _saveShoppingLists() async {
    try {
      await StorageService.saveShoppingLists(shoppingLists);
    } catch (e) {
      // Erro ao salvar
    }
  }

  // Carrega o orçamento global
  Future<void> _loadGlobalBudget() async {
    try {
      final budget = await StorageService.loadGlobalBudget();
      setState(() {
        _globalBudget = budget;
      });
    } catch (e) {
      // Erro ao carregar
    }
  }

  // Salva o orçamento global
  Future<void> _saveGlobalBudget(double? budget) async {
    try {
      await StorageService.saveGlobalBudget(budget);
      setState(() {
        _globalBudget = budget;
      });
    } catch (e) {
      // Erro ao salvar
    }
  }

  // Calcula o valor total de todas as listas
  double get _totalAllListsValue {
    return shoppingLists.fold(0.0, (sum, list) => sum + list.totalPrice);
  }

  // Exibe o painel para configurar o orçamento global
  void _showGlobalBudgetDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String budgetText = _globalBudget?.toStringAsFixed(2) ?? '';
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
            
            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
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
                    
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                        const Flexible(
                          child: Text(
                            'Orçamento Global',
                            style: AppStyles.headingMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    
                    Text(
                      'Defina o valor máximo que deseja gastar com todas as suas listas.',
                      style: AppStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    
                    TextField(
                      onChanged: (value) => budgetText = value,
                      decoration: InputDecoration(
                        labelText: 'Orçamento Global',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        hintText: 'Ex: 500.00',
                        prefixIcon: const Icon(Icons.attach_money),
                        // prefixText: settingsProvider... (simplified access if needed or use Consumer)
                        filled: true,
                        fillColor: AppTheme.softGrey,
                        suffixIcon: _globalBudget != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setSheetState(() {
                                    budgetText = '';
                                  });
                                },
                                tooltip: 'Remover orçamento',
                              )
                            : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: TextEditingController(text: budgetText),
                      autofocus: true,
                    ),
                    
                    const SizedBox(height: AppConstants.paddingMedium),
                    
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppTheme.softGrey,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Expanded(
                            child: Text(
                              'Total atual: €${_totalAllListsValue.toStringAsFixed(2)}',
                              style: AppStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            double? budget;
                            if (budgetText.isNotEmpty) {
                              budget = double.tryParse(budgetText.replaceAll(',', '.'));
                            }
                            
                            await _saveGlobalBudget(budget);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Adiciona uma nova lista de compras
  void _addNewList() {
    _showCreateListDialog();
  }

  // Cria uma nova lista como cópia de uma existente
  void _copyList(ShoppingList originalList) {
    _showCreateListDialog(originalList: originalList);
  }

  // Exibe o painel para criar uma nova lista (com opção de cópia)
  void _showCreateListDialog({ShoppingList? originalList}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShoppingListDialog(
        originalList: originalList,
        existingLists: shoppingLists,
      ),
    );

    if (result != null) {
      final String listName = result['name'];
      final double? budget = result['budget'];
      final ShoppingList? copyFrom = result['copyFrom'];

      ShoppingList newList;
      if (copyFrom != null) {
        newList = copyFrom.copyAsTemplate(
          newName: listName,
          newBudget: budget,
        );
      } else {
        newList = ShoppingList(
          name: listName,
          items: [],
          budget: budget,
        );
      }

      setState(() {
        shoppingLists.add(newList);
      });
      await _saveShoppingLists();
      
      _animationController.forward();
    }
  }

  // Edita o nome e orçamento de uma lista
  void _editList(ShoppingList list, int index) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShoppingListDialog(
        originalList: list,
        isEditing: true,
      ),
    );

    if (result != null) {
      final String listName = result['name'];
      final double? budget = result['budget'];

      setState(() {
        list.name = listName;
        list.budget = budget;
      });
      await _saveShoppingLists();
    }
  }

  // Remove uma lista de compras
  void _deleteList(int index) async {
    final list = shoppingLists[index];

    
    String actionText = 'excluir a lista';
    String confirmText = 'Tem certeza que deseja excluir a lista "${list.name}"? Esta ação não pode ser desfeita.';
    
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
                child: Icon(
                  Icons.delete_outline,
                  color: AppTheme.warningRed,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Text('Excluir Lista'),
            ],
          ),
          content: Text(
            confirmText,
            style: AppStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Remover da lista local
                  
                  // Remover da lista local
                  setState(() {
                    shoppingLists.removeAt(index);
                  });
                  await _saveShoppingLists();
                  
                  Navigator.pop(context);
                } catch (error) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningRed,
                foregroundColor: Colors.white,
              ),
              child: Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  // Ordena as listas conforme o critério especificado
  void _sortLists(ListSortCriteria criteria) {
    setState(() {
      _currentListSortCriteria = criteria;
      switch (criteria) {
        case ListSortCriteria.nameAscending:
          shoppingLists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case ListSortCriteria.nameDescending:
          shoppingLists.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
        case ListSortCriteria.dateNewest:
          shoppingLists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case ListSortCriteria.dateOldest:
          shoppingLists.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case ListSortCriteria.totalValueAscending:
          shoppingLists.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
          break;
        case ListSortCriteria.totalValueDescending:
          shoppingLists.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
          break;
        case ListSortCriteria.itemCountAscending:
          shoppingLists.sort((a, b) => a.items.length.compareTo(b.items.length));
          break;
        case ListSortCriteria.itemCountDescending:
          shoppingLists.sort((a, b) => b.items.length.compareTo(a.items.length));
          break;
      }
    });
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
                Icons.shopping_cart,
                color: Colors.white,
                size: AppConstants.iconMedium,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            const Text(
              'SmartShop',
              style: AppStyles.headingMedium,
            ),
          ],
        ),
        actions: [
          if (shoppingLists.isNotEmpty)
            ListSortOptionsWidget(
              currentCriteria: _currentListSortCriteria,
              onSortChanged: _sortLists,
            ),
          const SizedBox(width: AppConstants.paddingSmall),
          // Botão de ajuda
          Container(
            child: IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: AppTheme.primaryGreen,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpScreen(),
                  ),
                );
                },
                tooltip: 'Como usar o app',
              ),
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
          _buildMainNavigationButtons(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppTheme.primaryGreen,
                    child: shoppingLists.isEmpty
                        ? _buildEmptyState()
                        : _buildShoppingLists(),
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "scanner_fab",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScannerPage(),
                ),
              );
            },
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            child: const Icon(Icons.document_scanner),
            tooltip: 'Escanear Fatura',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "settings_fab",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            child: const Icon(Icons.settings),
            tooltip: 'Configurações',
          ),
        ],
      ),
    );
  }

  Widget _buildMainNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Row(
        children: [
          // Botão Nova Lista de Compras
          Expanded(
            child: _buildCompactButton(
              icon: Icons.add_shopping_cart,
              label: 'Nova Lista',
              gradient: AppTheme.primaryGradient,
              onTap: _addNewList,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          
          // Botão Favoritos
          Expanded(
            child: _buildCompactButton(
              icon: Icons.favorite,
              label: 'Favoritos',
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoriteItemsScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),

          // Botão Despensa
          Expanded(
            child: _buildCompactButton(
              icon: Icons.kitchen,
              label: 'Despensa',
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PantryScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.mediumShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
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
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            size: AppConstants.iconXLarge,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingLarge),
                        Text(
                          'Nenhuma lista criada ainda',
                          style: AppStyles.headingMedium.copyWith(
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        const Text(
                          'Toque em "Nova Lista de Compras" acima para começar a organizar suas compras!\n\nPuxe para baixo para atualizar.',
                          style: AppStyles.bodyMedium,
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
    );
  }

  Widget _buildShoppingLists() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMedium,
        0,
        AppConstants.paddingMedium,
        AppConstants.paddingMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingSmall,
              vertical: AppConstants.paddingMedium,
            ),
            child: Consumer<AppSettingsProvider>(
              builder: (context, settingsProvider, child) {
                final remaining = _globalBudget != null 
                    ? _globalBudget! - _totalAllListsValue 
                    : null;
                final isOverBudget = remaining != null && remaining < 0;
                
                return InkWell(
                  onTap: _showGlobalBudgetDialog,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      boxShadow: const [AppStyles.softShadow],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total: ${settingsProvider.primaryCurrency.symbol}${_totalAllListsValue.toStringAsFixed(2)}',
                                style: AppStyles.headingMedium.copyWith(
                                  color: AppTheme.darkGreen,
                                  fontSize: 18,
                                ),
                              ),
                              if (_globalBudget != null)
                                Text(
                                  isOverBudget
                                      ? '${settingsProvider.primaryCurrency.symbol}${(-remaining!).toStringAsFixed(2)} acima'
                                      : 'Restam ${settingsProvider.primaryCurrency.symbol}${remaining!.toStringAsFixed(2)}',
                                  style: AppStyles.bodyMedium.copyWith(
                                    color: isOverBudget ? AppTheme.warningRed : AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (_globalBudget == null)
                                Text(
                                  'Toque para definir orçamento',
                                  style: AppStyles.captionGrey.copyWith(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            vertical: AppConstants.paddingSmall,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                          ),
                          child: Text(
                            '${shoppingLists.length}',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Icon(
                          Icons.edit,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: shoppingLists.length,
              itemBuilder: (context, index) {
                final list = shoppingLists[index];
                return _buildShoppingListCard(list, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingListCard(ShoppingList list, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShoppingListDetailScreen(
                  shoppingList: list,
                  onUpdate: () {
                    setState(() {});
                    _saveShoppingLists();
                  },
                ),
              ),
            );
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingMedium,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Lado esquerdo: Nome, data, valor
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nome + número de itens na mesma linha
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  list.name,
                                  style: AppStyles.bodyLarge.copyWith(
                                    color: AppTheme.darkGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${list.items.length} ${list.items.length == 1 ? 'item' : 'itens'}',
                                style: AppStyles.captionGrey.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Data de criação
                          Text(
                            '${list.createdAt.day.toString().padLeft(2, '0')}/${list.createdAt.month.toString().padLeft(2, '0')}/${list.createdAt.year}',
                            style: AppStyles.captionGrey.copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          // Valor total
                          Consumer<AppSettingsProvider>(
                            builder: (context, settingsProvider, child) {
                              return Text(
                                '${settingsProvider.primaryCurrency.symbol}${list.totalPrice.toStringAsFixed(2)}',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Meio: Orçamento restante (se houver)
                    if (list.budget != null) ...[
                      Consumer<AppSettingsProvider>(
                        builder: (context, settingsProvider, child) {
                          final remainingBudget = list.remainingBudget;
                          final isExceeded = list.isBudgetExceeded;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isExceeded 
                                  ? AppTheme.warningRed.withOpacity(0.1) 
                                  : AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                            ),
                            child: Text(
                              isExceeded 
                                  ? '${settingsProvider.primaryCurrency.symbol}${remainingBudget.abs().toStringAsFixed(2)} acima'
                                  : '${settingsProvider.primaryCurrency.symbol}${remainingBudget.toStringAsFixed(2)} restante',
                              style: AppStyles.captionGrey.copyWith(
                                fontSize: 11,
                                color: isExceeded ? AppTheme.warningRed : AppTheme.darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              // Lado direito Inferior: Botão de opções (3 pontinhos)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: () => _showListOptionsMenu(context, list, index),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(12),
                  tooltip: 'Opções da Lista',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showListOptionsMenu(BuildContext context, ShoppingList list, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryGreen),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _editList(list, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: AppTheme.accentBlue),
              title: const Text('Copiar'),
              onTap: () {
                Navigator.pop(context);
                _copyList(list);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.warningRed),
              title: const Text('Excluir'),
              onTap: () {
                Navigator.pop(context);
                _deleteList(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }



  // Mostra dialog informando que lista compartilhada não pode ser acessada offline
  void _showSharedListOfflineDialog(ShoppingList list) {
    showDialog(
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(
                Icons.wifi_off,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            const Expanded(
              child: Text(
                'Lista Indisponível',
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A lista "${list.name}" está compartilhada e não pode ser acessada sem conexão com a internet.',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: AppConstants.iconSmall,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Conecte-se à internet para acessar e editar listas compartilhadas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}