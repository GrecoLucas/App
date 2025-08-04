import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/favorite_item.dart';
import '../services/favorite_items_service.dart';
import '../services/image_service.dart';
import '../utils/app_theme.dart';
import '../providers/app_settings_provider.dart';

class AddProductDialog extends StatefulWidget {
  final String? initialName;
  final double? initialPrice;
  final int? initialQuantity;
  final bool isEditing;

  const AddProductDialog({
    super.key,
    this.initialName,
    this.initialPrice,
    this.initialQuantity,
    this.isEditing = false,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController weightController; // Novo: para peso/quantidade em kg
  String productName = '';
  String productPrice = '';
  int selectedQuantity = 1;
  bool _isFavorite = false;
  bool _isWeightMode = false; // Novo: controla se está no modo por peso
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    productName = widget.initialName ?? '';
    productPrice = widget.initialPrice?.toStringAsFixed(2) ?? '';
    selectedQuantity = widget.initialQuantity ?? 1;
    nameController = TextEditingController(text: productName);
    priceController = TextEditingController(text: productPrice);
    weightController = TextEditingController(text: '1.0'); // Peso padrão: 1kg
    
    if (productName.isNotEmpty) {
      _checkIfFavorite();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    weightController.dispose();
    super.dispose();
  }

  void _checkIfFavorite() async {
    if (productName.trim().isNotEmpty) {
      final isFav = await FavoriteItemsService.isFavorite(productName.trim());
      setState(() => _isFavorite = isFav);
    }
  }

  Future<void> _pickAndSaveImage() async {
    final String? choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Imagem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              subtitle: const Text('Escolher uma foto existente'),
              onTap: () {
                Navigator.of(context).pop('gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              subtitle: const Text('Tirar uma nova foto'),
              onTap: () {
                Navigator.of(context).pop('camera');
              },
            ),
            ListTile(
              leading: const Icon(Icons.no_photography),
              title: const Text('Sem imagem'),
              subtitle: const Text('Adicionar sem foto'),
              onTap: () {
                Navigator.of(context).pop('no_image');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (choice == null) {
      if (kDebugMode) {
        print('Usuário cancelou a seleção de imagem');
      }
      return;
    }

    if (choice == 'no_image') {
      if (kDebugMode) {
        print('Usuário escolheu adicionar favorito sem imagem');
      }
      _addFavorite(); // Adiciona sem imagem
      return;
    }

    // Converter a escolha para ImageSource
    final ImageSource source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;

    try {
      if (kDebugMode) {
        print('Iniciando seleção de imagem da ${source == ImageSource.camera ? 'câmera' : 'galeria'}');
      }

      final pickedImage = await _imageService.pickImage(source);
      if (pickedImage != null) {
        if (kDebugMode) {
          print('Imagem selecionada: ${pickedImage.path}');
          print('Iniciando processo de salvamento...');
        }

        final savedImagePath = await _imageService.saveImage(pickedImage);
        if (savedImagePath != null) {
          if (kDebugMode) {
            print('Imagem salva com sucesso! Caminho final: $savedImagePath');
            print('Adicionando favorito com imagem...');
          }
          _addFavorite(imagePath: savedImagePath);
        } else {
          if (kDebugMode) {
            print('ERRO: Falha ao salvar imagem! Salvando favorito sem imagem.');
          }
          _addFavorite();
        }
      } else {
        if (kDebugMode) {
          print('ERRO: Nenhuma imagem foi selecionada pelo usuário');
        }
        _addFavorite();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro durante o processo de seleção/salvamento: $e');
      }
      // Adiciona o favorito mesmo se houve erro com a imagem
      _addFavorite();
    }
  }

  void _addFavorite({String? imagePath}) async {
    if (kDebugMode) {
      print('=== CRIANDO FAVORITO ===');
      print('Nome: ${productName.trim()}');
      print('Imagem: ${imagePath ?? "sem imagem"}');
    }

    final price = double.tryParse(
      productPrice.replaceAll(',', '.').replaceAll(RegExp(r'[€$R\$\s]'), '').trim(),
    ) ?? 0.0;
    
    final favoriteItem = FavoriteItem(
      name: productName.trim(),
      defaultPrice: price,
      defaultQuantity: selectedQuantity,
      imagePath: imagePath,
    );
    
    if (kDebugMode) {
      print('Item criado - ID: ${favoriteItem.id}, ImagePath: ${favoriteItem.imagePath}');
    }
    
    await FavoriteItemsService.addFavoriteItem(favoriteItem);
    
    if (kDebugMode) {
      print('Item salvo no serviço!');
    }
    
    if (mounted) {
      setState(() => _isFavorite = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${productName.trim()} adicionado aos favoritos'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  void _toggleFavorite() async {
    if (productName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome do produto primeiro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isFavorite) {
      // Remover dos favoritos
      final items = await FavoriteItemsService.loadFavoriteItems();
      final item = items.firstWhere(
        (item) => item.name.toLowerCase() == productName.trim().toLowerCase(),
        orElse: () => FavoriteItem(name: ''),
      );
      
      if (item.name.isNotEmpty) {
        await FavoriteItemsService.removeFavoriteItem(item.id);
        setState(() => _isFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${productName.trim()} removido dos favoritos'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Adicionar aos favoritos
      await _pickAndSaveImage();
    }
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      contentPadding: EdgeInsets.all(AppConstants.getResponsivePadding(context, AppConstants.paddingLarge * 1.5)),
      // Aumentar o tamanho do dialog
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05, // 5% de margem horizontal
        vertical: screenHeight * 0.1,   // 10% de margem vertical
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Icon(
              widget.isEditing ? Icons.edit : Icons.add_shopping_cart,
              color: Colors.white,
              size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
            ),
          ),
          SizedBox(width: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),
          Flexible(
            child: Text(
              widget.isEditing 
                  ? 'Editar Produto' 
                  : (_isWeightMode ? 'Pesagem' : 'Unidade'),
              style: AppStyles.headingMedium.copyWith(
                fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.headingMedium.fontSize! * 1.2),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Botão para alternar entre modo normal e por peso (só na criação)
          if (!widget.isEditing) ...[
            const Spacer(),
            IconButton(
              onPressed: () {
                setState(() {
                  _isWeightMode = !_isWeightMode;
                  // Limpar campos ao trocar de modo
                  priceController.clear();
                  if (_isWeightMode) {
                    weightController.text = '1.0';
                  } else {
                    selectedQuantity = 1;
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
          ],
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            // Campo nome do produto
            TextField(
              controller: nameController,
              onChanged: (value) {
                productName = value;
                _checkIfFavorite();
              },
              decoration: InputDecoration(
                labelText: 'Nome do Produto',
                labelStyle: TextStyle(
                  fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                hintText: 'Ex: Pão, Leite, Ovos...',
                hintStyle: TextStyle(
                  fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontSmall * 1.2),
                ),
                prefixIcon: Icon(
                  Icons.shopping_basket,
                  size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                ),
                filled: true,
                fillColor: AppTheme.softGrey,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium * 1.2),
                  vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium * 1.2),
                ),
              ),
              style: TextStyle(
                fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
              ),
              autofocus: true,
            ),
            SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingLarge)),
            
            // Campo preço
            Consumer<AppSettingsProvider>(
              builder: (context, settingsProvider, child) {
                return TextField(
                  controller: priceController,
                  onChanged: (value) => productPrice = value,
                  decoration: InputDecoration(
                    labelText: _isWeightMode ? 'Preço por Kg (opcional)' : 'Preço (opcional)',
                    labelStyle: TextStyle(
                      fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    prefixText: '${settingsProvider.primaryCurrency.symbol} ',
                    hintText: _isWeightMode ? '0,00/kg' : '0,00',
                    hintStyle: TextStyle(
                      fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontSmall * 1.2),
                    ),
                    prefixIcon: Icon(
                      _isWeightMode ? Icons.scale : Icons.attach_money,
                      size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                      color: _isWeightMode ? Colors.black : null,
                    ),
                    filled: true,
                    fillColor: AppTheme.softGrey,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium * 1.2),
                      vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium * 1.2),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                );
              },
            ),
            SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingLarge)),
            
            // Campo quantidade/peso
            if (_isWeightMode) ...[
              // Campo de peso em kg
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
                  hintText: 'Ex: 1.5, 0.8, 2.0...',
                  hintStyle: TextStyle(
                    fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontSmall * 1.2),
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
                    horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium * 1.2),
                    vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium * 1.2),
                  ),
                ),
                style: TextStyle(
                  fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ] else ...[
              // Campo quantidade normal
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.softGrey,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: DropdownButtonFormField<int>(
                  value: selectedQuantity,
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    labelStyle: TextStyle(
                      fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium * 1.2),
                    ),
                    prefixIcon: Icon(
                      Icons.numbers,
                      size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                    color: Colors.black87,
                  ),
                  items: List.generate(20, (index) => index + 1)
                      .map((quantity) => DropdownMenuItem<int>(
                            value: quantity,
                            child: Text('$quantity'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedQuantity = value ?? 1;
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Botão de favoritos (não aparece no modo peso)
        if (!_isWeightMode) ...[
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.grey,
              size: isSmallScreen ? 24 : 28,
            ),
            tooltip: _isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
            style: IconButton.styleFrom(
              backgroundColor: _isFavorite ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            ),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(
              fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.1),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 4 : 8),
        ElevatedButton(
          onPressed: () async {
            if (productName.trim().isNotEmpty) {
              double price = 0.0;
              double finalWeight = 1.0;
              int finalQuantity = 1;
              
              // Se o preço foi fornecido, tenta fazer o parse
              if (productPrice.trim().isNotEmpty) {
                final parsedPrice = double.tryParse(
                  productPrice.replaceAll(',', '.').replaceAll(RegExp(r'[€$R\$\s]'), '').trim(),
                );
                if (parsedPrice != null && parsedPrice >= 0) {
                  price = parsedPrice;
                } else {
                  return;
                }
              }
              
              if (_isWeightMode) {
                // Modo por peso: calcular preço final baseado no peso
                final weight = double.tryParse(
                  weightController.text.replaceAll(',', '.').trim(),
                );
                if (weight != null && weight > 0) {
                  finalWeight = weight;
                  // Se há preço por kg, calcular o preço total
                  if (price > 0) {
                    price = price * weight; // preço final = preço/kg * peso
                  }
                  finalQuantity = 1; // Sempre 1 no modo peso
                } else {
                  // Peso inválido
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Por favor, insira um peso válido'),
                      backgroundColor: AppTheme.warningRed,
                    ),
                  );
                  return;
                }
              } else {
                // Modo normal
                finalQuantity = selectedQuantity;
              }
              
              // Se está editando e é favorito (só no modo normal), incrementar uso
              if (!widget.isEditing && !_isWeightMode && _isFavorite) {
                await FavoriteItemsService.incrementItemUsage(productName.trim());
              }
              
              Navigator.pop(context, {
                'name': productName.trim(),
                'price': price,
                'quantity': finalQuantity,
                'weight': _isWeightMode ? finalWeight : null, // Adicionar info do peso se relevante
                'isWeightBased': _isWeightMode, // Flag para identificar se foi adicionado por peso
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingLarge),
              vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
          ),
          child: Text(
            widget.isEditing ? 'Salvar' : 'Adicionar',
            style: TextStyle(
              fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium),
            ),
          ),
        ),
      ],
    );
  }
}
