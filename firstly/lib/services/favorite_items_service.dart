import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_item.dart';

enum FavoriteSortCriteria {
  alphabetical,
  mostUsed,
  recentlyUsed,
  recentlyAdded,
  priceAscending,
  priceDescending,
}

class FavoriteItemsService {
  static const String _favoriteItemsKey = 'favorite_items';
  static const String _favoriteSortPreferenceKey = 'favorite_sort_preference';

  /// Salva os itens favoritos no armazenamento local
  static Future<void> saveFavoriteItems(List<FavoriteItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = items.map((item) => item.toMap()).toList();
      final jsonString = jsonEncode(itemsJson);
      await prefs.setString(_favoriteItemsKey, jsonString);
      print('=== SALVANDO FAVORITOS ===');
      print('Total de itens: ${items.length}');
      for (var item in items) {
        print('Item: ${item.name}, Imagem: ${item.imagePath ?? "sem imagem"}');
      }
    } catch (e) {
      print('Erro ao salvar itens favoritos: $e');
    }
  }

  /// Carrega os itens favoritos do armazenamento local
  static Future<List<FavoriteItem>> loadFavoriteItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_favoriteItemsKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final items = jsonList.map((json) => FavoriteItem.fromMap(json)).toList();
      
      print('=== CARREGANDO FAVORITOS ===');
      print('Total de itens carregados: ${items.length}');
      for (var item in items) {
        print('Item: ${item.name}, Imagem: ${item.imagePath ?? "sem imagem"}');
      }
      
      return items;
    } catch (e) {
      print('Erro ao carregar itens favoritos: $e');
      return [];
    }
  }

  /// Adiciona um item aos favoritos
  static Future<void> addFavoriteItem(FavoriteItem item) async {
    try {
      final items = await loadFavoriteItems();
      
      // Verifica se já existe um item com o mesmo nome (case insensitive)
      final existingIndex = items.indexWhere(
        (existing) => existing.name.toLowerCase() == item.name.toLowerCase()
      );
      
      if (existingIndex >= 0) {
        // Se já existe, atualiza o preço padrão, incrementa o uso E preserva/atualiza a imagem
        items[existingIndex].updateDefaultPrice(item.defaultPrice);
        items[existingIndex].incrementUsage();
        
        // Atualiza a imagem se uma nova foi fornecida
        if (item.imagePath != null && item.imagePath!.isNotEmpty) {
          items[existingIndex].imagePath = item.imagePath;
          print('Imagem atualizada para item existente: ${item.imagePath}');
        }
      } else {
        // Se não existe, adiciona o novo item
        items.add(item);
        print('Novo item favorito adicionado com imagem: ${item.imagePath}');
      }
      
      await saveFavoriteItems(items);
    } catch (e) {
      print('Erro ao adicionar item favorito: $e');
    }
  }

  /// Remove um item dos favoritos
  static Future<void> removeFavoriteItem(String itemId) async {
    try {
      final items = await loadFavoriteItems();
      items.removeWhere((item) => item.id == itemId);
      await saveFavoriteItems(items);
    } catch (e) {
      print('Erro ao remover item favorito: $e');
    }
  }

  /// Incrementa o uso de um item favorito
  static Future<void> incrementItemUsage(String itemName) async {
    try {
      final items = await loadFavoriteItems();
      final itemIndex = items.indexWhere(
        (item) => item.name.toLowerCase() == itemName.toLowerCase()
      );
      
      if (itemIndex >= 0) {
        items[itemIndex].incrementUsage();
        await saveFavoriteItems(items);
      }
    } catch (e) {
      print('Erro ao incrementar uso do item favorito: $e');
    }
  }

  /// Verifica se um item está nos favoritos
  static Future<bool> isFavorite(String itemName) async {
    try {
      final items = await loadFavoriteItems();
      return items.any(
        (item) => item.name.toLowerCase() == itemName.toLowerCase()
      );
    } catch (e) {
      print('Erro ao verificar se item é favorito: $e');
      return false;
    }
  }

  /// Retorna os itens favoritos ordenados conforme o critério
  static Future<List<FavoriteItem>> getSortedFavoriteItems(FavoriteSortCriteria criteria) async {
    try {
      final items = await loadFavoriteItems();
      
      switch (criteria) {
        case FavoriteSortCriteria.alphabetical:
          items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case FavoriteSortCriteria.mostUsed:
          items.sort((a, b) => b.usageCount.compareTo(a.usageCount));
          break;
        case FavoriteSortCriteria.recentlyUsed:
          items.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
          break;
        case FavoriteSortCriteria.recentlyAdded:
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case FavoriteSortCriteria.priceAscending:
          items.sort((a, b) => a.defaultPrice.compareTo(b.defaultPrice));
          break;
        case FavoriteSortCriteria.priceDescending:
          items.sort((a, b) => b.defaultPrice.compareTo(a.defaultPrice));
          break;
      }
      
      return items;
    } catch (e) {
      print('Erro ao carregar itens favoritos ordenados: $e');
      return [];
    }
  }

  /// Salva a preferência de ordenação dos favoritos
  static Future<void> saveFavoriteSortPreference(FavoriteSortCriteria criteria) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favoriteSortPreferenceKey, criteria.toString());
    } catch (e) {
      print('Erro ao salvar preferência de ordenação dos favoritos: $e');
    }
  }

  /// Carrega a preferência de ordenação dos favoritos
  static Future<FavoriteSortCriteria> loadFavoriteSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferenceString = prefs.getString(_favoriteSortPreferenceKey);
      
      if (preferenceString == null) {
        return FavoriteSortCriteria.mostUsed; // Padrão
      }

      return FavoriteSortCriteria.values.firstWhere(
        (criteria) => criteria.toString() == preferenceString,
        orElse: () => FavoriteSortCriteria.mostUsed,
      );
    } catch (e) {
      print('Erro ao carregar preferência de ordenação dos favoritos: $e');
      return FavoriteSortCriteria.mostUsed;
    }
  }

  /// Limpa todos os itens favoritos
  static Future<void> clearAllFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoriteItemsKey);
    } catch (e) {
      print('Erro ao limpar itens favoritos: $e');
    }
  }

  /// Busca itens favoritos por nome
  static Future<List<FavoriteItem>> searchFavoriteItems(String query) async {
    try {
      final items = await loadFavoriteItems();
      final searchQuery = query.toLowerCase();
      
      return items.where((item) => 
        item.name.toLowerCase().contains(searchQuery)
      ).toList();
    } catch (e) {
      print('Erro ao buscar itens favoritos: $e');
      return [];
    }
  }

  /// Cria um item favorito a partir de um item da lista
  static FavoriteItem createFavoriteFromItem(String name, double price, int quantity) {
    return FavoriteItem(
      name: name,
      defaultPrice: price,
      defaultQuantity: quantity,
      usageCount: 1,
    );
  }
}
