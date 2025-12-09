import 'item.dart';

class PantryItem {
  final String id;
  String name;
  int quantity;
  DateTime addedDate;
  DateTime? expirationDate;
  String category;
  int? autoConsumeDays; // Dias para diminuir 1 unidade
  DateTime? lastAutoConsumeDate; // Data da última diminuição/início

  PantryItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    required this.addedDate,
    this.expirationDate,
    this.category = 'Geral',
    this.autoConsumeDays,
    this.lastAutoConsumeDate,
  });

  // Convert to Map for JSON storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'expirationDate': expirationDate?.millisecondsSinceEpoch,
      'category': category,
      'autoConsumeDays': autoConsumeDays,
      'lastAutoConsumeDate': lastAutoConsumeDate?.millisecondsSinceEpoch,
    };
  }

  // Create from Map
  factory PantryItem.fromMap(Map<String, dynamic> map) {
    return PantryItem(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'] ?? 1,
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['addedDate']),
      expirationDate: map['expirationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expirationDate'])
          : null,
      category: map['category'] ?? 'Geral',
      autoConsumeDays: map['autoConsumeDays'],
      lastAutoConsumeDate: map['lastAutoConsumeDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastAutoConsumeDate'])
          : null,
    );
  }

  // Create from Shopping List Item
  factory PantryItem.fromItem(Item item) {
    return PantryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString() + item.name.hashCode.toString(), // Unique ID generation
      name: item.name,
      quantity: item.quantity,
      addedDate: DateTime.now(),
      category: 'Geral', // Default category
    );
  }
}
