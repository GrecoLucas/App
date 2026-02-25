import 'package:flutter/material.dart';
import '../models/list.dart';
import '../../../core/theme/app_theme.dart';


class ShoppingListDialog extends StatefulWidget {
  final ShoppingList? originalList;
  final bool isEditing;
  final List<ShoppingList> existingLists;

  const ShoppingListDialog({
    super.key,
    this.originalList,
    this.isEditing = false,
    this.existingLists = const [],
  });

  @override
  State<ShoppingListDialog> createState() => _ShoppingListDialogState();
}

class _ShoppingListDialogState extends State<ShoppingListDialog> {
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  ShoppingList? _selectedListToCopy;

  @override
  void initState() {
    super.initState();
    String initialName = '';
    String initialBudget = '';
    
    if (widget.isEditing && widget.originalList != null) {
      initialName = widget.originalList!.name;
      initialBudget = widget.originalList!.budget?.toStringAsFixed(2) ?? '';
    } else if (!widget.isEditing && widget.originalList != null) {
      // Copying specific list
      initialName = 'Cópia de ${widget.originalList!.name}';
      _selectedListToCopy = widget.originalList;
    }

    _nameController = TextEditingController(text: initialName);
    _budgetController = TextEditingController(text: initialBudget);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fill the page logic: Use MediaQuery to get height
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        minHeight: screenHeight * 0.5, // At least 50%
        maxHeight: screenHeight * 0.95, // Max 95%
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Allow it to shrink if content is small, but constraints allow growth
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                        ),
                        child: Icon(
                          widget.isEditing ? Icons.edit : (widget.originalList != null ? Icons.copy : Icons.add_shopping_cart),
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Flexible(
                        child: Text(
                          widget.isEditing 
                              ? 'Editar Lista' 
                              : (widget.originalList != null ? 'Copiar Lista' : 'Nova Lista'),
                          style: AppStyles.headingMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome da Lista',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      hintText: 'Ex: Supermercado, Farmácia...',
                      prefixIcon: const Icon(Icons.shopping_basket),
                      filled: true,
                      fillColor: AppTheme.softGrey,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  TextField(
                    controller: _budgetController,
                    decoration: InputDecoration(
                      labelText: 'Orçamento (opcional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      hintText: 'Ex: 50.00',
                      prefixIcon: const Icon(Icons.attach_money),
                      filled: true,
                      fillColor: AppTheme.softGrey,
                      suffixIcon: _budgetController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _budgetController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      setState(() {}); // Rebuild to toggle clear button
                    },
                  ),
                  
                  // Copy from option (only if creating new, not editing, and not already copying specific)
                  if (!widget.isEditing && widget.originalList == null && widget.existingLists.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.paddingMedium),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.softGrey,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: DropdownButtonFormField<ShoppingList?>(
                        value: _selectedListToCopy,
                        decoration: const InputDecoration(
                          labelText: 'Copiar de (opcional)',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingLarge,
                            vertical: AppConstants.paddingMedium,
                          ),
                          prefixIcon: Icon(Icons.copy),
                        ),
                        dropdownColor: Colors.white,
                        items: [
                          const DropdownMenuItem<ShoppingList?>(
                            value: null,
                            child: Text('Lista vazia'),
                          ),
                          ...widget.existingLists.map((list) => DropdownMenuItem<ShoppingList?>(
                            value: list,
                            child: Text(
                              list.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedListToCopy = value;
                          });
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingLarge, 
              0, 
              AppConstants.paddingLarge, 
              AppConstants.paddingLarge
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty) {
                      double? budget;
                      if (_budgetController.text.isNotEmpty) {
                        budget = double.tryParse(_budgetController.text.replaceAll(',', '.'));
                      }
                      
                      Navigator.pop(context, {
                        'name': name,
                        'budget': budget,
                        'copyFrom': _selectedListToCopy,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.isEditing ? 'Salvar' : (widget.originalList != null ? 'Copiar' : 'Criar')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
