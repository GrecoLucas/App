import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scanned_item.dart';
import '../models/expense_list.dart';

class BarcodeService {
  static const String _scannedItemsKey = 'scanned_items_database';
  static const String _expenseListsKey = 'expense_lists';

  /// Salva um item escaneado no banco local (para reutilização)
  static Future<void> saveScannedItemToDatabase(ScannedItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingItems = await _loadScannedItemsDatabase();
      
      // Verifica se já existe um item com o mesmo código de barras
      final existingIndex = existingItems.indexWhere(
        (existingItem) => existingItem.barcode == item.barcode,
      );
      
      if (existingIndex >= 0) {
        // Atualiza o item existente
        existingItems[existingIndex] = item;
      } else {
        // Adiciona novo item
        existingItems.add(item);
      }
      
      final itemsJson = existingItems.map((item) => item.toMap()).toList();
      final jsonString = jsonEncode(itemsJson);
      await prefs.setString(_scannedItemsKey, jsonString);
    } catch (e) {
      print('Erro ao salvar item escaneado: $e');
    }
  }

  /// Carrega todos os itens escaneados do banco local
  static Future<List<ScannedItem>> _loadScannedItemsDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_scannedItemsKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ScannedItem.fromMap(json)).toList();
    } catch (e) {
      print('Erro ao carregar itens escaneados: $e');
      return [];
    }
  }

  /// Retorna todos os itens escaneados salvos (método público)
  static Future<List<ScannedItem>> getAllScannedItems() async {
    return await _loadScannedItemsDatabase();
  }

  /// Remove um item específico do banco local
  static Future<void> removeScannedItem(String itemId) async {
    try {
      final existingItems = await _loadScannedItemsDatabase();
      existingItems.removeWhere((item) => item.id == itemId);
      
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = existingItems.map((item) => item.toMap()).toList();
      final jsonString = jsonEncode(itemsJson);
      await prefs.setString(_scannedItemsKey, jsonString);
    } catch (e) {
      print('Erro ao remover item escaneado: $e');
    }
  }

  /// Remove todos os itens escaneados
  static Future<void> clearAllScannedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scannedItemsKey);
    } catch (e) {
      print('Erro ao limpar itens escaneados: $e');
    }
  }

  /// Busca um item pelo código de barras no banco local
  static Future<ScannedItem?> findItemByBarcode(String barcode) async {
    try {
      final items = await _loadScannedItemsDatabase();
      for (final item in items) {
        if (item.barcode == barcode) {
          return item;
        }
      }
      return null;
    } catch (e) {
      print('Erro ao buscar item por código de barras: $e');
      return null;
    }
  }

  /// Salva todas as listas de gastos
  static Future<void> saveExpenseLists(List<ExpenseList> lists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listsJson = lists.map((list) => list.toMap()).toList();
      final jsonString = jsonEncode(listsJson);
      await prefs.setString(_expenseListsKey, jsonString);
    } catch (e) {
      print('Erro ao salvar listas de gastos: $e');
    }
  }

  /// Carrega todas as listas de gastos
  static Future<List<ExpenseList>> loadExpenseLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_expenseListsKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => ExpenseList.fromMap(json)).toList();
    } catch (e) {
      print('Erro ao carregar listas de gastos: $e');
      return [];
    }
  }

  /// Remove uma lista de gastos
  static Future<void> removeExpenseList(String listId) async {
    try {
      final lists = await loadExpenseLists();
      lists.removeWhere((list) => list.id == listId);
      await saveExpenseLists(lists);
    } catch (e) {
      print('Erro ao remover lista de gastos: $e');
    }
  }

  /// Atualiza uma lista de gastos específica
  static Future<void> updateExpenseList(ExpenseList updatedList) async {
    try {
      final lists = await loadExpenseLists();
      final index = lists.indexWhere((list) => list.id == updatedList.id);
      
      if (index >= 0) {
        lists[index] = updatedList;
        await saveExpenseLists(lists);
      }
    } catch (e) {
      print('Erro ao atualizar lista de gastos: $e');
    }
  }

  /// Estatísticas dos gastos
  static Future<Map<String, dynamic>> getExpenseStats() async {
    try {
      final lists = await loadExpenseLists();
      double totalSpent = 0;
      int totalItems = 0;
      
      for (final list in lists) {
        totalSpent += list.totalExpense;
        totalItems += list.totalItems;
      }
      
      return {
        'totalSpent': totalSpent,
        'totalItems': totalItems,
        'totalLists': lists.length,
        'averagePerList': lists.isNotEmpty ? totalSpent / lists.length : 0.0,
      };
    } catch (e) {
      print('Erro ao calcular estatísticas: $e');
      return {
        'totalSpent': 0.0,
        'totalItems': 0,
        'totalLists': 0,
        'averagePerList': 0.0,
      };
    }
  }
}
