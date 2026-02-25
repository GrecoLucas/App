class Item {
  String id;
  String name;
  double price;
  int quantity; 
  bool isCompleted;
  bool isAddedToPantry;
  bool isPending;
  DateTime lastModified;

  Item({
    String? id,
    required this.name,
    this.price = 0.0,
    this.quantity = 1,
    this.isCompleted = false,
    this.isAddedToPantry = false,
    this.isPending = false,
    DateTime? lastModified,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       lastModified = lastModified ?? DateTime.now();

  Item copyWithNewVersion() {
    return Item(
      id: id,
      name: name,
      price: price,
      quantity: quantity,
      isCompleted: isCompleted,
      isAddedToPantry: isAddedToPantry,
      isPending: isPending,
      lastModified: DateTime.now(),
    );
  }

  // Método para converter o item para Map (útil para persistência futura)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity, 
      'price': price,
      'isCompleted': isCompleted,
      'isAddedToPantry': isAddedToPantry,
      'isPending': isPending,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  // Método para converter o item para JSON
  Map<String, dynamic> toJson() => toMap();

  // Método para criar um Item a partir de um Map
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 1,
      isCompleted: map['isCompleted'] ?? false,
      isAddedToPantry: map['isAddedToPantry'] ?? false,
      isPending: map['isPending'] ?? false,
      lastModified: map['lastModified'] != null 
          ? DateTime.tryParse(map['lastModified']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Método para criar um Item a partir de JSON
  factory Item.fromJson(Map<String, dynamic> json) => Item.fromMap(json);
}