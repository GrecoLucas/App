import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/list.dart';
import '../utils/app_theme.dart';
import '../services/storage_service.dart';
import '../services/list_sharing_service.dart';
import '../widgets/list_sort_options_widget.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import 'shopping_list_detail_screen.dart';
import 'favorite_items_screen.dart';
import 'settings_screen.dart';

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
  static const Duration _pollingInterval = Duration(seconds: 10); // Atualizar a cada 10 segundos

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.animationMedium,
      vsync: this,
    );
    _loadShoppingLists();
    _startPolling();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Inicia o polling para atualizar as listas automaticamente
  void _startPolling() {
    // Desabilitar polling temporariamente para evitar conflitos
    // _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
    //   _refreshListsFromSupabase();
    // });
  }

  // Atualiza as listas do Supabase sem mostrar loading
  Future<void> _refreshListsFromSupabase() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Só fazer polling se estiver logado
      if (authProvider.isLoggedIn && authProvider.currentUser != null) {
        final supabaseLists = await ListSharingService.loadUserLists(
          authProvider.currentUser!['id'].toString(),
        );
        
        // Só atualizar se as listas mudaram
        if (mounted && _hasListsChanged(supabaseLists)) {
          setState(() {
            shoppingLists = supabaseLists;
          });
          await _saveShoppingLists();
        }
      }
    } catch (e) {
      // Falhar silenciosamente durante o polling
      print('Erro no polling: $e');
    }
  }

  // Verifica se as listas mudaram
  bool _hasListsChanged(List<ShoppingList> newLists) {
    if (newLists.length != shoppingLists.length) return true;
    
    for (int i = 0; i < newLists.length; i++) {
      final newList = newLists[i];
      final oldList = shoppingLists[i];
      
      if (newList.name != oldList.name ||
          newList.items.length != oldList.items.length ||
          newList.isShared != oldList.isShared) {
        return true;
      }
      
      // Verificar se os itens mudaram
      for (int j = 0; j < newList.items.length; j++) {
        if (j >= oldList.items.length) return true;
        
        final newItem = newList.items[j];
        final oldItem = oldList.items[j];
        
        if (newItem.name != oldItem.name ||
            newItem.price != oldItem.price ||
            newItem.quantity != oldItem.quantity ||
            newItem.isCompleted != oldItem.isCompleted) {
          return true;
        }
      }
    }
    
    return false;
  }

  // Função para o pull-to-refresh
  Future<void> _handleRefresh() async {
    await _refreshListsFromSupabase();
  }

  // Carrega as listas salvas do armazenamento local e do Supabase
  Future<void> _loadShoppingLists() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Se estiver logado, carregar do Supabase
      if (authProvider.isLoggedIn && authProvider.currentUser != null) {
        try {
          final supabaseLists = await ListSharingService.loadUserLists(
            authProvider.currentUser!['id'].toString(),
          );
          setState(() {
            shoppingLists = supabaseLists;
            _isLoading = false;
          });
        } catch (e) {
          // Se der erro no Supabase, carregar localmente
          final loadedLists = await StorageService.loadShoppingLists();
          setState(() {
            shoppingLists = loadedLists;
            _isLoading = false;
          });
        }
      } else {
        // Se não estiver logado, carregar apenas localmente
        final loadedLists = await StorageService.loadShoppingLists();
        setState(() {
          shoppingLists = loadedLists;
          _isLoading = false;
        });
      }
      
      // Aplica a ordenação padrão
      _sortLists(_currentListSortCriteria);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Salva as listas no armazenamento local
  Future<void> _saveShoppingLists() async {
    try {
      await StorageService.saveShoppingLists(shoppingLists);
    } catch (e) {
      // Erro ao salvar
    }
  }

  // Adiciona uma nova lista de compras
  void _addNewList() {
    _showCreateListDialog();
  }

  // Cria uma nova lista como cópia de uma existente
  void _copyList(ShoppingList originalList) {
    _showCreateListDialog(originalList: originalList);
  }

  // Exibe o diálogo para criar uma nova lista (com opção de cópia)
  void _showCreateListDialog({ShoppingList? originalList}) {
    showDialog(
      context: context,
      builder: (context) {
        String listName = originalList != null ? 'Cópia de ${originalList.name}' : '';
        String budgetText = '';
        ShoppingList? selectedListToCopy = originalList;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: Icon(
                      originalList != null ? Icons.copy : Icons.add_shopping_cart,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Flexible(
                    child: Text(
                      originalList != null ? 'Copiar Lista' : 'Nova Lista',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                  ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) => listName = value,
                      decoration: InputDecoration(
                        labelText: 'Nome da Lista',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        hintText: 'Ex: Supermercado, Farmácia...',
                        prefixIcon: const Icon(Icons.shopping_basket),
                        filled: true,
                        fillColor: AppTheme.softGrey,
                      ),
                      autofocus: true,
                      controller: TextEditingController(text: listName),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Consumer<AppSettingsProvider>(
                      builder: (context, settingsProvider, child) {
                        return TextField(
                          onChanged: (value) => budgetText = value,
                          decoration: InputDecoration(
                            labelText: 'Orçamento (opcional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                            ),
                            hintText: 'Ex: 50.00',
                            prefixIcon: Icon(Icons.attach_money),
                            prefixText: '${settingsProvider.primaryCurrency.symbol} ',
                            filled: true,
                            fillColor: AppTheme.softGrey,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        );
                      },
                    ),
                    // Mostrar opção de cópia apenas quando não estamos já copiando uma lista específica
                    if (originalList == null && shoppingLists.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.paddingMedium),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.softGrey,
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: DropdownButtonFormField<ShoppingList?>(
                          value: selectedListToCopy,
                          decoration: const InputDecoration(
                            labelText: 'Copiar produtos de (opcional)',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingLarge,
                              vertical: AppConstants.paddingMedium,
                            ),
                            prefixIcon: Icon(Icons.copy),
                          ),
                          dropdownColor: Colors.white,
                          items: [
                            const DropdownMenuItem<ShoppingList?>(
                              value: null,
                              child: Text('Nenhuma (lista vazia)'),
                            ),
                            ...shoppingLists.map((list) => DropdownMenuItem<ShoppingList?>(
                              value: list,
                              child: Text(
                                list.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              selectedListToCopy = value;
                            });
                          },
                        ),
                      ),
                    ],
                    // Mostrar informação sobre a cópia quando há uma lista selecionada
                    if (selectedListToCopy != null) ...[
                      const SizedBox(height: AppConstants.paddingMedium),
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.darkGreen,
                              size: AppConstants.iconSmall,
                            ),
                            const SizedBox(width: AppConstants.paddingSmall),
                            Expanded(
                              child: Text(
                                'Os produtos serão copiados com quantidade 1 e preço €0,00',
                                style: AppStyles.captionGrey.copyWith(
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (listName.trim().isNotEmpty) {
                      double? budget;
                      if (budgetText.isNotEmpty) {
                        budget = double.tryParse(budgetText.replaceAll(',', '.'));
                      }
                      
                      // Criar a lista com os itens copiados se necessário
                      ShoppingList newList;
                      if (selectedListToCopy != null) {
                        newList = selectedListToCopy!.copyAsTemplate(
                          newName: listName.trim(),
                          newBudget: budget,
                        );
                      } else {
                        newList = ShoppingList(
                          name: listName.trim(), 
                          items: [],
                          budget: budget,
                        );
                      }
                      
                      // SEMPRE salvar apenas localmente na criação
                      // A lista só será enviada para a Supabase quando for compartilhada
                      print('Salvando lista localmente: ${newList.name}');
                      
                      setState(() {
                        shoppingLists.add(newList);
                      });
                      await _saveShoppingLists();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lista "${newList.name}" criada com sucesso!'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                      
                      _animationController.forward();
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(originalList != null ? 'Copiar' : 'Criar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Remove uma lista de compras
  void _deleteList(int index) async {
    final list = shoppingLists[index];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?['id']?.toString();
    
    if (currentUserId == null) return;

    bool isOwner = false;
    String actionText = 'sair da lista compartilhada';
    String confirmText = 'Tem certeza que deseja sair da lista "${list.name}"?';
    
    // Verificar se é o dono da lista
    if (list.id != null) {
      // Lista tem ID do Supabase, verificar propriedade
      try {
        isOwner = await ListSharingService.isListOwner(list.id!, currentUserId);
        if (isOwner) {
          actionText = 'excluir a lista';
          confirmText = 'Tem certeza que deseja excluir a lista "${list.name}"? Esta ação irá remover a lista da base de dados e não pode ser desfeita.';
        } else {
          actionText = 'sair da lista compartilhada';
          confirmText = 'Tem certeza que deseja sair da lista "${list.name}"?';
        }
      } catch (error) {
        // Em caso de erro, assumir que não é o dono
        print('Erro ao verificar propriedade da lista: $error');
        isOwner = false;
        actionText = 'sair da lista compartilhada';
        confirmText = 'Tem certeza que deseja sair da lista "${list.name}"?';
      }
    } else {
      // Lista local (sem ID do Supabase), sempre pode excluir
      isOwner = true;
      actionText = 'excluir a lista';
      confirmText = 'Tem certeza que deseja excluir a lista "${list.name}"? Esta ação não pode ser desfeita.';
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
                child: Icon(
                  isOwner ? Icons.delete_outline : Icons.exit_to_app,
                  color: AppTheme.warningRed,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Text(isOwner ? 'Excluir Lista' : 'Sair da Lista'),
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
                  // Se a lista tem ID do Supabase, deletar/sair do Supabase
                  if (list.id != null) {
                    if (isOwner) {
                      // Dono da lista: deletar completamente do Supabase
                      print('Deletando lista do Supabase - ID: ${list.id}, Owner: $isOwner');
                      await ListSharingService.deleteList(list.id!, currentUserId);
                    } else {
                      // Convidado: apenas sair da lista compartilhada
                      print('Saindo da lista compartilhada - ID: ${list.id}');
                      await ListSharingService.leaveSharedList(list.id!, currentUserId);
                    }
                  }
                  
                  // Remover da lista local
                  setState(() {
                    shoppingLists.removeAt(index);
                  });
                  await _saveShoppingLists();
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isOwner ? 'Lista excluída com sucesso' : 'Você saiu da lista compartilhada'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                } catch (error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao ${actionText}: $error'),
                      backgroundColor: AppTheme.warningRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningRed,
                foregroundColor: Colors.white,
              ),
              child: Text(isOwner ? 'Excluir' : 'Sair'),
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
          // Botão de logout
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.person),
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(authProvider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'user_info',
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usuário:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          authProvider.currentUser?['Username'] ?? 'Usuário',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Sair'),
                      ],
                    ),
                  ),
                ],
              );
            },
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
      floatingActionButton: FloatingActionButton(
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
    );
  }

  Widget _buildMainNavigationButtons() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          // Botão Nova Lista de Compras
          _buildNavigationButton(
            icon: Icons.add_shopping_cart,
            title: 'Nova Lista de Compras',
            subtitle: 'Organize suas compras com scanner QR e orçamento',
            gradient: AppTheme.primaryGradient,
            onTap: _addNewList,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          
          // Botão Favoritos
          _buildNavigationButton(
            icon: Icons.favorite,
            title: 'Favoritos',
            subtitle: 'Produtos salvos para reutilizar',
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
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
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
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: AppConstants.iconLarge,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingLarge),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            child: Row(
              children: [
                Text(
                  'Minhas Listas',
                  style: AppStyles.headingMedium.copyWith(
                    color: AppTheme.darkGreen,
                  ),
                ),
                const Spacer(),
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
                    '${shoppingLists.length} ${shoppingLists.length == 1 ? 'lista' : 'listas'}',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
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
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_basket,
                        color: Colors.white,
                        size: AppConstants.iconMedium,
                      ),
                      // Contador de pessoas com acesso (apenas para listas com ID)
                      if (list.id != null)
                        FutureBuilder<int>(
                          future: ListSharingService.getListAccessCount(list.id!),
                          builder: (context, snapshot) {
                            final accessCount = snapshot.data ?? 1;
                            if (accessCount > 1) {
                              return Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$accessCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppConstants.paddingLarge),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: AppConstants.iconSmall,
                            color: AppTheme.textGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${list.items.length}',
                            style: AppStyles.captionGrey,
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),
                          Consumer<AppSettingsProvider>(
                            builder: (context, settingsProvider, child) {
                              return Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_money,
                                      size: AppConstants.iconSmall,
                                      color: AppTheme.primaryGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${settingsProvider.primaryCurrency.symbol}${list.totalPrice.toStringAsFixed(2)}',
                                        style: AppStyles.captionGrey.copyWith(
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: AppConstants.iconSmall,
                            color: AppTheme.textGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${list.createdAt.day.toString().padLeft(2, '0')}/${list.createdAt.month.toString().padLeft(2, '0')}/${list.createdAt.year}',
                            style: AppStyles.captionGrey,
                          ),
                        ],
                      ),
                      // Mostrar informação do orçamento se disponível
                      if (list.budget != null) ...[
                        const SizedBox(height: AppConstants.paddingSmall),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: AppConstants.iconSmall,
                              color: list.isBudgetExceeded ? AppTheme.warningRed : AppTheme.darkGreen,
                            ),
                            const SizedBox(width: 4),
                            Consumer<AppSettingsProvider>(
                              builder: (context, settingsProvider, child) {
                                final remainingBudget = list.remainingBudget;
                                final displayText = list.isBudgetExceeded 
                                    ? '${settingsProvider.primaryCurrency.symbol}${remainingBudget.abs().toStringAsFixed(2)} acima'
                                    : '${settingsProvider.primaryCurrency.symbol}${remainingBudget.toStringAsFixed(2)} restante';
                                
                                return Expanded(
                                  child: Text(
                                    displayText,
                                    style: AppStyles.captionGrey.copyWith(
                                      color: list.isBudgetExceeded ? AppTheme.warningRed : AppTheme.darkGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: AppConstants.paddingSmall),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botão de copiar
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.copy,
                              color: AppTheme.accentBlue,
                              size: AppConstants.iconSmall,
                            ),
                            onPressed: () => _copyList(list),
                            tooltip: 'Copiar lista',
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Botão de deletar
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.warningRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppTheme.warningRed,
                              size: AppConstants.iconSmall,
                            ),
                            onPressed: () => _deleteList(index),
                            tooltip: 'Excluir lista',
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Exibe diálogo de confirmação para logout
  void _showLogoutDialog(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta'),
        content: Text(
          'Tem certeza que deseja sair da conta "${authProvider.currentUser?['Username']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}