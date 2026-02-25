import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CyclicQuantitySelector extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final double height;
  final bool isSmallScreen;

  final Color? backgroundColor;
  final BoxBorder? border;

  const CyclicQuantitySelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
    this.height = 48,
    this.isSmallScreen = false,
    this.backgroundColor,
    this.border,
  });

  void _decrement() {
    if (value > min) {
      onChanged(value - 1);
    } else {
      onChanged(max); // Ciclo para o máximo
    }
  }

  void _increment() {
    if (value < max) {
      onChanged(value + 1);
    } else {
      onChanged(min); // Ciclo para o mínimo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.softGrey,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: border ?? Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão Menos
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppConstants.radiusMedium)),
              onTap: _decrement,
              child: Container(
                width: isSmallScreen ? 36 : 48,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove,
                  size: isSmallScreen ? 18 : 22,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          
          // Valor Central
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
                maxLines: 1,
              ),
            ),
          ),
          
          // Botão Mais
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(AppConstants.radiusMedium)),
              onTap: _increment,
              child: Container(
                width: isSmallScreen ? 36 : 48,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  size: isSmallScreen ? 18 : 22,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
