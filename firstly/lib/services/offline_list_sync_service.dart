import '../models/list.dart';
import '../models/item.dart';
import 'storage_service.dart';
import 'list_sharing_service.dart';
import 'connectivity_service.dart';

class OfflineListSyncService {
  static const String _offlineListsKey = 'offline_shopping_lists';
  static const String _pendingActionsKey = 'pending_sync_actions';

  /// Salva uma lista como offline
  static Future<void> saveOfflineList(ShoppingList list) async {
    final offlineLists = await _getOfflineLists();
    
    // Remove lista existente se houver
    offlineLists.removeWhere((offlineList) => offlineList.id == list.id);
    
    // Marca como offline e adiciona
    list.isOfflineOnly = true;
    offlineLists.add(list);
    
    await StorageService.saveToPrefs(_offlineListsKey, 
      offlineLists.map((list) => list.toJson()).toList());
  }

  /// Obtém todas as listas offline
  static Future<List<ShoppingList>> getOfflineLists() async {
    return await _getOfflineLists();
  }

  /// Adiciona ação pendente para sincronização
  static Future<void> addPendingAction(Map<String, dynamic> action) async {
    final pendingActions = await _getPendingActions();
    pendingActions.add(action);
    
    await StorageService.saveToPrefs(_pendingActionsKey, pendingActions);
  }

  /// Sincroniza listas offline com online quando volta a conexão
  static Future<List<ShoppingList>> syncListsWhenOnline(String userId) async {
    if (!ConnectivityService.isOnline) {
      // Se offline, retorna apenas listas locais
      final localLists = await StorageService.loadShoppingLists();
      final offlineLists = await getOfflineLists();
      
      // Combina listas locais com offline
      final allLists = <ShoppingList>[];
      allLists.addAll(localLists.where((list) => list.id == null)); // Listas puramente locais
      allLists.addAll(offlineLists);
      
      return allLists;
    }

    try {
      // Se online, tenta sincronizar
      final onlineLists = await ListSharingService.loadUserLists(userId);
      final offlineLists = await getOfflineLists();
      final localLists = await StorageService.loadShoppingLists();
      
      // Mescla as listas
      final mergedLists = await _mergeLists(onlineLists, offlineLists, localLists);
      
      // Salva as listas mescladas
      await StorageService.saveShoppingLists(mergedLists);
      
      // Executa ações pendentes
      await _executePendingActions(userId);
      
      // Limpa listas offline após sincronização bem-sucedida
      await _clearOfflineLists();
      
      return mergedLists;
    } catch (e) {
      print('Erro na sincronização: $e');
      // Em caso de erro, retorna listas locais + offline
      final localLists = await StorageService.loadShoppingLists();
      final offlineLists = await getOfflineLists();
      
      final allLists = <ShoppingList>[];
      allLists.addAll(localLists);
      allLists.addAll(offlineLists.where((offlineList) => 
        !localLists.any((localList) => localList.id == offlineList.id)));
      
      return allLists;
    }
  }

  /// Verifica se uma lista é acessível offline
  static bool isListAccessibleOffline(ShoppingList list) {
    // Listas locais (sem ID) são sempre acessíveis offline
    if (list.id == null) return true;
    
    // Listas marcadas como offline são acessíveis
    if (list.isOfflineOnly == true) return true;
    
    // Listas compartilhadas não são acessíveis offline
    return false;
  }

  /// Remove uma lista offline
  static Future<void> removeOfflineList(String listId) async {
    final offlineLists = await _getOfflineLists();
    offlineLists.removeWhere((list) => list.id == listId);
    
    await StorageService.saveToPrefs(_offlineListsKey, 
      offlineLists.map((list) => list.toJson()).toList());
  }

  /// Obtém listas offline do storage
  static Future<List<ShoppingList>> _getOfflineLists() async {
    final data = await StorageService.loadFromPrefs(_offlineListsKey);
    if (data == null) return [];
    
    return (data as List).map((json) => ShoppingList.fromJson(json)).toList();
  }

