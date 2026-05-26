import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/relatorio_repository.dart';
import '../../../data/repositories/atendimento_repository.dart';

// Estados
abstract class RelatorioState {}

class RelatorioInicial extends RelatorioState {}

class RelatorioCarregando extends RelatorioState {}

class RelatorioCarregado extends RelatorioState {
  final dynamic dados;
  RelatorioCarregado(this.dados);
}

class RelatorioErro extends RelatorioState {
  final String mensagem;
  RelatorioErro(this.mensagem);
}

// Eventos
abstract class RelatorioEvent {}

class RelatorioEstagioSolicitado extends RelatorioEvent {
  final String estagiarioId;
  final DateTime inicio;
  final DateTime fim;
  RelatorioEstagioSolicitado(this.estagiarioId, this.inicio, this.fim);
}

class RelatorioClinicoSolicitado extends RelatorioEvent {
  final String profissionalId;
  RelatorioClinicoSolicitado(this.profissionalId);
}

// BLoC
class RelatorioBloc extends Bloc<RelatorioEvent, RelatorioState> {
  final RelatorioRepository _relatorioRepository;
  final AtendimentoRepository _atendimentoRepository;

  RelatorioBloc(this._relatorioRepository, this._atendimentoRepository) : super(RelatorioInicial()) {
    on<RelatorioEstagioSolicitado>((event, emit) async {
      emit(RelatorioCarregando());
      try {
        final atendimentos = await _relatorioRepository.buscarAtendimentosPorEstagiario(
          event.estagiarioId,
          event.inicio,
          event.fim,
        );
        
        final Map<String, int> contagem = {};
        for (var a in atendimentos) {
          for (var t in a.terapias) {
            contagem[t] = (contagem[t] ?? 0) + 1;
          }
        }

        emit(RelatorioCarregado({
          'atendimentos': atendimentos,
          'total': atendimentos.length,
          'contagem': contagem,
          'periodo': '${event.inicio.day}/${event.inicio.month} a ${event.fim.day}/${event.fim.month}',
        }));
      } catch (e) {
        emit(RelatorioErro('Erro ao carregar relatório de estágio: $e'));
      }
    });

    on<RelatorioClinicoSolicitado>((event, emit) async {
      emit(RelatorioCarregando());
      try {
        final atendimentos = await _atendimentoRepository.buscarPorProfissional(event.profissionalId);
        
        if (atendimentos.isEmpty) {
          emit(RelatorioCarregado({
            'semDados': true,
            'total': 0,
            'contagem': <String, int>{},
            'evolucao': <double>[],
          }));
          return;
        }

        // Processar contagem por terapia
        final Map<String, int> contagem = {};
        for (var a in atendimentos) {
          for (var t in a.terapias) {
            contagem[t] = (contagem[t] ?? 0) + 1;
          }
        }

        // Simular evolução (eixo Y = índice sequencial inverso para mostrar crescimento no tempo)
        // No eixo X usamos os índices, mas poderíamos normalizar datas
        final List<double> evolucao = atendimentos
            .reversed // Do mais antigo para o mais recente
            .toList()
            .asMap()
            .entries
            .map((e) => e.key.toDouble() + 1.0)
            .toList();

        emit(RelatorioCarregado({
          'semDados': false,
          'total': atendimentos.length,
          'contagem': contagem,
          'evolucao': evolucao,
          'dorRecorrente': '${(contagem.values.isNotEmpty ? contagem.values.reduce((a, b) => a > b ? a : b) / atendimentos.length * 100 : 0).toStringAsFixed(0)}%',
          'bemEstar': (evolucao.length > 5 ? '8.2' : '7.5'), // Placeholder para lógica de bem-estar real
          'atendimentos': atendimentos,
        }));
      } catch (e) {
        emit(RelatorioErro('Erro ao carregar relatório clínico: $e'));
      }
    });
  }
}
