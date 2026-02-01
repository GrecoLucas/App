import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/favorite_item.dart';
import '../services/favorite_items_service.dart';
import '../services/snackbar_service.dart';
import '../utils/app_theme.dart';

class EnhancedProductCard extends StatefulWidget {
  final Item item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EnhancedProductCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.onToggle,
  });

  final VoidCallback? onToggle;

  @override
  State<EnhancedProductCard> createState() => _EnhancedProductCardState();
}

class _EnhancedProductCardState extends State<EnhancedProductCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  void _checkIfFavorite() async {
    final isFav = await FavoriteItemsService.isFavorite(widget.item.name);
    setState(() => _isFavorite = isFav);
  }

  void _toggleFavorite() async {
    if (_isFavorite) {
      // Remover dos favoritos
      final items = await FavoriteItemsService.loadFavoriteItems();
      final item = items.firstWhere(
        (item) => item.name.toLowerCase() == widget.item.name.toLowerCase(),
        orElse: () => FavoriteItem(name: ''),
      );
      
      if (item.name.isNotEmpty) {
        await FavoriteItemsService.removeFavoriteItem(item.id);
        setState(() => _isFavorite = false);
        SnackBarService.warning(context, '${widget.item.name} removido dos favoritos');
      }
    } else {
      // Adicionar aos favoritos
      final favoriteItem = FavoriteItemsService.createFavoriteFromItem(
        widget.item.name,
        widget.item.price,
        widget.item.quantity,
      );
      
      await FavoriteItemsService.addFavoriteItem(favoriteItem);
      setState(() => _isFavorite = true);
      SnackBarService.success(context, '${widget.item.name} adicionado aos favoritos');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.getResponsivePadding(context, AppConstants.paddingSmall)), // Reduced margin
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: const [AppStyles.softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: widget.item.isCompleted ? 0.6 : 1.0,
          child: Padding(
            padding: EdgeInsets.all(AppConstants.getResponsivePadding(context, AppConstants.paddingSmall)), // Reduced padding
            child: Column(
              children: [
                Row(
                  children: [
                    // Checkbox para indicar se está no carrinho
                    Transform.scale(
                      scale: isSmallScreen ? 1.0 : 1.1, // Slightly reduced scale
                      child: Checkbox(
                        value: widget.item.isCompleted,
                        onChanged: (bool? value) {
                          if (widget.onToggle != null) {
                            widget.onToggle!();
                          }
                        },
                        activeColor: AppTheme.primaryGreen,
                        checkColor: Colors.white,
                        side: BorderSide(
                          color: AppTheme.primaryGreen.withOpacity(0.6),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  SizedBox(width: AppConstants.getResponsivePadding(context, 4)), // Reduced gap
                  Container(
                    width: isSmallScreen ? 36 : 44, // Reduced size
                    height: isSmallScreen ? 36 : 44, // Reduced size
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.item.quantity}x',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 11 : 13, // Reduced font
                          ),
                        ),
                        Icon(
                          Icons.shopping_basket,
                          color: Colors.white.withOpacity(0.8),
                          size: isSmallScreen ? 12 : 14, // Reduced icon
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium)), // Reduced gap
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: AppStyles.bodyLarge.copyWith(
                            color: AppTheme.darkGreen,
                            fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.bodyLarge.fontSize!),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Informações de preço em layout responsivo
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppConstants.getResponsivePadding(context, AppConstants.paddingMedium),
                          runSpacing: 2,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.euro,
                                  size: AppConstants.iconSmall,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(widget.item.price * widget.item.quantity).toStringAsFixed(2)}',
                                  style: AppStyles.priceStyle.copyWith(
                                    fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.priceStyle.fontSize!),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.item.quantity > 1)
                              Text(
                                '(€${widget.item.price.toStringAsFixed(2)} cada)',
                                style: AppStyles.captionGrey.copyWith(
                                  fontSize: AppConstants.getResponsiveFontSize(context, AppStyles.captionGrey.fontSize!),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu dropdown com as ações
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'favorite':
                          _toggleFavorite();
                          break;
                        case 'edit':
                          widget.onEdit();
                          break;
                        case 'delete':
                          widget.onDelete();
                          break;
                      }
                    },
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.darkGreen,
                      size: isSmallScreen ? AppConstants.iconSmall : AppConstants.iconMedium,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(_isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: AppTheme.accentBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: AppTheme.warningRed,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Text('Remover'),
                          ],
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
      ),
    );
  }
}