  /// Obtém ações pendentes do storage
  static Future<List<Map<String, dynamic>>> _getPendingActions() async {
    final data = await StorageService.loadFromPrefs(_pendingActionsKey);
    if (data == null) return [];
    
    return List<Map<String, dynamic>>.from(data);
  }

  /// Mescla listas online, offline e locais
  static Future<List<ShoppingList>> _mergeLists(
    List<ShoppingList> onlineLists,
    List<ShoppingList> offlineLists,
    List<ShoppingList> localLists,
  ) async {
    final mergedLists = <ShoppingList>[];
    
    // Adiciona listas online
    mergedLists.addAll(onlineLists);
    
    // Para cada lista offline, verifica se deve ser mesclada ou adicionada
    for (final offlineList in offlineLists) {
      final existingIndex = mergedLists.indexWhere((list) => list.id == offlineList.id);
      
      if (existingIndex >= 0) {
        // Lista existe online, mescla os itens
        final onlineList = mergedLists[existingIndex];
        final mergedItems = _mergeItems(onlineList.items, offlineList.items);
        onlineList.items = mergedItems;
        
        // Atualiza outros campos se necessário
        if (offlineList.name != onlineList.name) {
          onlineList.name = offlineList.name;
        }
        if (offlineList.budget != onlineList.budget) {
          onlineList.budget = offlineList.budget;
        }
      } else {
        // Lista só existe offline, adiciona
        offlineList.isOfflineOnly = false;
        mergedLists.add(offlineList);
      }
    }
    
    // Adiciona listas puramente locais (sem ID)
    for (final localList in localLists) {
      if (localList.id == null && !mergedLists.any((list) => list.name == localList.name)) {
        mergedLists.add(localList);
      }
    }
    
    return mergedLists;
  }

  /// Mescla itens de duas listas
  static List<Item> _mergeItems(List<Item> onlineItems, List<Item> offlineItems) {
    final mergedItems = <Item>[];
    final processedIds = <String>{};
    
    // Adiciona itens online
    for (final item in onlineItems) {
      mergedItems.add(item);
      processedIds.add(item.id);
    }
    
    // Adiciona itens offline que não existem online
    for (final item in offlineItems) {
      if (!processedIds.contains(item.id)) {
        mergedItems.add(item);
      }
    }
    
    return mergedItems;
  }

  /// Executa ações pendentes de sincronização
  static Future<void> _executePendingActions(String userId) async {
    final pendingActions = await _getPendingActions();
    
    for (final action in pendingActions) {
      try {
        await _executeAction(action, userId);
      } catch (e) {
        print('Erro ao executar ação pendente: $e');
        // Continua com as próximas ações mesmo se uma falhar
      }
    }
    
    // Limpa ações pendentes após execução
    await StorageService.saveToPrefs(_pendingActionsKey, []);
  }

  /// Executa uma ação específica
  static Future<void> _executeAction(Map<String, dynamic> action, String userId) async {
    final type = action['type'] as String;
    
    switch (type) {
      case 'add_item':
        final listId = action['listId'] as String;
        final item = Item.fromJson(action['item']);
        await ListSharingService.addItemToList(listId, item, addedByUserId: userId);
        break;
      case 'update_item':
        final listId = action['listId'] as String;
        final itemId = action['itemId'] as String;
        final item = Item.fromJson(action['item']);
        await ListSharingService.updateItemInList(listId, itemId, item);
        break;
      case 'delete_item':
        final listId = action['listId'] as String;
        final itemId = action['itemId'] as String;
        await ListSharingService.removeItemFromList(listId, itemId);
        break;
      case 'create_list':
        final list = ShoppingList.fromJson(action['list']);
        await ListSharingService.saveListToSupabase(list, userId);
        break;
      case 'update_list':
        final list = ShoppingList.fromJson(action['list']);
        await ListSharingService.updateList(list.id!, list.name, list.budget);
        break;
    }
  }

  /// Limpa todas as listas offline
  static Future<void> _clearOfflineLists() async {
    await StorageService.saveToPrefs(_offlineListsKey, []);
  }
}
