import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/auth_service.dart';
import 'bloc/relatorio_bloc.dart';
import '../../../data/repositories/relatorio_repository.dart';
import '../../../data/repositories/atendimento_repository.dart';
import '../../../data/models/atendimento_model.dart';

class RelatorioClinicoScreen extends StatefulWidget {
  const RelatorioClinicoScreen({super.key});

  @override
  State<RelatorioClinicoScreen> createState() => _RelatorioClinicoScreenState();
}

class _RelatorioClinicoScreenState extends State<RelatorioClinicoScreen> {
  final List<String> _especialidades = ['Todos', 'Acupuntura', 'Nutrição', 'Fisioterapia', 'Psicologia'];
  String _especialidadeSelecionada = 'Todos';

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return BlocProvider(
      create: (context) => RelatorioBloc(
        RelatorioRepository(),
        AtendimentoRepository(),
      )..add(RelatorioClinicoSolicitado(auth.usuarioAtual?.uid ?? 'anonimo')),
      child: Scaffold(
        appBar: AppBar(title: const Text('Relatórios Clínicos')),
        body: BlocBuilder<RelatorioBloc, RelatorioState>(
          builder: (context, state) {
            if (state is RelatorioCarregando) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RelatorioCarregado) {
              final dados = state.dados;
              
              if (dados['semDados'] == true) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Sem dados suficientes para análise', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }

              final List<double> evolucao = List<double>.from(dados['evolucao']);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtros
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _especialidades.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(e),
                            selected: _especialidadeSelecionada == e,
                            onSelected: (selected) {
                              setState(() { _especialidadeSelecionada = e; });
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cards
                    Row(
                      children: [
                        _buildIndicatorCard(
                          'Total Atendimentos',
                          '${dados['total']}',
                          'Base Real',
                          Icons.assessment,
                          AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildIndicatorCard(
                          'Frequência de Dor',
                          dados['dorRecorrente'],
                          'Calculado',
                          Icons.trending_up,
                          AppColors.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text('Volume de Atendimentos no Tempo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 24),
                    
                    // Gráfico
                    if (evolucao.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
                          minX: 0,
                          maxX: (evolucao.length - 1).toDouble(),
                          minY: 0,
                          maxY: (evolucao.length + 2).toDouble(),
                          lineBarsData: [
                            LineChartBarData(
                              spots: evolucao.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 4,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.1)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Botão PDF
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final atendimentos = (dados['atendimentos'] as List<AtendimentoModel>).take(5).map((a) => {
                            'data': DateFormat('dd/MM').format(a.data),
                            'terapia': a.terapias.join(', '),
                            'obs': a.observacoes.length > 20 ? '${a.observacoes.substring(0, 20)}...' : a.observacoes,
                          }).toList();

                          final path = await PdfService().gerarRelatorioClinico(
                            pacienteNome: 'Relatório Geral do Profissional',
                            dorRecorrente: dados['dorRecorrente'],
                            bemEstar: '${dados['total']} atendimentos',
                            atendimentos: atendimentos,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('PDF gerado: $path'), backgroundColor: AppColors.secondary),
                            );
                            // Abrir o arquivo PDF automaticamente
                            await OpenFilex.open(path);
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Gerar Relatório PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildIndicatorCard(String title, String value, String variation, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withValues(alpha: 0.2))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(variation, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ],
          ),
        ),
      ),
    );
  }
}
