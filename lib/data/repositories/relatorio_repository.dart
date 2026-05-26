import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/atendimento_model.dart';

class RelatorioRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionAtendimentos = 'atendimentos';

  /// Busca atendimentos realizados por um estagiário específico em um intervalo de tempo.
  /// Útil para o RF007 (Relatório de Estágio).
  Future<List<AtendimentoModel>> buscarAtendimentosPorEstagiario(
    String idUsuario,
    DateTime inicio,
    DateTime fim,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionAtendimentos)
          .where('profissionalId', isEqualTo: idUsuario)
          .where('data', isGreaterThanOrEqualTo: inicio)
          .where('data', isLessThanOrEqualTo: fim)
          .orderBy('data', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AtendimentoModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erro ao gerar relatório de estágio: $e');
    }
  }
}
