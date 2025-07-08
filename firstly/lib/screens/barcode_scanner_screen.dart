import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/scanned_item.dart';
import '../services/barcode_service.dart';
import '../utils/app_theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Function(ScannedItem)? onItemScanned;

  const BarcodeScannerScreen({
    super.key,
    this.onItemScanned,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  bool isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!isScanning || isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;
    
    setState(() {
      isScanning = false;
      isProcessing = true;
    });
    
    final scannedBarcode = barcode.rawValue!;
    print('Código escaneado: $scannedBarcode');
    
    try {
      // Buscar produto no banco local
      final existingItem = await BarcodeService.findItemByBarcode(scannedBarcode);
      
      if (existingItem != null) {
        // Produto encontrado - mostrar dialog de confirmação/edição
        _showExistingItemDialog(existingItem);
      } else {
        // Produto não encontrado - mostrar dialog para inserir dados
        _showNewItemDialog(scannedBarcode);
      }
    } catch (e) {
      print('Erro ao processar código de barras: $e');
      setState(() {
        isScanning = true;
        isProcessing = false;
      });
    }
  }

  void _showExistingItemDialog(ScannedItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ItemFoundDialog(
        item: item,
        onConfirm: (updatedItem) async {
          print('Confirmando item existente: ${updatedItem.name}');
          // Salva o item atualizado no banco local
          await BarcodeService.saveScannedItemToDatabase(updatedItem);
          // Fecha o dialog
          Navigator.of(context).pop();
          // Retorna o item e fecha o scanner
          Navigator.of(context).pop(updatedItem);
        },
        onCancel: () {
          Navigator.of(context).pop();
          setState(() {
            isScanning = true;
            isProcessing = false;
          });
        },
      ),
    );
  }

  void _showNewItemDialog(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NewItemDialog(
        barcode: barcode,
        onSave: (newItem) async {
          print('Salvando novo item: ${newItem.name}');
          // Salva o novo item no banco local
          await BarcodeService.saveScannedItemToDatabase(newItem);
          // Fecha o dialog
          Navigator.of(context).pop();
          // Retorna o item e fecha o scanner
          Navigator.of(context).pop(newItem);
        },
        onCancel: () {
          Navigator.of(context).pop();
          setState(() {
            isScanning = true;
            isProcessing = false;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código de Barras'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.white);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
          ),
          // Overlay com instruções
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(AppConstants.paddingXLarge),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              ),
              child: const Text(
                'Aponte a câmera para o código de barras do produto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemFoundDialog extends StatefulWidget {
  final ScannedItem item;
  final Function(ScannedItem) onConfirm;
  final VoidCallback onCancel;

  const _ItemFoundDialog({
    required this.item,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_ItemFoundDialog> createState() => _ItemFoundDialogState();
}

class _ItemFoundDialogState extends State<_ItemFoundDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late int quantity;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.name);
    priceController = TextEditingController(text: widget.item.price.toStringAsFixed(2));
    quantity = widget.item.quantity;
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
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: const Icon(
              Icons.qr_code,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          const Expanded(
            child: Text('Produto Encontrado'),
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
                color: AppTheme.lightGreen,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este produto já foi escaneado antes. Você pode editar as informações.',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppTheme.darkGreen,
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
          onPressed: widget.onCancel,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final price = double.tryParse(
              priceController.text.replaceAll(',', '.').replaceAll('€', '').trim(),
            ) ?? 0.0;
            
            final updatedItem = ScannedItem.create(
              barcode: widget.item.barcode,
              name: nameController.text.trim(),
              price: price,
              quantity: quantity,
            );
            
            widget.onConfirm(updatedItem);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Adicionar à Lista'),
        ),
      ],
    );
  }
}

class _NewItemDialog extends StatefulWidget {
  final String barcode;
  final Function(ScannedItem) onSave;
  final VoidCallback onCancel;

  const _NewItemDialog({
    required this.barcode,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_NewItemDialog> createState() => _NewItemDialogState();
}

class _NewItemDialogState extends State<_NewItemDialog> {
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
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: const Icon(
              Icons.add_shopping_cart,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          const Expanded(
            child: Text('Novo Produto'),
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
                color: AppTheme.softGrey,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Código: ${widget.barcode}',
                      style: AppStyles.captionGrey,
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
          onPressed: widget.onCancel,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Digite o nome do produto')),
              );
              return;
            }
            
            final price = double.tryParse(
              priceController.text.replaceAll(',', '.').replaceAll('€', '').trim(),
            ) ?? 0.0;
            
            final newItem = ScannedItem.create(
              barcode: widget.barcode,
              name: nameController.text.trim(),
              price: price,
              quantity: quantity,
            );
            
            widget.onSave(newItem);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Salvar e Adicionar'),
        ),
      ],
    );
  }
}
