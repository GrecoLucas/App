import '../models/list.dart';
import '../models/item.dart';
import 'supabase_service.dart';

class ListSharingService {
  // Função para contar quantas pessoas têm acesso a uma lista (dono + colaboradores)
  static Future<int> getListAccessCount(String listId) async {
    try {
      // Contar colaboradores na tabela shared_lists
      final sharedResponse = await SupabaseService.client
          .from('shared_lists')
          .select('id')
          .eq('list_id', int.parse(listId));
      
      // +1 para incluir o dono da lista
      return sharedResponse.length + 1;
    } catch (error) {
      print('Erro ao contar acessos da lista: $error');
      return 1; // Retorna 1 (apenas o dono) em caso de erro
    }
  }

  // Salvar lista no Supabase
  static Future<ShoppingList> saveListToSupabase(ShoppingList list, String userId) async {
    try {
      print('saveListToSupabase - Iniciando...');
      print('Lista: ${list.name}');
      print('User ID: $userId');
      
      final listData = {
        'name': list.name,
        'description': null, // Pode adicionar descrição futuramente
        'owner_id': int.parse(userId),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Dados da lista: $listData');

      final response = await SupabaseService.client
          .from('shopping_lists')
          .insert(listData)
          .select()
          .single();

      print('Resposta do Supabase: $response');

      final listId = response['id'].toString();
      
      // Salvar itens da lista
      if (list.items.isNotEmpty) {
        print('Salvando ${list.items.length} itens...');
        final itemsData = list.items.map((item) => {
          'list_id': int.parse(listId),
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'is_completed': item.isCompleted,
          'added_by': int.parse(userId),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).toList();

        await SupabaseService.client
            .from('shopping_items')
            .insert(itemsData);
        
        print('Itens salvos com sucesso');
      }

      // Retornar lista atualizada com ID e data do Supabase
      list.id = listId;
      list.ownerId = userId;
      list.createdAt = DateTime.parse(response['created_at']);
      
      print('Lista salva com sucesso! ID: ${list.id}');
      return list;
    } catch (error) {
      print('Erro ao salvar lista: $error');
      throw Exception('Erro ao salvar lista: $error');
    }
  }

  // Compartilhar lista com usuário específico
  static Future<bool> shareListWithUser(String listId, String username, String currentUserId) async {
    try {
      print('shareListWithUser - Iniciando...');
      print('Lista ID: $listId');
      print('Username: $username');
      print('Current User ID: $currentUserId');
      
      // Verificar se o usuário existe
      final userResponse = await SupabaseService.client
          .from('Users')
          .select('id, Username')
          .eq('Username', username.trim())
          .maybeSingle();

      print('Resposta do usuário: $userResponse');

      if (userResponse == null) {
        throw Exception('Usuário "$username" não encontrado');
      }

      final targetUserId = userResponse['id'].toString();
      print('Target User ID: $targetUserId');

      // Verificar se o usuário não está tentando compartilhar consigo mesmo
      if (targetUserId == currentUserId) {
        throw Exception('Você não pode compartilhar uma lista consigo mesmo');
      }

      // Verificar se a lista já não está compartilhada com este usuário
      final existingShare = await SupabaseService.client
          .from('shared_lists')
          .select('id')
          .eq('list_id', int.parse(listId))
          .eq('user_id', int.parse(targetUserId))
          .maybeSingle();

      print('Compartilhamento existente: $existingShare');

      if (existingShare != null) {
        throw Exception('Lista já compartilhada com este usuário');
      }

      // Adicionar compartilhamento
      print('Adicionando compartilhamento...');
      await SupabaseService.client
          .from('shared_lists')
          .insert({
            'list_id': int.parse(listId),
            'user_id': int.parse(targetUserId),
            'permission': 'edit',
          });

      print('Compartilhamento adicionado com sucesso');
      return true;
    } catch (error) {
      print('Erro ao compartilhar lista: $error');
      throw Exception('Erro ao compartilhar lista: $error');
    }
  }

  // Carregar listas do usuário (próprias e compartilhadas)
  static Future<List<ShoppingList>> loadUserLists(String userId) async {
    try {
      // Carregar listas próprias
      final ownListsResponse = await SupabaseService.client
          .from('shopping_lists')
          .select('''
            *,
            shopping_items(*)
          ''')
          .eq('owner_id', int.parse(userId))
          .order('created_at', ascending: false);

      // Carregar listas compartilhadas comigo
      final sharedListsResponse = await SupabaseService.client
          .from('shared_lists')
          .select('''
            permission,
            shopping_lists!inner(
              *,
              shopping_items(*)
            )
          ''')
          .eq('user_id', int.parse(userId));

      List<ShoppingList> allLists = [];

      // Processar listas próprias
      for (var listData in ownListsResponse) {
        final items = (listData['shopping_items'] as List? ?? [])
            .map<Item>((itemData) => Item(
                  name: itemData['name'] ?? '',
                  price: (itemData['price'] ?? 0.0).toDouble(),
                  quantity: itemData['quantity'] ?? 1,
                  isCompleted: itemData['is_completed'] ?? false,
                  addedBy: itemData['added_by']?.toString(),
                  supabaseId: itemData['id']?.toString(),
                ))
            .toList();

        // Verificar se a lista tem compartilhamentos
        final shareResponse = await SupabaseService.client
            .from('shared_lists')
            .select('id')
            .eq('list_id', listData['id']);
        
        final shareCount = shareResponse.length;

        allLists.add(ShoppingList(
          name: listData['name'] ?? '',
          items: items,
          createdAt: DateTime.parse(listData['created_at']),
          id: listData['id'].toString(),
          ownerId: listData['owner_id'].toString(),
          isShared: shareCount > 0,
        ));
      }

      // Processar listas compartilhadas
      for (var sharedData in sharedListsResponse) {
        final listData = sharedData['shopping_lists'];
        final items = (listData['shopping_items'] as List? ?? [])
            .map<Item>((itemData) => Item(
                  name: itemData['name'] ?? '',
                  price: (itemData['price'] ?? 0.0).toDouble(),
                  quantity: itemData['quantity'] ?? 1,
                  isCompleted: itemData['is_completed'] ?? false,
                  addedBy: itemData['added_by']?.toString(),
                  supabaseId: itemData['id']?.toString(),
                ))
            .toList();

        allLists.add(ShoppingList(
          name: listData['name'],
          items: items,
          createdAt: DateTime.parse(listData['created_at']),
          id: listData['id'].toString(),
          ownerId: listData['owner_id'].toString(),
          isShared: true,
        ));
      }

      return allLists;
    } catch (error) {
      throw Exception('Erro ao carregar listas: $error');
    }
  }

  // Adicionar item à lista (funciona para listas próprias e compartilhadas)
  static Future<void> addItemToList(String listId, Item item, {String? addedByUserId}) async {
    try {
      print('addItemToList - Iniciando...');
      print('Lista ID: $listId');
      print('Item: ${item.name}');
      print('Adicionado por: $addedByUserId');
      
      final itemData = {
        'list_id': int.parse(listId),
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'is_completed': item.isCompleted,
        'added_by': addedByUserId != null ? int.parse(addedByUserId) : null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('Dados do item: $itemData');
      
      final response = await SupabaseService.client
          .from('shopping_items')
          .insert(itemData)
          .select()
          .single();
      
      print('Resposta do Supabase: $response');
      
      // Atualizar o item com o ID do Supabase
      item.supabaseId = response['id'].toString();
      
      print('Item salvo com sucesso! Supabase ID: ${item.supabaseId}');
    } catch (error) {
      print('Erro ao adicionar item: $error');
      throw Exception('Erro ao adicionar item: $error');
    }
  }

  // Atualizar item na lista
  static Future<void> updateItemInList(String listId, String itemSupabaseId, Item item) async {
    try {
      await SupabaseService.client
          .from('shopping_items')
          .update({
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'is_completed': item.isCompleted,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', int.parse(itemSupabaseId))
          .eq('list_id', int.parse(listId));
    } catch (error) {
      throw Exception('Erro ao atualizar item: $error');
    }
  }

  // Remover item da lista
  static Future<void> removeItemFromList(String listId, String itemSupabaseId) async {
    try {
      await SupabaseService.client
          .from('shopping_items')
          .delete()
          .eq('id', int.parse(itemSupabaseId))
          .eq('list_id', int.parse(listId));
    } catch (error) {
      throw Exception('Erro ao remover item: $error');
    }
  }

  // Obter lista específica com seus itens
  static Future<ShoppingList?> getListWithItems(String listId) async {
    try {
      // Buscar a lista
      final listResponse = await SupabaseService.client
          .from('shopping_lists')
          .select()
          .eq('id', int.parse(listId))
          .single();

      // Buscar os itens da lista
      final itemsResponse = await SupabaseService.client
          .from('shopping_items')
          .select()
          .eq('list_id', int.parse(listId));

      // Converter os itens
      List<Item> items = itemsResponse.map<Item>((itemData) => Item(
        name: itemData['name'],
        price: (itemData['price'] ?? 0.0).toDouble(),
        quantity: itemData['quantity'] ?? 1,
        isCompleted: itemData['is_completed'] ?? false,
        addedBy: itemData['added_by']?.toString(),
        supabaseId: itemData['id'].toString(),
      )).toList();

      // Converter a lista
      ShoppingList list = ShoppingList(
        name: listResponse['name'],
        items: items,
        id: listResponse['id'].toString(),
        ownerId: listResponse['owner_id'].toString(),
        isShared: listResponse['is_shared'] ?? false,
        createdAt: DateTime.parse(listResponse['created_at']),
        sharedWith: [],
      );

      return list;
    } catch (error) {
      print('Erro ao carregar lista: $error');
      throw Exception('Erro ao carregar lista: $error');
    }
  }

  // Recarregar lista após mudanças
  static Future<void> refreshListFromSupabase(ShoppingList list) async {
    if (list.id == null) return;
    
    try {
      final updatedList = await getListWithItems(list.id!);
      if (updatedList != null) {
        list.items.clear();
        list.items.addAll(updatedList.items);
      }
    } catch (error) {
      print('Erro ao recarregar lista: $error');
    }
  }

  // Obter lista de usuários que têm acesso à lista
  static Future<List<String>> getListCollaborators(String listId) async {
    try {
      final response = await SupabaseService.client
          .from('shared_lists')
          .select('''
            Users!shared_lists_user_id_fkey(Username)
          ''')
          .eq('list_id', int.parse(listId));

      return response.map<String>((item) => item['Users']['Username'] as String).toList();
    } catch (error) {
      throw Exception('Erro ao carregar colaboradores: $error');
    }
  }

  // Remover compartilhamento
  static Future<void> removeUserFromList(String listId, String username) async {
    try {
      // Buscar ID do usuário
      final userResponse = await SupabaseService.client
          .from('Users')
          .select('id')
          .eq('Username', username.trim())
          .single();

      final userId = userResponse['id'];

      // Remover compartilhamento
      await SupabaseService.client
          .from('shared_lists')
          .delete()
          .eq('list_id', int.parse(listId))
          .eq('user_id', userId);

      // Verificar se ainda há outros compartilhamentos
      final remainingShares = await SupabaseService.client
          .from('shared_lists')
          .select('id')
          .eq('list_id', int.parse(listId));

      // Se não há mais compartilhamentos, marcar lista como não compartilhada
      if (remainingShares.isEmpty) {
        await SupabaseService.client
            .from('shopping_lists')
            .update({'is_shared': false})
            .eq('id', int.parse(listId));
      }
    } catch (error) {
      throw Exception('Erro ao remover usuário: $error');
    }
  }

  // Deletar lista completamente (apenas para o dono)
  static Future<void> deleteList(String listId, String userId) async {
    try {
      // Verificar se o usuário é o dono da lista
      final listResponse = await SupabaseService.client
          .from('shopping_lists')
          .select('owner_id')
          .eq('id', int.parse(listId))
          .single();

      if (listResponse['owner_id'].toString() != userId) {
        throw Exception('Apenas o dono pode deletar a lista');
      }

      // Deletar todos os itens da lista
      await SupabaseService.client
          .from('shopping_items')
          .delete()
          .eq('list_id', int.parse(listId));

      // Deletar todos os compartilhamentos
      await SupabaseService.client
          .from('shared_lists')
          .delete()
          .eq('list_id', int.parse(listId));

      // Deletar a lista
      await SupabaseService.client
          .from('shopping_lists')
          .delete()
          .eq('id', int.parse(listId));

    } catch (error) {
      throw Exception('Erro ao deletar lista: $error');
    }
  }

  // Remover usuário da lista compartilhada (deixar de ser convidado)
  static Future<void> leaveSharedList(String listId, String userId) async {
    try {
      // Remover o compartilhamento para este usuário
      await SupabaseService.client
          .from('shared_lists')
          .delete()
          .eq('list_id', int.parse(listId))
          .eq('user_id', int.parse(userId));

      // Verificar se ainda há outros compartilhamentos
      final remainingShares = await SupabaseService.client
          .from('shared_lists')
          .select('id')
          .eq('list_id', int.parse(listId));

      // Se não há mais compartilhamentos, marcar lista como não compartilhada
      if (remainingShares.isEmpty) {
        await SupabaseService.client
            .from('shopping_lists')
            .update({'is_shared': false})
            .eq('id', int.parse(listId));
      }
    } catch (error) {
      throw Exception('Erro ao sair da lista compartilhada: $error');
    }
  }

  // Verificar se o usuário é dono da lista
  static Future<bool> isListOwner(String listId, String userId) async {
    try {
      final response = await SupabaseService.client
          .from('shopping_lists')
          .select('owner_id')
          .eq('id', int.parse(listId))
          .single();

      return response['owner_id'].toString() == userId;
    } catch (error) {
      return false;
    }
  }
}
