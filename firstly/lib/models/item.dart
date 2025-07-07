class Item {
  String id;
  String name;
  double price;
  int quantity; 

  Item({
    String? id,
    required this.name,
    required this.price,
    this.quantity = 1,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Método para converter o item para Map (útil para persistência futura)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity, 
      'price': price,
    };
  }

  // Método para criar um Item a partir de um Map
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 1,
    );
  }
}