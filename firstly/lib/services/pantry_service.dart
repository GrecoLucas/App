import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pantry_item.dart';
import '../models/item.dart';

class PantryService {
  static const String _pantryKey = 'pantry_items';

  // Load all pantry items
  static Future<List<PantryItem>> loadPantryItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pantryKey);
      
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      var items = jsonList.map((json) => PantryItem.fromMap(json)).toList();
      
      // Process auto-consumption
      bool hasUpdates = false;
      final now = DateTime.now();
      
      for (var item in items) {
        if (item.autoConsumeDays != null && item.autoConsumeDays! > 0) {
          // Initialize start date if missing
          item.lastAutoConsumeDate ??= now;
          
          final difference = now.difference(item.lastAutoConsumeDate!);
          final daysElapsed = difference.inDays;
          
          if (daysElapsed >= item.autoConsumeDays!) {
             final decrements = (daysElapsed / item.autoConsumeDays!).floor();
             if (decrements > 0) {
               // Decrease quantity
               item.quantity = (item.quantity - decrements);
               if (item.quantity < 0) item.quantity = 0;
               
               // Update last processed date
               // We advance the date by exact intervals to keep schedule
               item.lastAutoConsumeDate = item.lastAutoConsumeDate!.add(
                 Duration(days: decrements * item.autoConsumeDays!)
               );
               
               hasUpdates = true;
             }
          }
        }
      }
      
      if (hasUpdates) {
        // Save changes back to storage
        // We can't use savePantryItems here directly easily because this function IS called by other things?
        // Actually savePantryItems is static, so it's fine.
        // But wait, savePantryItems calls get instance again.
        // It's safer to just save the modified list we have.
        final itemsJson = items.map((item) => item.toMap()).toList();
        final newJsonString = jsonEncode(itemsJson);
        await prefs.setString(_pantryKey, newJsonString);
      }

      return items;
    } catch (e) {
      print('Error loading pantry items: $e');
      return [];
    }
  }

  // Save pantry items
  static Future<void> savePantryItems(List<PantryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = items.map((item) => item.toMap()).toList();
      final jsonString = jsonEncode(itemsJson);
      await prefs.setString(_pantryKey, jsonString);
    } catch (e) {
      print('Error saving pantry items: $e');
    }
  }

  // Add items from a shopping list (handling duplicates)
  static Future<int> addItemsFromList(List<Item> itemsToAdd) async {
    final currentItems = await loadPantryItems();
    int addedCount = 0;

    for (var newItem in itemsToAdd) {
      // Check if item already exists (by name, case insensitive)
      final existingIndex = currentItems.indexWhere(
        (i) => i.name.toLowerCase() == newItem.name.toLowerCase()
      );

      if (existingIndex >= 0) {
        // Update quantity if exists
        currentItems[existingIndex].quantity += newItem.quantity;
        // Optionally update addedDate to bring it to top/freshness? 
        // currentItems[existingIndex].addedDate = DateTime.now(); 
      } else {
        // Add new item
        currentItems.add(PantryItem.fromItem(newItem));
        addedCount++;
      }
    }

    await savePantryItems(currentItems);
    return addedCount;
  }

  // Update a single item
  static Future<void> updateItem(PantryItem updatedItem) async {
    final items = await loadPantryItems();
    final index = items.indexWhere((i) => i.id == updatedItem.id);
    if (index >= 0) {
      items[index] = updatedItem;
      await savePantryItems(items);
    }
  }

  // Remove an item
  static Future<void> removeItem(String itemId) async {
    final items = await loadPantryItems();
    items.removeWhere((i) => i.id == itemId);
    await savePantryItems(items);
  }
}
