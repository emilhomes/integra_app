import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/atendimento_model.dart';

class AtendimentoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'atendimentos';

  Future<void> salvar(AtendimentoModel atendimento) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(atendimento.id)
          .set(atendimento.toMap());
    } catch (e) {
      throw Exception('Erro ao salvar atendimento: $e');
    }
  }

  Future<List<AtendimentoModel>> buscarAtendimentosHoje(String idProfissional) async {
    try {
      final agora = DateTime.now();
      final inicioDia = DateTime(agora.year, agora.month, agora.day);
      final fimDia = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('profissionalId', isEqualTo: idProfissional)
          .where('data', isGreaterThanOrEqualTo: inicioDia)
          .where('data', isLessThanOrEqualTo: fimDia)
          .get();

      return querySnapshot.docs
          .map((doc) => AtendimentoModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar atendimentos de hoje: $e');
    }
  }

  Future<List<AtendimentoModel>> buscarPorPaciente(String idPaciente) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('pacienteId', isEqualTo: idPaciente)
          .orderBy('data', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AtendimentoModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar históricos do paciente: $e');
    }
  }

  Future<List<AtendimentoModel>> buscarPorProfissional(String idProfissional) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('profissionalId', isEqualTo: idProfissional)
          .orderBy('data', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AtendimentoModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar atendimentos do profissional: $e');
    }
  }
}
