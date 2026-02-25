class PendingItem {
  String id;
  String name;
  double price;
  int quantity;
  DateTime createdAt;

  PendingItem({
    String? id,
    required this.name,
    this.price = 0.0,
    this.quantity = 1,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PendingItem.fromMap(Map<String, dynamic> map) {
    return PendingItem(
      id: map['id'],
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}
