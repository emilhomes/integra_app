import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agendamento_model.dart';

class AgendamentoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'agendamentos';

  Future<void> salvar(AgendamentoModel agendamento) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(agendamento.id)
          .set(agendamento.toMap());
    } catch (e) {
      throw Exception('Erro ao salvar agendamento: $e');
    }
  }

  Future<List<AgendamentoModel>> buscarPorDia(String profissionalId, DateTime dia) async {
    try {
      final inicioDia = DateTime(dia.year, dia.month, dia.day);
      final fimDia = DateTime(dia.year, dia.month, dia.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('profissionalId', isEqualTo: profissionalId)
          .where('dataHora', isGreaterThanOrEqualTo: inicioDia)
          .where('dataHora', isLessThanOrEqualTo: fimDia)
          .orderBy('dataHora')
          .get();

      return querySnapshot.docs
          .map((doc) => AgendamentoModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar agendamentos do dia: $e');
    }
  }

  Future<List<AgendamentoModel>> buscarHoje(String profissionalId) async {
    return buscarPorDia(profissionalId, DateTime.now());
  }

  Future<List<AgendamentoModel>> buscarPendentesHoje(String profissionalId) async {
    try {
      final agendamentos = await buscarHoje(profissionalId);
      return agendamentos.where((a) => a.status == AgendamentoStatus.agendado).toList();
    } catch (e) {
      throw Exception('Erro ao buscar agendamentos pendentes de hoje: $e');
    }
  }

  Future<void> atualizarStatus(String id, String status) async {
    try {
      await _firestore.collection(_collection).doc(id).update({'status': status});
    } catch (e) {
      throw Exception('Erro ao atualizar status do agendamento: $e');
    }
  }

  Future<void> excluir(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao excluir agendamento: $e');
    }
  }

  Future<AgendamentoModel?> buscarPorId(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return AgendamentoModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar agendamento: $e');
    }
  }
}
