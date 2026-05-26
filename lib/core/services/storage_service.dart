import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageService {
  /// Salva um arquivo localmente no diretório de documentos do aplicativo.
  /// Retorna o caminho absoluto do arquivo salvo.
  Future<String> salvarArquivoLocal(String atendimentoId, File file) async {
    try {
      // Obtém o diretório de documentos do aplicativo
      final directory = await getApplicationDocumentsDirectory();
      
      // Cria a pasta de mídias se não existir
      final mediaPath = Directory(p.join(directory.path, 'midias', atendimentoId));
      if (!await mediaPath.exists()) {
        await mediaPath.create(recursive: true);
      }

      // Define o nome do arquivo (preservando a extensão original ou usando .jpg)
      final extension = p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
      final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}$extension';
      final targetFile = File(p.join(mediaPath.path, fileName));

      // Copia o arquivo para o destino local
      await file.copy(targetFile.path);

      return targetFile.path;
    } catch (e) {
      throw Exception('Erro ao salvar arquivo localmente: $e');
    }
  }
}
