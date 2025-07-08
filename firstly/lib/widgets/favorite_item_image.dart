import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class FavoriteItemImage extends StatelessWidget {
  final String? imagePath;
  final double width;
  final double height;
  final double borderRadius;

  const FavoriteItemImage({
    super.key,
    this.imagePath,
    this.width = 48,
    this.height = 48,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildImageWidget(),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Se não há caminho de imagem, mostra o ícone padrão
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildDefaultIcon();
    }

    final imageFile = File(imagePath!);

    return FutureBuilder<bool>(
      future: imageFile.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Enquanto verifica se o arquivo existe, mostra um loading
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          // Arquivo existe, tenta carregar a imagem
          return Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Erro ao carregar imagem: $error');
              return _buildDefaultIcon();
            },
          );
        } else {
          // Arquivo não existe, mostra ícone padrão
          print('Arquivo de imagem não encontrado: $imagePath');
          return _buildDefaultIcon();
        }
      },
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.shopping_basket,
        color: Colors.white,
        size: width * 0.5, // Tamanho do ícone proporcional ao container
      ),
    );
  }
}
