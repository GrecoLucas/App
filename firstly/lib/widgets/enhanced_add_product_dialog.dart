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
  String productName = '';
  String productPrice = '';
  int selectedQuantity = 1;
  bool _isFavorite = false;
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    productName = widget.initialName ?? '';
    productPrice = widget.initialPrice?.toStringAsFixed(2) ?? '';
    selectedQuantity = widget.initialQuantity ?? 1;
    nameController = TextEditingController(text: productName);
    priceController = TextEditingController(text: productPrice);
    
    if (productName.isNotEmpty) {
      _checkIfFavorite();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
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
    final isSmallScreen = screenWidth < 400;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      contentPadding: EdgeInsets.all(AppConstants.getResponsivePadding(context, AppConstants.paddingLarge)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Icon(
              widget.isEditing ? Icons.edit : Icons.add_shopping_cart,
              color: Colors.white,
              size: isSmallScreen ? AppConstants.iconSmall : AppConstants.iconMedium,
            ),
          ),
          SizedBox(width: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),
          Flexible(
            child: Text(
              widget.isEditing ? 'Editar Produto' : 'Adicionar Produto',
              style: AppStyles.headingMedium.copyWith(
                fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.headingMedium.fontSize!),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
                  fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                hintText: 'Ex: Pão, Leite, Ovos...',
                hintStyle: TextStyle(
                  fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontSmall),
                ),
                prefixIcon: Icon(
                  Icons.shopping_basket,
                  size: isSmallScreen ? AppConstants.iconSmall : AppConstants.iconMedium,
                ),
                filled: true,
                fillColor: AppTheme.softGrey,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                  vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                ),
              ),
              style: TextStyle(
                fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium),
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
                    labelText: 'Preço (opcional)',
                    labelStyle: TextStyle(
                      fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    prefixText: '${settingsProvider.primaryCurrency.symbol} ',
                    hintText: '0,00',
                    hintStyle: TextStyle(
                      fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontSmall),
                    ),
                    prefixIcon: Icon(
                      Icons.attach_money,
                      size: isSmallScreen ? AppConstants.iconSmall : AppConstants.iconMedium,
                    ),
                    filled: true,
                    fillColor: AppTheme.softGrey,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                      vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                );
              },
            ),
            SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingLarge)),
            
            // Campo quantidade
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
                    fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                  ),
                  prefixIcon: Icon(
                    Icons.numbers,
                    size: isSmallScreen ? AppConstants.iconSmall : AppConstants.iconMedium,
                  ),
                ),
                dropdownColor: Colors.white,
                style: TextStyle(
                  fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium),
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
        ),
      ),
      actions: [
        IconButton(
          onPressed: _toggleFavorite,
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.grey,
            size: isSmallScreen ? 20 : 24,
          ),
          tooltip: _isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
          style: IconButton.styleFrom(
            backgroundColor: _isFavorite ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(
              fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 4 : 8),
        ElevatedButton(
          onPressed: () async {
            if (productName.trim().isNotEmpty) {
              double price = 0.0;
              
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
              

              
              // Se está editando e é favorito, incrementar uso
              if (!widget.isEditing && _isFavorite) {
                await FavoriteItemsService.incrementItemUsage(productName.trim());
              }
              
              Navigator.pop(context, {
                'name': productName.trim(),
                'price': price,
                'quantity': selectedQuantity,
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
