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
import '../../../core/widgets/product_image_widget.dart';

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
      String? suggestedImageUrl = productInfo?.imageUrl;

      // Produto encontrado na API ou não - mostrar dialog
      await _showNewItemDialog(
        scannedBarcode, 
        suggestedName: suggestedName,
        suggestedImageUrl: suggestedImageUrl,
      );
      
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
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _ItemFoundBottomSheet(
        item: item,
        onConfirm: (updatedItem) async {
          print('Confirmando item existente: ${updatedItem.name}');
          // Salva o item atualizado no banco local
          await BarcodeService.saveScannedItemToDatabase(updatedItem);
          
          // Fecha o bottom sheet
          if (mounted) Navigator.of(context).pop();

          if (widget.onItemScanned != null) {
            // Modo contínuo
            widget.onItemScanned!(updatedItem);
            
            if (mounted) {
              final formattedPrice = await context.read<AppSettingsProvider>().formatPriceWithConversion(updatedItem.price);
              if (mounted) {
                SnackBarService.success(context, '${updatedItem.name} adicionado, preço: $formattedPrice');
                Navigator.of(context).pop(); // Auto fecha o scanner e vai para a lista
              }
            }
          } else {
            // Modo único (fecha o scanner)
            if (mounted) Navigator.of(context).pop(updatedItem);
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

  Future<void> _showNewItemDialog(String barcode, {String? suggestedName, String? suggestedImageUrl}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _NewItemBottomSheet(
        barcode: barcode,
        suggestedName: suggestedName,
        suggestedImageUrl: suggestedImageUrl,
        onSave: (newItem) async {
          print('Salvando novo item: ${newItem.name}');
          // Salva o novo item no banco local
          await BarcodeService.saveScannedItemToDatabase(newItem);
          
          // Fecha o bottom sheet
          if (mounted) Navigator.of(context).pop();

          if (widget.onItemScanned != null) {
            // Modo contínuo
            widget.onItemScanned!(newItem);
            
            if (mounted) {
              final formattedPrice = await context.read<AppSettingsProvider>().formatPriceWithConversion(newItem.price);
              if (mounted) {
                SnackBarService.success(context, '${newItem.name} adicionado, preço: $formattedPrice');
                Navigator.of(context).pop(); // Auto fecha o scanner e vai para a lista
              }
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

class _ItemFoundBottomSheet extends StatefulWidget {
  final ScannedItem item;
  final Function(ScannedItem) onConfirm;
  final VoidCallback onCancel;

  const _ItemFoundBottomSheet({
    required this.item,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_ItemFoundBottomSheet> createState() => _ItemFoundBottomSheetState();
}

class _ItemFoundBottomSheetState extends State<_ItemFoundBottomSheet> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController weightController;
  late int quantity;
  bool _isWeightMode = false;
  PantryItem? _pantryMatch;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.name);
    _isWeightMode = widget.item.isWeighed;
    quantity = widget.item.quantity;
    
    // If it was previously weighed, price field shows pricePerKg
    if (_isWeightMode) {
      priceController = TextEditingController(
          text: widget.item.pricePerKg != null && widget.item.pricePerKg! > 0
              ? widget.item.pricePerKg!.toStringAsFixed(2)
              : '');
      weightController = TextEditingController(
          text: widget.item.weight != null
              ? widget.item.weight.toString()
              : '1.0');
    } else {
      priceController = TextEditingController(
          text: widget.item.price > 0
              ? widget.item.price.toStringAsFixed(2)
              : '');
      weightController = TextEditingController(text: '1.0');
    }
    
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
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.5,
        maxHeight: screenHeight * 0.95,
      ),
      padding: EdgeInsets.only(
        bottom: bottomPadding + AppConstants.getResponsivePadding(context, AppConstants.paddingSmall),
        top: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
        left: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
        right: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                ),
              ),
              SizedBox(width: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isWeightMode ? 'Editar Pesagem' : 'Editar Produto',
                      style: AppStyles.headingMedium.copyWith(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.headingMedium.fontSize! * 1.2),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cód: ${widget.item.barcode}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isWeightMode = !_isWeightMode;
                    priceController.clear();
                    if (_isWeightMode) {
                      weightController.text = '1.0';
                    } else {
                      quantity = 1;
                    }
                  });
                },
                icon: Icon(
                  _isWeightMode ? Icons.shopping_cart : Icons.balance,
                  color: Colors.black,
                  size: 28,
                ),
                tooltip: _isWeightMode ? 'Modo normal' : 'Modo por peso',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),

          // Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppConstants.paddingLarge),
                        child: ProductImageWidget(
                          imageUrl: widget.item.imageUrl,
                          width: 120,
                          height: 120,
                          borderRadius: AppConstants.radiusMedium,
                        ),
                      ),
                    ),
                  TextField(
                    controller: nameController,
                    onChanged: (value) => _checkPantry(),
                    decoration: InputDecoration(
                      labelText: 'Nome do Produto',
                      labelStyle: TextStyle(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      prefixIcon: Icon(
                        Icons.shopping_bag_outlined,
                        size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                      ),
                      filled: true,
                      fillColor: AppTheme.softGrey,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                        vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                    ),
                  ),

                  // Pantry Status
                  if (nameController.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4, bottom: 8),
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

                  SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),

                  // Campo Preço
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: _isWeightMode ? 'Preço por Kg (opcional)' : 'Preço (opcional)',
                      labelStyle: TextStyle(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      prefixIcon: Icon(
                        _isWeightMode ? Icons.scale : Icons.euro,
                        size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                        color: _isWeightMode ? Colors.black : null,
                      ),
                      filled: true,
                      fillColor: AppTheme.softGrey,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                        vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),

                  SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),

                  if (_isWeightMode) ...[
                    // Campo Peso
                    TextField(
                      controller: weightController,
                      decoration: InputDecoration(
                        labelText: 'Peso (kg)',
                        labelStyle: TextStyle(
                          fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        prefixIcon: Icon(
                          Icons.fitness_center_outlined,
                          size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                          color: Colors.black,
                        ),
                        suffixText: 'kg',
                        filled: true,
                        fillColor: AppTheme.softGrey,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                          vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ] else ...[
                    // Campo Quantidade
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Quantidade',
                            style: TextStyle(
                              fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: CyclicQuantitySelector(
                            value: quantity,
                            isSmallScreen: isSmallScreen,
                            onChanged: (value) {
                              setState(() {
                                quantity = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.1),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    SnackBarService.warning(context, 'Digite o nome do produto');
                    return;
                  }

                  double price = 0.0;
                  double finalWeight = 1.0;
                  int finalQuantity = 1;
                  double pricePerKg = 0.0;

                  if (priceController.text.trim().isNotEmpty) {
                    final parsedPrice = double.tryParse(
                      priceController.text.replaceAll(',', '.').replaceAll(RegExp(r'[€$R\$\s]'), '').trim(),
                    );
                    if (parsedPrice != null && parsedPrice >= 0) {
                      price = parsedPrice;
                      if (_isWeightMode) pricePerKg = parsedPrice;
                    } else {
                      return;
                    }
                  }

                  if (_isWeightMode) {
                    final weight = double.tryParse(
                      weightController.text.replaceAll(',', '.').trim(),
                    );
                    if (weight != null && weight > 0) {
                      finalWeight = weight;
                      if (price > 0) {
                        price = price * weight; // final price
                      }
                      finalQuantity = 1;
                    } else {
                      SnackBarService.error(context, 'Por favor, insira um peso válido');
                      return;
                    }
                  } else {
                    finalQuantity = quantity;
                  }

                  final updatedItem = ScannedItem.create(
                    barcode: widget.item.barcode,
                    name: nameController.text.trim(),
                    price: price, // final calculated price
                    quantity: finalQuantity,
                    imageUrl: widget.item.imageUrl,
                    isWeighed: _isWeightMode,
                    weight: _isWeightMode ? finalWeight : null,
                    pricePerKg: _isWeightMode ? pricePerKg : null,
                  );

                  widget.onConfirm(updatedItem);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                    vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingSmall),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                ),
                child: Text(
                  'Atualizar e Adicionar',
                  style: TextStyle(
                    fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewItemBottomSheet extends StatefulWidget {
  final String barcode;
  final String? suggestedName;
  final String? suggestedImageUrl;
  final Function(ScannedItem) onSave;
  final VoidCallback onCancel;

  const _NewItemBottomSheet({
    required this.barcode,
    this.suggestedName,
    this.suggestedImageUrl,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_NewItemBottomSheet> createState() => _NewItemBottomSheetState();
}

class _NewItemBottomSheetState extends State<_NewItemBottomSheet> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController weightController;
  int quantity = 1;
  bool _isWeightMode = false;
  PantryItem? _pantryMatch;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.suggestedName ?? '');
    priceController = TextEditingController();
    weightController = TextEditingController(text: '1.0');
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
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.5,
        maxHeight: screenHeight * 0.95,
      ),
      padding: EdgeInsets.only(
        bottom: bottomPadding + AppConstants.getResponsivePadding(context, AppConstants.paddingSmall),
        top: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
        left: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
        right: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Icon(
                  Icons.add_shopping_cart,
                  color: Colors.white,
                  size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                ),
              ),
              SizedBox(width: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isWeightMode ? 'Nova Pesagem' : 'Novo Produto',
                      style: AppStyles.headingMedium.copyWith(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.headingMedium.fontSize! * 1.2),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cód: ${widget.barcode}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isWeightMode = !_isWeightMode;
                    priceController.clear();
                    if (_isWeightMode) {
                      weightController.text = '1.0';
                    } else {
                      quantity = 1;
                    }
                  });
                },
                icon: Icon(
                  _isWeightMode ? Icons.shopping_cart : Icons.balance,
                  color: Colors.black,
                  size: 28,
                ),
                tooltip: _isWeightMode ? 'Modo normal' : 'Modo por peso',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),

          // Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.suggestedImageUrl != null && widget.suggestedImageUrl!.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppConstants.paddingLarge),
                        child: ProductImageWidget(
                          imageUrl: widget.suggestedImageUrl,
                          width: 120,
                          height: 120,
                          borderRadius: AppConstants.radiusMedium,
                        ),
                      ),
                    ),
                  TextField(
                    controller: nameController,
                    onChanged: (value) => _checkPantry(),
                    decoration: InputDecoration(
                      labelText: 'Nome do Produto',
                      labelStyle: TextStyle(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      prefixIcon: Icon(
                        Icons.shopping_bag_outlined,
                        size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                      ),
                      filled: true,
                      fillColor: AppTheme.softGrey,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                        vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                    ),
                    autofocus: widget.suggestedName == null,
                  ),

                  // Pantry Status
                  if (nameController.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4, bottom: 8),
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

                  SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),

                  // Campo Preço
                  TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: _isWeightMode ? 'Preço por Kg (opcional)' : 'Preço (opcional)',
                      labelStyle: TextStyle(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      prefixIcon: Icon(
                        _isWeightMode ? Icons.scale : Icons.euro,
                        size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                        color: _isWeightMode ? Colors.black : null,
                      ),
                      filled: true,
                      fillColor: AppTheme.softGrey,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                        vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),

                  SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),

                  if (_isWeightMode) ...[
                    // Campo Peso
                    TextField(
                      controller: weightController,
                      decoration: InputDecoration(
                        labelText: 'Peso (kg)',
                        labelStyle: TextStyle(
                          fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        prefixIcon: Icon(
                          Icons.fitness_center_outlined,
                          size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                          color: Colors.black,
                        ),
                        suffixText: 'kg',
                        filled: true,
                        fillColor: AppTheme.softGrey,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                          vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ] else ...[
                    // Campo Quantidade
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Quantidade',
                            style: TextStyle(
                              fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: CyclicQuantitySelector(
                            value: quantity,
                            isSmallScreen: isSmallScreen,
                            onChanged: (value) {
                              setState(() {
                                quantity = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.1),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    SnackBarService.warning(context, 'Digite o nome do produto');
                    return;
                  }

                  double price = 0.0;
                  double finalWeight = 1.0;
                  int finalQuantity = 1;
                  double pricePerKg = 0.0;

                  if (priceController.text.trim().isNotEmpty) {
                    final parsedPrice = double.tryParse(
                      priceController.text.replaceAll(',', '.').replaceAll(RegExp(r'[€$R\$\s]'), '').trim(),
                    );
                    if (parsedPrice != null && parsedPrice >= 0) {
                      price = parsedPrice;
                      if (_isWeightMode) pricePerKg = parsedPrice;
                    } else {
                      return;
                    }
                  }

                  if (_isWeightMode) {
                    final weight = double.tryParse(
                      weightController.text.replaceAll(',', '.').trim(),
                    );
                    if (weight != null && weight > 0) {
                      finalWeight = weight;
                      if (price > 0) {
                        price = price * weight; // final price
                      }
                      finalQuantity = 1;
                    } else {
                      SnackBarService.error(context, 'Por favor, insira um peso válido');
                      return;
                    }
                  } else {
                    finalQuantity = quantity;
                  }

                  final newItem = ScannedItem.create(
                    barcode: widget.barcode,
                    name: nameController.text.trim(),
                    price: price, // final calculated price
                    quantity: finalQuantity,
                    imageUrl: widget.suggestedImageUrl,
                    isWeighed: _isWeightMode,
                    weight: _isWeightMode ? finalWeight : null,
                    pricePerKg: _isWeightMode ? pricePerKg : null,
                  );

                  widget.onSave(newItem);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                    vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingSmall),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                ),
                child: Text(
                  'Salvar e Adicionar',
                  style: TextStyle(
                    fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
