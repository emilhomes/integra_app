import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/gps_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../data/models/atendimento_model.dart';
import '../../../data/repositories/atendimento_repository.dart';

// Estados
abstract class AtendimentoState {}

class AtendimentoInicial extends AtendimentoState {}

class AtendimentoSalvando extends AtendimentoState {}

class AtendimentoSalvo extends AtendimentoState {}

class AtendimentoErro extends AtendimentoState {
  final String mensagem;
  AtendimentoErro(this.mensagem);
}

// Eventos
abstract class AtendimentoEvent {}

class AtendimentoSalvarSolicitado extends AtendimentoEvent {
  final AtendimentoModel atendimento;
  final File? foto;

  AtendimentoSalvarSolicitado({
    required this.atendimento,
    this.foto,
  });
}

// BLoC
class AtendimentoBloc extends Bloc<AtendimentoEvent, AtendimentoState> {
  final AtendimentoRepository _repository;
  final GpsService _gpsService;
  final StorageService _storageService;

  AtendimentoBloc(this._repository, this._gpsService, this._storageService)
      : super(AtendimentoInicial()) {
    on<AtendimentoSalvarSolicitado>((event, emit) async {
      emit(AtendimentoSalvando());
      try {
        // 1. Capturar GPS
        final posicao = await _gpsService.capturarLocalizacao();
        
        // 2. Salvar foto localmente (se houver)
        if (event.foto != null) {
          await _storageService.salvarArquivoLocal(
            event.atendimento.id,
            event.foto!,
          );
        }

        // 3. Salvar no Firestore
        final atendimentoFinal = AtendimentoModel(
          id: event.atendimento.id,
          pacienteId: event.atendimento.pacienteId,
          profissionalId: event.atendimento.profissionalId,
          data: event.atendimento.data,
          terapias: event.atendimento.terapias,
          observacoes: event.atendimento.observacoes,
          latitude: posicao?.latitude,
          longitude: posicao?.longitude,
        );

        await _repository.salvar(
          atendimentoFinal,
          latitude: posicao?.latitude,
          longitude: posicao?.longitude,
        );
        
        emit(AtendimentoSalvo());
      } catch (e) {
        emit(AtendimentoErro('Erro ao salvar atendimento: $e'));
      }
    });
  }
}
