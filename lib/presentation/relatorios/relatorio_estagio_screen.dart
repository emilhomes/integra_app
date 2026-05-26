import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import '../../../data/models/atendimento_model.dart';
import '../../../data/repositories/relatorio_repository.dart';
import '../../../data/repositories/atendimento_repository.dart';
import 'bloc/relatorio_bloc.dart';

class RelatorioEstagioScreen extends StatefulWidget {
  const RelatorioEstagioScreen({super.key});

  @override
  State<RelatorioEstagioScreen> createState() => _RelatorioEstagioScreenState();
}

class _RelatorioEstagioScreenState extends State<RelatorioEstagioScreen> {
  DateTime? _dataInicio;
  DateTime? _dataFim;

  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RelatorioBloc(
        RelatorioRepository(),
        AtendimentoRepository(),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Relatório de Estágio')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Seletor de Período
              Row(
                children: [
                  Expanded(child: _buildDateTile('Início', _dataInicio, () => _selecionarData(context, true))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateTile('Fim', _dataFim, () => _selecionarData(context, false))),
                ],
              ),
              const SizedBox(height: 24),
              
              // Botão Gerar
              Builder(
                builder: (context) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_dataInicio != null && _dataFim != null)
                        ? () {
                            final auth = AuthService();
                            context.read<RelatorioBloc>().add(RelatorioEstagioSolicitado(
                              auth.usuarioAtual?.uid ?? 'anonimo',
                              _dataInicio!,
                              _dataFim!,
                            ));
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Gerar Relatório'),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Resultados
              BlocBuilder<RelatorioBloc, RelatorioState>(
                builder: (context, state) {
                  if (state is RelatorioCarregando) return const CircularProgressIndicator();
                  if (state is RelatorioErro) return Text(state.mensagem, style: const TextStyle(color: Colors.red));
                  
                  if (state is RelatorioCarregado) {
                    final dados = state.dados;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.assignment, color: AppColors.primary),
                            title: const Text('Total de Atendimentos'),
                            trailing: Text('${dados['total']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Por Terapia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        ...(dados['contagem'] as Map<String, int>).entries.map((e) => ListTile(
                          title: Text(e.key),
                          trailing: Chip(label: Text('${e.value}')),
                        )),
                        const SizedBox(height: 32),
                        
                        // Botão Exportar PDF
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final auth = AuthService();
                              final path = await PdfService().gerarRelatorioEstagio(
                                estagiarioNome: auth.usuarioAtual?.email ?? 'Estagiário',
                                periodo: dados['periodo'],
                                totalAtendimentos: '${dados['total']}',
                                contagemPorTerapia: Map<String, int>.from(dados['contagem']),
                                atendimentos: (dados['atendimentos'] as List<AtendimentoModel>).map((a) => {
                                  'data': DateFormat('dd/MM/yyyy').format(a.data),
                                  'paciente': a.pacienteId,
                                  'terapias': a.terapias.join(', '),
                                }).toList(),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('PDF salvo: $path'), backgroundColor: AppColors.secondary),
                                );
                                // Abrir o arquivo PDF automaticamente
                                await OpenFilex.open(path);
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Exportar PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, VoidCallback onTap) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 12)),
      subtitle: Text(date == null ? '--/--/----' : DateFormat('dd/MM/yyyy').format(date)),
      trailing: const Icon(Icons.calendar_month),
      onTap: onTap,
      shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
    );
  }
}
