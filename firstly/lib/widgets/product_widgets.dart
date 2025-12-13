import 'package:flutter/material.dart';
import '../models/item.dart';
import '../utils/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Item item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(AppConstants.getResponsivePadding(context, AppConstants.paddingLarge)),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: isSmallScreen ? 50 : 60,
                    height: isSmallScreen ? 50 : 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${item.quantity}x',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                        Icon(
                          Icons.shopping_basket,
                          color: Colors.white.withOpacity(0.8),
                          size: isSmallScreen ? 14 : 16,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppConstants.getResponsivePadding(context, AppConstants.paddingLarge)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppStyles.bodyLarge.copyWith(
                            color: AppTheme.darkGreen,
                            fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.bodyLarge.fontSize!),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Informações de preço em layout responsivo
                        isSmallScreen
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Valor total (maior)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.euro,
                                        size: AppConstants.iconSmall,
                                        color: AppTheme.primaryGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(item.price * item.quantity).toStringAsFixed(2)}',
                                        style: AppStyles.priceStyle.copyWith(
                                          fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.priceStyle.fontSize!),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Valor unitário (menor)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightGreen,
                                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                                    ),
                                    child: Text(
                                      '€${item.price.toStringAsFixed(2)} cada',
                                      style: AppStyles.captionGrey.copyWith(
                                        color: AppTheme.darkGreen,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  // Valor total (maior)
                                  Icon(
                                    Icons.euro,
                                    size: AppConstants.iconSmall,
                                    color: AppTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(item.price * item.quantity).toStringAsFixed(2)}',
                                    style: AppStyles.priceStyle.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: AppConstants.paddingMedium),
                                  // Valor unitário (menor)
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
                                      '€${item.price.toStringAsFixed(2)} cada',
                                      style: AppStyles.captionGrey.copyWith(
                                        color: AppTheme.darkGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                  // Botões de ação responsivos
                  isSmallScreen
                      ? Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: AppTheme.accentBlue,
                                  size: AppConstants.iconSmall,
                                ),
                                onPressed: onEdit,
                                tooltip: 'Editar',
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: const EdgeInsets.all(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.warningRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.warningRed,
                                  size: AppConstants.iconSmall,
                                ),
                                onPressed: onDelete,
                                tooltip: 'Remover',
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: const EdgeInsets.all(4),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: AppTheme.accentBlue,
                                  size: AppConstants.iconSmall,
                                ),
                                onPressed: onEdit,
                                tooltip: 'Editar produto',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.warningRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.warningRed,
                                  size: AppConstants.iconSmall,
                                ),
                                onPressed: onDelete,
                                tooltip: 'Remover',
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    productName = widget.initialName ?? '';
    productPrice = widget.initialPrice?.toStringAsFixed(2) ?? '';
    selectedQuantity = widget.initialQuantity ?? 1;
    nameController = TextEditingController(text: productName);
    priceController = TextEditingController(text: productPrice);
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
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
            TextField(
              controller: nameController,
              onChanged: (value) => productName = value,
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
            TextField(
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
                prefixText: '€ ',
                hintText: '0,00',
                hintStyle: TextStyle(
                  fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontSmall),
                ),
                prefixIcon: Icon(
                  Icons.euro,
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
            ),
            SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingLarge)),
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
                    horizontal: AppConstants.getResponsivePadding(context, AppConstants.paddingLarge),
                    vertical: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                  ),
                  prefixIcon: Icon(
                    Icons.format_list_numbered,
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
          onPressed: () {
            if (productName.trim().isNotEmpty) {
              double price = 0.0;
              
              // Se o preço foi fornecido, tenta fazer o parse
              if (productPrice.trim().isNotEmpty) {
                final parsedPrice = double.tryParse(
                  productPrice.replaceAll(',', '.').replaceAll('€', '').trim(),
                );
                if (parsedPrice != null && parsedPrice >= 0) {
                  price = parsedPrice;
                } else {
                  return;
                }
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
