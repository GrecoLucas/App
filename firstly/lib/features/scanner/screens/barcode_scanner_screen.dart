import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../pantry/models/pantry_item.dart';
import '../models/scanned_item.dart';
import '../services/barcode_service.dart';
import '../../pantry/services/pantry_service.dart';
import '../../../core/services/product_api_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_settings_provider.dart';
import '../../../core/widgets/cyclic_quantity_selector.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Function(ScannedItem)? onItemScanned;

  const BarcodeScannerScreen({
    super.key,
    this.onItemScanned,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> with WidgetsBindingObserver {
  late MobileScannerController cameraController;
  bool isScanning = true;
  bool isProcessing = false;
  String? lastScannedBarcode;
  DateTime? lastScanTime;
  static const scanCooldown = Duration(milliseconds: 1000); // Cooldown apenas para o MESMO código

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        if (isScanning && !isProcessing) {
          cameraController.start();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        cameraController.stop();
        break;
        case AppLifecycleState.hidden:
        // TODO: Handle this case.
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    // 1. Verificações síncronas rápidas
    if (!isScanning || isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final barcode = barcodes.first;
    final scannedBarcode = barcode.rawValue; // Restore variable name used below
    if (scannedBarcode == null) return;

    // Check cooldown for SAME barcode
    if (lastScannedBarcode == scannedBarcode && 
        lastScanTime != null && 
        DateTime.now().difference(lastScanTime!) < scanCooldown) {
      return;
    }
    
    // 2. Bloqueio síncrono para evitar condições de corrida
    isProcessing = true;
    lastScanTime = DateTime.now();
    lastScannedBarcode = scannedBarcode;

    // 3. Feedback visual
    if (mounted) {
      setState(() => isScanning = false); 
    }
    
    print('Código escaneado: $scannedBarcode');
    
    try {
      // Primeiro verificar se já existe no banco local
      final existingItem = await BarcodeService.findItemByBarcode(scannedBarcode);
      
      if (!mounted) return;

      if (existingItem != null) {
        // Se temos um callback de escaneamento, usamos o modo de escaneamento contínuo
        if (widget.onItemScanned != null) {
          widget.onItemScanned!(existingItem);
          
          // Feedback visual
          if (mounted) {
            final formattedPrice = await context.read<AppSettingsProvider>().formatPriceWithConversion(existingItem.price);
            if (mounted) {
              SnackBarService.success(context, '${existingItem.name} adicionado, preço: $formattedPrice');
            }
          }

          // Reativar imediatamente para o próximo item
          if (mounted) {
            setState(() {
              isScanning = true;
              isProcessing = false;
            });
          }
          return;
        }

        // Produto encontrado no banco local - mostrar dialog de confirmação/edição (comportamento antigo)
        await _showExistingItemDialog(existingItem);
        return;
      }
      
      // Não existe no banco local - tentar buscar nas APIs
      print('Buscando produto nas APIs...');
      final productInfo = await ProductApiService.getProductInfo(scannedBarcode);
      
      if (!mounted) return;

      String? suggestedName = productInfo?.name;
      if (suggestedName != null) {
        final lowerName = suggestedName.toLowerCase();
        if (lowerName.contains('unknown') || 
            lowerName.contains('produto desconhecido') ||
            lowerName.trim().isEmpty) {
          suggestedName = null;
        }
      }

      // Produto encontrado na API ou não - mostrar dialog
      await _showNewItemDialog(scannedBarcode, suggestedName: suggestedName);
      
    } catch (e) {
      print('Erro ao processar código de barras: $e');
      if (mounted) {
        await _showNewItemDialog(scannedBarcode);
      }
    } finally {
      // Garantir que o estado seja resetado se não foi tratado nos fluxos acima
      // (Os dialogs já tratam o reset, mas em caso de erro não tratado)
      if (mounted && isProcessing && isScanning == false) {
         // Se ainda estiver "processando" mas o fluxo terminou sem abrir dialog
         // (Isso não deve acontecer com a lógica atual, mas é um fail-safe)
      }
    }
  }

  Future<void> _showExistingItemDialog(ScannedItem item) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ItemFoundDialog(
        item: item,
        onConfirm: (updatedItem) async {
          print('Confirmando item existente: ${updatedItem.name}');
          // Salva o item atualizado no banco local
          await BarcodeService.saveScannedItemToDatabase(updatedItem);
          // Fecha o dialog
          if (mounted) Navigator.of(context).pop();
          // Retorna o item e fecha o scanner
          if (mounted) Navigator.of(context).pop(updatedItem);
        },
        onCancel: () {
          Navigator.of(context).pop();
          if (mounted) {
            setState(() {
              isScanning = true;
              isProcessing = false;
            });
          }
        },
      ),
    );
  }

  Future<void> _showNewItemDialog(String barcode, {String? suggestedName}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NewItemDialog(
        barcode: barcode,
        suggestedName: suggestedName,
        onSave: (newItem) async {
          print('Salvando novo item: ${newItem.name}');
          // Salva o novo item no banco local
          await BarcodeService.saveScannedItemToDatabase(newItem);
          
          // Fecha o dialog
          if (mounted) Navigator.of(context).pop();

          if (widget.onItemScanned != null) {
            // Modo contínuo
            widget.onItemScanned!(newItem);
            
            if (mounted) {
              final formattedPrice = await context.read<AppSettingsProvider>().formatPriceWithConversion(newItem.price);
              if (mounted) {
                SnackBarService.success(context, '${newItem.name} adicionado, preço: $formattedPrice');
              }
              
              setState(() {
                isScanning = true;
                isProcessing = false;
              });
            }
          } else {
            // Modo único (fecha o scanner)
            if (mounted) Navigator.of(context).pop(newItem);
          }
        },
        onCancel: () {
          Navigator.of(context).pop();
          if (mounted) {
            setState(() {
              isScanning = true;
              isProcessing = false;
            });
          }
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
  PantryItem? _pantryMatch;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.name);
    priceController = TextEditingController(
        text: widget.item.price > 0
            ? widget.item.price.toStringAsFixed(2)
            : '');
    quantity = widget.item.quantity;
    _checkPantry();
  }

  void _checkPantry() async {
    final name = nameController.text.trim();
    if (name.isNotEmpty) {
      final match = await PantryService.findItemByName(name);
      if (mounted) {
        setState(() => _pantryMatch = match);
      }
    } else {
      if (mounted) {
        setState(() => _pantryMatch = null);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
          boxShadow: [AppStyles.mediumShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusXLarge),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Editar Produto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Código: ${widget.item.barcode}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      onChanged: (value) => _checkPantry(),
                      decoration: InputDecoration(
                        labelText: 'Nome do Produto',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        filled: true,
                        fillColor: AppTheme.softGrey,
                      ),
                      style: AppStyles.bodyLarge,
                    ),

                    // Pantry Status
                    if (nameController.text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 8, left: 4, bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: _pantryMatch == null
                                  ? Colors.grey
                                  : _pantryMatch!.quantity > 0
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _pantryMatch == null
                                  ? 'Novo na despensa'
                                  : '${_pantryMatch!.quantity} unidade(s) na despensa',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _pantryMatch == null
                                    ? Colors.grey
                                    : _pantryMatch!.quantity > 0
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: AppConstants.paddingMedium),

                    const SizedBox(height: AppConstants.paddingSmall),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Alinha ao topo p/ absorver diferenças de padding
                      children: [
                        Expanded(
                          flex: 1, // Reduzido de 3 para 1 para simetria horizontal
                          child: TextField(
                            controller: priceController,
                            decoration: InputDecoration(
                              labelText: 'Preço',
                              prefixIcon: const Icon(Icons.euro),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMedium),
                              ),
                              filled: true,
                              fillColor: AppTheme.softGrey,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: AppStyles.bodyLarge,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                        Expanded(
                          flex: 1, // Ajustado para corresponder ao rácio do Preço (1:1)
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Quantidade',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMedium),
                              ),
                              filled: true,
                              fillColor: AppTheme.softGrey,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 0),
                            ),
                            child: CyclicQuantitySelector(
                              value: quantity,
                              // Height removido para herdar altura nativa do InputDecorator e TextField pai.
                              backgroundColor: Colors.transparent, // Prevê borda dupla 
                              border: Border.all(color: Colors.transparent), 
                              onChanged: (value) {
                                setState(() {
                                  quantity = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final price = double.tryParse(
                          priceController.text
                              .replaceAll(',', '.')
                              .replaceAll('€', '')
                              .trim(),
                        ) ??
                        0.0;

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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    'Atualizar e Adicionar ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewItemDialog extends StatefulWidget {
  final String barcode;
  final String? suggestedName;
  final Function(ScannedItem) onSave;
  final VoidCallback onCancel;

  const _NewItemDialog({
    required this.barcode,
    this.suggestedName,
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
  PantryItem? _pantryMatch;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.suggestedName ?? '');
    priceController = TextEditingController();
    _checkPantry();
  }

  void _checkPantry() async {
    final name = nameController.text.trim();
    if (name.isNotEmpty) {
      final match = await PantryService.findItemByName(name);
      if (mounted) {
        setState(() => _pantryMatch = match);
      }
    } else {
      if (mounted) {
        setState(() => _pantryMatch = null);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
          boxShadow: [AppStyles.mediumShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusXLarge),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: const Icon(Icons.add_shopping_cart,
                        color: Colors.white),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Novo Produto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Código: ${widget.barcode}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      onChanged: (value) => _checkPantry(),
                      decoration: InputDecoration(
                        labelText: 'Nome do Produto',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        filled: true,
                        fillColor: AppTheme.softGrey,
                      ),
                      style: AppStyles.bodyLarge,
                      autofocus: widget.suggestedName ==
                          null, // Focus if name is empty
                    ),

                    // Pantry Status
                    if (nameController.text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 8, left: 4, bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: _pantryMatch == null
                                  ? Colors.grey
                                  : _pantryMatch!.quantity > 0
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _pantryMatch == null
                                  ? 'Novo na despensa'
                                  : '${_pantryMatch!.quantity} unidade(s) na despensa',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _pantryMatch == null
                                    ? Colors.grey
                                    : _pantryMatch!.quantity > 0
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(height: AppConstants.paddingMedium),

                    const SizedBox(height: AppConstants.paddingSmall),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start, // Alinha ao topo p/ absorver diferenças de padding
                      children: [
                        Expanded(
                          flex: 1, // Reduzido de 3 para 1 para simetria horizontal
                          child: TextField(
                            controller: priceController,
                            decoration: InputDecoration(
                              labelText: 'Preço',
                              prefixIcon: const Icon(Icons.euro),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMedium),
                              ),
                              filled: true,
                              fillColor: AppTheme.softGrey,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: AppStyles.bodyLarge,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                        Expanded(
                          flex: 1, // Ajustado para corresponder ao rácio do Preço (1:1)
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Quantidade',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMedium),
                              ),
                              filled: true,
                              fillColor: AppTheme.softGrey,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 0),
                            ),
                            child: CyclicQuantitySelector(
                              value: quantity,
                              // Height removido para herdar altura nativa do InputDecorator e TextField pai.
                              backgroundColor: Colors.transparent, // Prevê borda dupla 
                              border: Border.all(color: Colors.transparent), 
                              onChanged: (value) {
                                setState(() {
                                  quantity = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      SnackBarService.warning(
                          context, 'Digite o nome do produto');
                      return;
                    }

                    final price = double.tryParse(
                          priceController.text
                              .replaceAll(',', '.')
                              .replaceAll('€', '')
                              .trim(),
                        ) ??
                        0.0;

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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    'Salvar e Adicionar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
