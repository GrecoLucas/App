import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      if (kDebugMode) {
        print('Imagem selecionada: ${pickedFile.path}');
      }
      return File(pickedFile.path);
    }
    return null;
  }

  Future<String?> saveImage(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Criar um nome único para a imagem
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'favorite_item_$timestamp$extension';
      final newPath = path.join(directory.path, fileName);

      if (kDebugMode) {
        print('Salvando imagem de ${imageFile.path} para $newPath');
      }

      // Copia o arquivo para o novo local
      final savedImage = await imageFile.copy(newPath);
      
      // Verificar se o arquivo foi realmente salvo
      if (await savedImage.exists()) {
        if (kDebugMode) {
          print('Imagem salva com sucesso em: ${savedImage.path}');
        }
        return savedImage.path;
      } else {
        if (kDebugMode) {
          print('Erro: Arquivo não foi salvo corretamente');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar a imagem: $e');
      }
      return null;
    }
  }
}
