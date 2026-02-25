import 'package:flutter/material.dart';
import '../../../core/models/item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../shopping/models/list.dart';

class ReviewPage extends StatefulWidget {
  final List<Item> scannedItems;

  const ReviewPage({Key? key, required this.scannedItems}) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late List<Item> _items;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Create a copy so we can edit
    _items = List.from(widget.scannedItems);
  }

  void _editItem(int index) {
    final item = _items[index];
    final titleController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toStringAsFixed(2));
    final qtyController = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Nome do Produdo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço (€)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  item.name = titleController.text;
                  item.price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? item.price;
                  item.quantity = int.tryParse(qtyController.text) ?? item.quantity;
                });
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _confirmAndSave() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum item para adicionar.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Logic to save items
      // For now, let's create a new ShoppingList or ask the user which list to add it to
      // A simplified approach is to show a dialog choosing an existing list
      
      final lists = await StorageService.loadShoppingLists();
      if(lists.isEmpty){
        // Create new list
         final newList = ShoppingList(
          name: 'Fatura - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          items: _items,
        );
        lists.add(newList);
        await StorageService.saveShoppingLists(lists);
      } else {
         // show dialog to pick list or create new
         if(!mounted) return;
         await showDialog(context: context, builder: (ctx) {
             return AlertDialog(
                title: const Text('Para qual lista quer adicionar?'),
                content: SizedBox(
                   width: double.maxFinite,
                   child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: lists.length + 1,
                      itemBuilder: (context, i) {
                         if(i == 0) {
                            return ListTile(
                               leading: const Icon(Icons.add),
                               title: const Text('Criar Nova Lista'),
                               onTap: () {
                                  final newList = ShoppingList(
                                     name: 'Fatura - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                     items: _items,
                                  );
                                  lists.insert(0, newList);
                                  Navigator.pop(context, true);
                               },
                            );
                         }
                         final list = lists[i-1];
                         return ListTile(
                            leading: const Icon(Icons.list),
                            title: Text(list.name),
                            onTap: () {
                               list.items.addAll(_items);
                               Navigator.pop(context, true);
                            },
                         );
                      }
                   )
                ),
             );
         });
         await StorageService.saveShoppingLists(lists);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itens guardados com sucesso!')),
        );
        // Voltar para a home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao guardar os itens: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculando o total
    final total = _items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rever Produtos Mapeados'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  color: AppTheme.softGrey,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Encontrado: ${_items.length}',
                        style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total: €${total.toStringAsFixed(2)}',
                        style: AppStyles.headingMedium.copyWith(color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text('Nenhum produto reconhecido.'))
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                title: Text(item.name, style: AppStyles.bodyMedium),
                                subtitle: Text(
                                  'Qtd: ${item.quantity}  |  Preço: €${item.price.toStringAsFixed(2)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _editItem(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppTheme.warningRed),
                                      onPressed: () => _removeItem(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: ElevatedButton(
            onPressed: _isLoading || _items.isEmpty ? null : _confirmAndSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRMAR E ADICIONAR', style: AppStyles.headingSmall),
          ),
        ),
      ),
    );
  }
}
