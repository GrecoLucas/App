import 'package:flutter/material.dart';
import '../models/expense_list.dart';
import '../models/scanned_item.dart';
import '../services/barcode_service.dart';
import '../services/snackbar_service.dart';
import '../utils/app_theme.dart';
import 'barcode_scanner_screen.dart';

class ExpenseListDetailScreen extends StatefulWidget {
  final ExpenseList expenseList;
  final VoidCallback onUpdate;

  const ExpenseListDetailScreen({
    super.key,
    required this.expenseList,
    required this.onUpdate,
  });

  @override
  State<ExpenseListDetailScreen> createState() => _ExpenseListDetailScreenState();
}

class _ExpenseListDetailScreenState extends State<ExpenseListDetailScreen> {
  
  void _scanBarcode() async {
    try {
      // Navega para o scanner
      final result = await Navigator.push<ScannedItem>(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );
      
      print('Resultado do scanner: $result');
      
      if (result != null) {
        print('Adicionando item à lista: ${result.name}');
        print('Lista antes: ${widget.expenseList.items.length} itens');
        
        // Adiciona o item à lista
        widget.expenseList.addItem(result);
        
        print('Lista depois: ${widget.expenseList.items.length} itens');
        
        // Atualiza a lista no armazenamento
        await BarcodeService.updateExpenseList(widget.expenseList);
        
        // Força o rebuild da tela
        setState(() {});
        
        // Chama callback de atualização
        widget.onUpdate();
        
        if (mounted) {
          SnackBarService.success(context, '${result.name} adicionado à lista');
        }
      } else {
        print('Nenhum resultado retornado do scanner');
      }
    } catch (e) {
      print('Erro ao escanear código de barras: $e');
      if (mounted) {
        SnackBarService.error(context, 'Erro ao escanear código de barras');
      }
    }
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppTheme.warningRed,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            const Text('Remover Item'),
          ],
        ),
        content: Text('Remover "${widget.expenseList.items[index].name}" da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                widget.expenseList.removeItem(index);
              });
              
              await BarcodeService.updateExpenseList(widget.expenseList);
              widget.onUpdate();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _editItem(int index) {
    final item = widget.expenseList.items[index];
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toStringAsFixed(2));
    int quantity = item.quantity;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              const Text('Editar Item'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Produto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppTheme.softGrey,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Preço',
                    prefixText: '€ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppTheme.softGrey,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                DropdownButtonFormField<int>(
                  value: quantity,
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    filled: true,
                    fillColor: AppTheme.softGrey,
                  ),
                  items: List.generate(20, (index) => index + 1)
                      .map((qty) => DropdownMenuItem<int>(
                            value: qty,
                            child: Text('$qty'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      quantity = value ?? 1;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(
                  priceController.text.replaceAll(',', '.').replaceAll('€', '').trim(),
                ) ?? 0.0;
                
                final updatedItem = item.copyWith(
                  name: nameController.text.trim(),
                  price: price,
                  quantity: quantity,
                );
                
                setState(() {
                  widget.expenseList.editItem(index, updatedItem);
                });
                
                await BarcodeService.updateExpenseList(widget.expenseList);
                widget.onUpdate();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _addManualItem() {
    showDialog(
      context: context,
      builder: (context) => _ManualItemDialog(
        onSave: (newItem) async {
          print('Adicionando item manual: ${newItem.name}');
          
          // Adiciona o item à lista (sem salvar na base de dados)
          widget.expenseList.addItem(newItem);
          
          // Atualiza a lista no armazenamento
          await BarcodeService.updateExpenseList(widget.expenseList);
          
          // Força o rebuild da tela
          setState(() {});
          
          // Chama callback de atualização
          widget.onUpdate();
          
          if (mounted) {
            SnackBarService.info(context, '${newItem.name} adicionado à lista');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGrey,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Text(
                widget.expenseList.name,
                style: AppStyles.headingMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: widget.expenseList.items.isEmpty
                ? _buildEmptyState()
                : _buildItemsList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: _addManualItem,
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit),
            label: const Text('Inserir Manualmente'),
            heroTag: "manual_add",
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          FloatingActionButton.extended(
            onPressed: _scanBarcode,
            backgroundColor: const Color.fromARGB(255, 61, 109, 164),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear'),
            heroTag: "scan_barcode",
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.mediumShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.euro,
                          color: AppTheme.primaryGreen,
                          size: AppConstants.iconSmall,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Total Gasto:',
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.expenseList.formattedTotal,
                      style: AppStyles.headingLarge.copyWith(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text(
                      'Criada ${widget.expenseList.formattedCreatedAt}',
                      style: AppStyles.captionGrey,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: AppConstants.iconMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.expenseList.totalItems}',
                        style: AppStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.expenseList.totalItems == 1 ? 'item' : 'itens',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingXLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
                boxShadow: const [AppStyles.softShadow],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: AppConstants.iconXLarge,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  const Text(
                    'Nenhum produto escaneado',
                    style: AppStyles.headingMedium,
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  const Text(
                    'Escaneie códigos de barras para adicionar produtos à sua lista de gastos',
                    style: AppStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  const Text(
                    'Toque em "Escanear" para começar!',
                    style: AppStyles.captionGrey,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      child: ListView.builder(
        itemCount: widget.expenseList.items.length,
        itemBuilder: (context, index) {
          final item = widget.expenseList.items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              boxShadow: const [AppStyles.softShadow],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _editItem(index),
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        child: Icon(
                          Icons.qr_code,
                          color: AppTheme.primaryGreen,
                          size: AppConstants.iconMedium,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingLarge),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppStyles.bodyLarge.copyWith(
                                color: AppTheme.darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Código: ${item.barcode}',
                              style: AppStyles.captionGrey.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  item.formattedTotal,
                                  style: AppStyles.priceStyle.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: AppConstants.paddingMedium),
                                if (item.quantity > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightGreen,
                                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                                    ),
                                    child: Text(
                                      '${item.quantity}x ${item.formattedPrice}',
                                      style: AppStyles.captionGrey.copyWith(
                                        color: AppTheme.darkGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  item.formattedDate,
                                  style: AppStyles.captionGrey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editItem(index);
                              break;
                            case 'delete':
                              _removeItem(index);
                              break;
                          }
                        },
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey[600],
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, color: AppTheme.accentBlue),
                                SizedBox(width: 12),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: AppTheme.warningRed),
                                SizedBox(width: 12),
                                Text('Remover'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ManualItemDialog extends StatefulWidget {
  final Function(ScannedItem) onSave;

  const _ManualItemDialog({
    required this.onSave,
  });

  @override
  State<_ManualItemDialog> createState() => _ManualItemDialogState();
}

class _ManualItemDialogState extends State<_ManualItemDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    priceController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: const Icon(
              Icons.edit,
              color: AppTheme.accentBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          const Expanded(
            child: Text('Inserir Manualmente'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use para produtos sem código de barras (frutas, carnes, etc.)',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nome do Produto',
                hintText: 'Ex: Bananas, Carne de Vaca...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                filled: true,
                fillColor: AppTheme.softGrey,
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Preço',
                prefixText: '€ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                filled: true,
                fillColor: AppTheme.softGrey,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            DropdownButtonFormField<int>(
              value: quantity,
              decoration: InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                filled: true,
                fillColor: AppTheme.softGrey,
              ),
              items: List.generate(20, (index) => index + 1)
                  .map((qty) => DropdownMenuItem<int>(
                        value: qty,
                        child: Text('$qty'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  quantity = value ?? 1;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
          if (nameController.text.trim().isEmpty) {
              SnackBarService.warning(context, 'Digite o nome do produto');
              return;
            }
            
            final price = double.tryParse(
              priceController.text.replaceAll(',', '.').replaceAll('€', '').trim(),
            ) ?? 0.0;
            
            // Gerar um código único para produtos manuais (não será salvo na base de dados)
            final uniqueBarcode = 'MANUAL_${DateTime.now().millisecondsSinceEpoch}';
            
            final newItem = ScannedItem.create(
              barcode: uniqueBarcode,
              name: nameController.text.trim(),
              price: price,
              quantity: quantity,
            );
            
            Navigator.pop(context);
            widget.onSave(newItem);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Adicionar à Lista'),
        ),
      ],
    );
  }
}
