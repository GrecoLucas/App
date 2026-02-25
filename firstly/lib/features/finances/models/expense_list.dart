import '../../scanner/models/scanned_item.dart';

class ExpenseList {
  final String id;
  final String name;
  final List<ScannedItem> items;
  final DateTime createdAt;

  ExpenseList({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  // Cria uma nova lista de gastos
  ExpenseList.create({
    required this.name,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       items = [],
       createdAt = DateTime.now();

  // Converte para Map para salvar no armazenamento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Cria uma ExpenseList a partir de um Map
  factory ExpenseList.fromMap(Map<String, dynamic> map) {
    return ExpenseList(
      id: map['id'],
      name: map['name'],
      items: List<ScannedItem>.from(
        map['items']?.map((item) => ScannedItem.fromMap(item)) ?? [],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  // Calcula o total dos gastos
  double get totalExpense {
    return items.fold(0.0, (sum, item) => sum + item.totalValue);
  }

  // Formata o total para exibição
  String get formattedTotal => '€${totalExpense.toStringAsFixed(2)}';

  // Quantidade total de itens
  int get totalItems => items.length;

  // Adiciona um item à lista
  void addItem(ScannedItem item) {
    items.add(item);
  }

  // Remove um item da lista
  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  // Edita um item da lista
  void editItem(int index, ScannedItem updatedItem) {
    if (index >= 0 && index < items.length) {
      items[index] = updatedItem;
    }
  }

  // Formata a data de criação
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    }
  }

  // Cria uma cópia da lista com valores modificados
  ExpenseList copyWith({
    String? id,
    String? name,
    List<ScannedItem>? items,
    DateTime? createdAt,
  }) {
    return ExpenseList(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? List<ScannedItem>.from(this.items),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseList && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExpenseList(id: $id, name: $name, items: ${items.length}, total: $formattedTotal)';
  }
}
