import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// Abre a câmera para fotografar um documento.
  /// Retorna o [File] capturado ou null se o usuário cancelar.
  Future<File?> fotografarDocumento() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Comprime levemente a imagem para economizar espaço
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      // Em caso de erro (ex: falta de permissão não tratada pelo plugin)
      return null;
    }
  }
}
