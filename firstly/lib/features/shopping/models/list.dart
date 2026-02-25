import '../../../core/models/item.dart';

enum SortCriteria {
  alphabetical,
  priceAscending,
  priceDescending,
  quantityAscending,
  quantityDescending,
  totalValueAscending,
  totalValueDescending,
  smart, // Padrão: Não marcados primeiro (A-Z), depois marcados (A-Z)
}

class ShoppingList {
  String name;
  List<Item> items;
  DateTime createdAt;
  double? budget; // Orçamento opcional da lista

  ShoppingList({
    required this.name,
    required this.items,
    DateTime? createdAt,
    this.budget,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calcula o total da lista considerando a quantidade
  double get totalPrice {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Calcula o valor restante do orçamento
  double get remainingBudget {
    if (budget == null) return 0.0;
    return budget! - totalPrice;
  }

  // Calcula a porcentagem do orçamento utilizada
  double get budgetUsagePercentage {
    if (budget == null || budget == 0) return 0.0;
    return (totalPrice / budget!) * 100;
  }

  // Verifica se o orçamento foi ultrapassado
  bool get isBudgetExceeded {
    if (budget == null) return false;
    return totalPrice > budget!;
  }

  // Adiciona um item à lista
  void addItem(Item item) {
    items.add(item);
  }

  // Edita um item da lista
  void editItem(String itemId, String newName, double newPrice, int newQuantity) {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      items[index].name = newName;
      items[index].price = newPrice;
      items[index].quantity = newQuantity;
    }
  }

  // Remove um item da lista
  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  // Ordena os itens da lista conforme o critério especificado
  void sortItems(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.alphabetical:
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortCriteria.priceAscending:
        items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortCriteria.priceDescending:
        items.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortCriteria.quantityAscending:
        items.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case SortCriteria.quantityDescending:
        items.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case SortCriteria.totalValueAscending:
        items.sort((a, b) => (a.price * a.quantity).compareTo(b.price * b.quantity));
        break;
      case SortCriteria.totalValueDescending:
        items.sort((a, b) => (b.price * b.quantity).compareTo(a.price * a.quantity));
        break;
      case SortCriteria.smart:
        // Ordenação inteligente é tratada primariamente no getSortedItems
        // Aqui apenas ordenamos alfabeticamente como fallback
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
  }

  // Retorna uma nova lista com os itens ordenados (sem modificar a lista original)
  List<Item> getSortedItems(SortCriteria criteria) {
    List<Item> sortedItems = List.from(items);
    switch (criteria) {
      case SortCriteria.alphabetical:
        sortedItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortCriteria.priceAscending:
        sortedItems.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortCriteria.priceDescending:
        sortedItems.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortCriteria.quantityAscending:
        sortedItems.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case SortCriteria.quantityDescending:
        sortedItems.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case SortCriteria.totalValueAscending:
        sortedItems.sort((a, b) => (a.price * a.quantity).compareTo(b.price * b.quantity));
        break;
      case SortCriteria.totalValueDescending:
        sortedItems.sort((a, b) => (b.price * b.quantity).compareTo(a.price * a.quantity));
        break;
      case SortCriteria.smart:
        // Separa itens marcados e não marcados
        final uncheckedItems = sortedItems.where((item) => !item.isCompleted).toList();
        final checkedItems = sortedItems.where((item) => item.isCompleted).toList();
        
        // Ordena cada grupo alfabeticamente
        uncheckedItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        checkedItems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        
        // Retorna a concatenação: não marcados primeiro
        return [...uncheckedItems, ...checkedItems];
    }
    return sortedItems;
  }

  // Método para converter a lista para Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'budget': budget,
    };
  }

  // Método para converter a lista para JSON
  Map<String, dynamic> toJson() => toMap();

  // Método para criar uma ShoppingList a partir de um Map
  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      name: map['name'] ?? '',
      items: List<Item>.from(
        map['items']?.map((item) => Item.fromMap(item)) ?? [],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      budget: map['budget']?.toDouble(),
    );
  }

  // Método para criar uma ShoppingList a partir de JSON
  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList.fromMap(json);

  // Cria uma cópia da lista com itens resetados (quantidade 1, preço 0)
  ShoppingList copyAsTemplate({
    required String newName,
    double? newBudget,
  }) {
    final copiedItems = items.map((item) => 
      Item(
        name: item.name,
        price: item.price,
        quantity: item.quantity,
      )
    ).toList();
    
    return ShoppingList(
      name: newName,
      items: copiedItems,
      budget: newBudget,
    );
  }
}