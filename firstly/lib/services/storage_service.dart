import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/list.dart';

class StorageService {
  static const String _shoppingListsKey = 'shopping_lists';
  static const String _sortPreferenceKey = 'sort_preference';

  /// Salva as listas de compras no armazenamento local
  static Future<void> saveShoppingLists(List<ShoppingList> lists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listsJson = lists.map((list) => list.toMap()).toList();
      final jsonString = jsonEncode(listsJson);
      await prefs.setString(_shoppingListsKey, jsonString);
    } catch (e) {
      print('Erro ao salvar listas: $e');
    }
  }

  /// Carrega as listas de compras do armazenamento local
  static Future<List<ShoppingList>> loadShoppingLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_shoppingListsKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ShoppingList.fromMap(json)).toList();
    } catch (e) {
      print('Erro ao carregar listas: $e');
      return [];
    }
  }

  /// Remove todas as listas salvas (útil para reset do app)
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_shoppingListsKey);
    } catch (e) {
      print('Erro ao limpar dados: $e');
    }
  }

  /// Salva a preferência de ordenação do usuário
  static Future<void> saveSortPreference(SortCriteria criteria) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sortPreferenceKey, criteria.toString());
    } catch (e) {
      print('Erro ao salvar preferência de ordenação: $e');
    }
  }

  /// Carrega a preferência de ordenação do usuário
  static Future<SortCriteria> loadSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferenceString = prefs.getString(_sortPreferenceKey);
      
      if (preferenceString == null) {
        return SortCriteria.smart; // Padrão
      }

      // Converte a string de volta para o enum
      return SortCriteria.values.firstWhere(
        (criteria) => criteria.toString() == preferenceString,
        orElse: () => SortCriteria.smart,
      );
    } catch (e) {
      print('Erro ao carregar preferência de ordenação: $e');
      return SortCriteria.smart;
    }
  }

  /// Limpa apenas a preferência de ordenação
  static Future<void> clearSortPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sortPreferenceKey);
    } catch (e) {
      print('Erro ao limpar preferência de ordenação: $e');
    }
  }

  /// Salva qualquer dado nas preferências (método genérico)
  static Future<void> saveToPrefs(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(key, jsonString);
    } catch (e) {
      print('Erro ao salvar $key: $e');
    }
  }

  /// Carrega qualquer dado das preferências (método genérico)
  static Future<dynamic> loadFromPrefs(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      
      if (jsonString == null) {
        return null;
      }

      return jsonDecode(jsonString);
    } catch (e) {
      print('Erro ao carregar $key: $e');
      return null;
    }
  }
}
