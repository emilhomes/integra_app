import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/paciente_model.dart';

class PacienteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'pacientes';

  Future<void> salvar(PacienteModel paciente) async {
    try {
      await _firestore.collection(_collection).doc(paciente.id).set(paciente.toMap());
    } catch (e) {
      throw Exception('Erro ao salvar paciente: $e');
    }
  }

  Future<List<PacienteModel>> buscarTodos() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs
          .map((doc) => PacienteModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar todos os pacientes: $e');
    }
  }

  Future<PacienteModel?> buscarPorId(String id) async {
    try {
      final docSnapshot = await _firestore.collection(_collection).doc(id).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return PacienteModel.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar paciente por ID: $e');
    }
  }

  Future<void> atualizar(PacienteModel paciente) async {
    try {
      await _firestore.collection(_collection).doc(paciente.id).update(paciente.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar paciente: $e');
    }
  }
}
