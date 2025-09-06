class Item {
  String id;
  String name;
  double price;
  int quantity; 
  bool isCompleted;
  String? addedBy; // ID do usuário que adicionou o item
  String? supabaseId; // ID do item no Supabase (diferente do ID local)

  Item({
    String? id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.isCompleted = false,
    this.addedBy,
    this.supabaseId,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Método para converter o item para Map (útil para persistência futura)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity, 
      'price': price,
      'isCompleted': isCompleted,
      'addedBy': addedBy,
      'supabaseId': supabaseId,
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
      addedBy: map['addedBy'],
      supabaseId: map['supabaseId'],
    );
  }

  // Método para criar um Item a partir de JSON
  factory Item.fromJson(Map<String, dynamic> json) => Item.fromMap(json);
}