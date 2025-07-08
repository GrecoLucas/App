class ScannedItem {
  final String id;
  final String barcode;
  final String name;
  final double price;
  final int quantity;
  final DateTime scannedAt;

  ScannedItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
    required this.scannedAt,
  });

  // Cria um item escaneado com valores padrão
  ScannedItem.create({
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       scannedAt = DateTime.now();

  // Converte para Map para salvar no armazenamento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'quantity': quantity,
      'scannedAt': scannedAt.millisecondsSinceEpoch,
    };
  }

  // Cria um ScannedItem a partir de um Map
  factory ScannedItem.fromMap(Map<String, dynamic> map) {
    return ScannedItem(
      id: map['id'],
      barcode: map['barcode'],
      name: map['name'],
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity']?.toInt() ?? 1,
      scannedAt: DateTime.fromMillisecondsSinceEpoch(map['scannedAt']),
    );
  }

  // Calcula o valor total do item
  double get totalValue => price * quantity;

  // Formata o preço para exibição
  String get formattedPrice => '€${price.toStringAsFixed(2)}';
  
  // Formata o valor total para exibição
  String get formattedTotal => '€${totalValue.toStringAsFixed(2)}';

  // Formata a data de escaneamento
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(scannedAt);
    
    if (difference.inDays == 0) {
      return 'Hoje ${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ontem ${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${scannedAt.day.toString().padLeft(2, '0')}/${scannedAt.month.toString().padLeft(2, '0')}/${scannedAt.year}';
    }
  }

  // Cria uma cópia do item com valores modificados
  ScannedItem copyWith({
    String? id,
    String? barcode,
    String? name,
    double? price,
    int? quantity,
    DateTime? scannedAt,
  }) {
    return ScannedItem(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScannedItem &&
        other.id == id &&
        other.barcode == barcode;
  }

  @override
  int get hashCode => Object.hash(id, barcode);

  @override
  String toString() {
    return 'ScannedItem(id: $id, barcode: $barcode, name: $name, price: $price, quantity: $quantity)';
  }
}
