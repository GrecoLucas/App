import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/pending_item.dart';

class PendingItemsService {
  static const String _pendingItemsKey = 'pending_items';

  /// Salva os itens pendentes no armazenamento local
  static Future<void> savePendingItems(List<PendingItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = items.map((item) => item.toMap()).toList();
      final jsonString = jsonEncode(itemsJson);
      await prefs.setString(_pendingItemsKey, jsonString);
    } catch (e) {
      print('Erro ao salvar itens pendentes: $e');
    }
  }

  /// Carrega os itens pendentes do armazenamento local
  static Future<List<PendingItem>> loadPendingItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pendingItemsKey);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => PendingItem.fromMap(json)).toList();
    } catch (e) {
      print('Erro ao carregar itens pendentes: $e');
      return [];
    }
  }

  /// Adiciona um item à lista de pendentes
  static Future<void> addPendingItem(PendingItem item) async {
    try {
      final items = await loadPendingItems();

      // Verifica se já existe um item com o mesmo nome (case insensitive)
      final existingIndex = items.indexWhere(
        (existing) => existing.name.toLowerCase() == item.name.toLowerCase(),
      );

      if (existingIndex >= 0) {
        // Se já existe, atualiza preço e quantidade
        items[existingIndex].price = item.price;
        items[existingIndex].quantity = item.quantity;
      } else {
        items.add(item);
      }

      await savePendingItems(items);
    } catch (e) {
      print('Erro ao adicionar item pendente: $e');
    }
  }

  /// Remove um item da lista de pendentes pelo ID
  static Future<void> removePendingItem(String itemId) async {
    try {
      final items = await loadPendingItems();
      items.removeWhere((item) => item.id == itemId);
      await savePendingItems(items);
    } catch (e) {
      print('Erro ao remover item pendente: $e');
    }
  }

  /// Remove múltiplos itens pendentes pelos IDs
  static Future<void> removePendingItems(List<String> itemIds) async {
    try {
      final items = await loadPendingItems();
      items.removeWhere((item) => itemIds.contains(item.id));
      await savePendingItems(items);
    } catch (e) {
      print('Erro ao remover itens pendentes: $e');
    }
  }

  /// Retorna a quantidade de itens pendentes
  static Future<int> getPendingCount() async {
    final items = await loadPendingItems();
    return items.length;
  }
}
