import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../services/pantry_service.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cyclic_quantity_selector.dart';

class EnhancedAddPantryItemDialog extends StatefulWidget {
  final String? initialName;
  final int? initialQuantity;
  final bool isEditing;

  const EnhancedAddPantryItemDialog({
    super.key,
    this.initialName,
    this.initialQuantity,
    this.isEditing = false,
  });

  @override
  State<EnhancedAddPantryItemDialog> createState() => _EnhancedAddPantryItemDialogState();
}

class _EnhancedAddPantryItemDialogState extends State<EnhancedAddPantryItemDialog> {
  late TextEditingController nameController;
  int selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? '');
    selectedQuantity = widget.initialQuantity ?? 1;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    
    // Obtém a altura do teclado para ajustar o padding
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.4, 
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
          // Handle visual
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
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Icon(
                  widget.isEditing ? Icons.edit : Icons.kitchen,
                  color: Colors.white,
                  size: isSmallScreen ? AppConstants.iconMedium : AppConstants.iconLarge,
                ),
              ),
              SizedBox(width: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),
              Flexible(
                child: Text(
                  widget.isEditing ? 'Editar Item' : 'Adicionar à Despensa',
                  style: AppStyles.headingMedium.copyWith(
                    fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.headingMedium.fontSize! * 1.2),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),

          // Content Scrollable
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo nome do produto
                  TextField(
                    controller: nameController,
                    maxLength: 24, 
                    decoration: InputDecoration(
                      labelText: 'Nome do Item',
                      labelStyle: TextStyle(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      hintText: 'Ex: Arroz, Feijão...',
                      hintStyle: TextStyle(
                        fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontSmall * 1.2),
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
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  
                  SizedBox(height: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)),
                  
                  // Campo quantidade normal
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
                          value: selectedQuantity,
                          isSmallScreen: isSmallScreen,
                          onChanged: (value) {
                            setState(() {
                              selectedQuantity = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
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
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: AppConstants.getResponsiveFontSize(context, AppConstants.fontMedium * 1.1),
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 8),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    final newItem = PantryItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.trim(),
                      quantity: selectedQuantity,
                      addedDate: DateTime.now(),
                    );
                    
                    final currentItems = await PantryService.loadPantryItems();
                    final existingIndex = currentItems.indexWhere(
                      (i) => i.name.toLowerCase() == newItem.name.toLowerCase()
                    );
                    
                    if (existingIndex >= 0) {
                      currentItems[existingIndex].quantity += newItem.quantity;
                      await PantryService.savePantryItems(currentItems);
                    } else {
                       await PantryService.savePantryItems([...currentItems, newItem]);
                    }
                    
                    if (mounted) {
                      Navigator.pop(context, true); // true = recarregar itens após salvar
                    }
                  } else {
                      SnackBarService.warning(context, 'O nome do item não pode estar vazio');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange, // Usando cor temática de despensa
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
                  widget.isEditing ? 'Salvar' : 'Adicionar',
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
