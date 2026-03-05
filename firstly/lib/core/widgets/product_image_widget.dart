import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../providers/app_settings_provider.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final IconData fallbackIcon;

  const ProductImageWidget({
    Key? key,
    this.imageUrl,
    this.width = 56,
    this.height = 56,
    this.borderRadius = 8,
    this.fallbackIcon = Icons.shopping_bag_outlined,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsProvider>(
      builder: (context, settingsProvider, child) {
        if (!settingsProvider.showProductImages) {
          return const SizedBox.shrink(); // Hide completely when disabled
        }
        
        if (imageUrl == null || imageUrl!.isEmpty) {
          return _buildFallback();
        }

        final isNetwork = imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://');

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: isNetwork 
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: width,
                height: height,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: width,
                  height: height,
                  color: AppTheme.softGrey,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildFallback(),
              )
            : Image.file(
                File(imageUrl!),
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              ),
        );
      },
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        fallbackIcon,
        color: AppTheme.primaryGreen,
        size: width * 0.5,
      ),
    );
  }
}
