class FavoriteItem {
  String id;
  String name;
  double defaultPrice;
  int defaultQuantity;
  int usageCount; // Contador de quantas vezes foi usado
  DateTime lastUsed;
  DateTime createdAt;

  FavoriteItem({
    String? id,
    required this.name,
    this.defaultPrice = 0.0,
    this.defaultQuantity = 1,
    this.usageCount = 0,
    DateTime? lastUsed,
    DateTime? createdAt,
  }) : 
    id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    lastUsed = lastUsed ?? DateTime.now(),
    createdAt = createdAt ?? DateTime.now();

  // Incrementa o contador de uso e atualiza a última vez que foi usado
  void incrementUsage() {
    usageCount++;
    lastUsed = DateTime.now();
  }

  // Atualiza o preço padrão (usado quando o item é adicionado com um novo preço)
  void updateDefaultPrice(double newPrice) {
    if (newPrice > 0) {
      defaultPrice = newPrice;
    }
  }

  // Método para converter o item favorito para Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'defaultPrice': defaultPrice,
      'defaultQuantity': defaultQuantity,
      'usageCount': usageCount,
      'lastUsed': lastUsed.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Método para criar um FavoriteItem a partir de um Map
  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'],
      name: map['name'] ?? '',
      defaultPrice: map['defaultPrice']?.toDouble() ?? 0.0,
      defaultQuantity: map['defaultQuantity']?.toInt() ?? 1,
      usageCount: map['usageCount']?.toInt() ?? 0,
      lastUsed: DateTime.fromMillisecondsSinceEpoch(map['lastUsed'] ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  // Cria uma cópia do item favorito para ser adicionado à lista
  Map<String, dynamic> toItemData() {
    return {
      'name': name,
      'price': defaultPrice,
      'quantity': defaultQuantity,
    };
  }
}
