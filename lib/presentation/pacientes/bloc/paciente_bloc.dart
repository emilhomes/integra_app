import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/paciente_model.dart';
import '../../../data/repositories/paciente_repository.dart';

// Estados
abstract class PacienteState {}

class PacienteInicial extends PacienteState {}

class PacienteCarregando extends PacienteState {}

class PacienteCarregado extends PacienteState {
  final List<PacienteModel> pacientes;
  PacienteCarregado(this.pacientes);
}

class PacienteSucesso extends PacienteState {}

class PacienteErro extends PacienteState {
  final String mensagem;
  PacienteErro(this.mensagem);
}

// Eventos
abstract class PacienteEvent {}

class PacienteCarregamentoSolicitado extends PacienteEvent {}

class PacienteSalvarSolicitado extends PacienteEvent {
  final PacienteModel paciente;
  PacienteSalvarSolicitado(this.paciente);
}

class PacienteBuscaSolicitada extends PacienteEvent {
  final String query;
  PacienteBuscaSolicitada(this.query);
}

// BLoC
class PacienteBloc extends Bloc<PacienteEvent, PacienteState> {
  final PacienteRepository _repository;
  List<PacienteModel> _todosPacientes = [];

  PacienteBloc(this._repository) : super(PacienteInicial()) {
    on<PacienteCarregamentoSolicitado>((event, emit) async {
      emit(PacienteCarregando());
      try {
        _todosPacientes = await _repository.buscarTodos();
        emit(PacienteCarregado(_todosPacientes));
      } catch (e) {
        emit(PacienteErro('Erro ao carregar pacientes: $e'));
      }
    });

    on<PacienteSalvarSolicitado>((event, emit) async {
      emit(PacienteCarregando());
      try {
        await _repository.salvar(event.paciente);
        emit(PacienteSucesso());
      } catch (e) {
        emit(PacienteErro('Erro ao salvar paciente: $e'));
      }
    });

    on<PacienteBuscaSolicitada>((event, emit) {
      if (_todosPacientes.isEmpty) return;
      
      final filtrados = _todosPacientes.where((p) {
        return p.nome.toLowerCase().contains(event.query.toLowerCase());
      }).toList();
      
      emit(PacienteCarregado(filtrados));
    });
  }
}
