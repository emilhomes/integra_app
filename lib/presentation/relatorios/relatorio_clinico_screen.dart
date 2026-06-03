import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool? _isProfissional;
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();
    _verificarAcesso();
  }

  Future<void> _verificarAcesso() async {
    final auth = AuthService();
    final isProf = await auth.isProfissional();
    if (mounted) {
      setState(() {
        _isProfissional = isProf;
        _carregandoPerfil = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoPerfil) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isProfissional == false) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Acesso Negado', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primary,
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 24),
                Text(
                  'Acesso Restrito',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esta área é reservada para Profissionais e Supervisores.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 15),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Voltar', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final auth = AuthService();
    return BlocProvider(
      create: (context) => RelatorioBloc(
        RelatorioRepository(),
        AtendimentoRepository(),
      )..add(RelatorioClinicoSolicitado(auth.usuarioAtual?.uid ?? 'anonimo')),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Relatórios', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 24)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primary,
        ),
        body: BlocBuilder<RelatorioBloc, RelatorioState>(
          builder: (context, state) {
            if (state is RelatorioCarregando) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RelatorioCarregado) {
              final dados = state.dados;
              
              if (dados['semDados'] == true) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Sem dados suficientes',
                        style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }

              final List<double> evolucao = List<double>.from(dados['evolucao']);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtros Modernos
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _especialidades.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: FilterChip(
                            label: Text(e, style: GoogleFonts.outfit(fontWeight: _especialidadeSelecionada == e ? FontWeight.w700 : FontWeight.w500)),
                            selected: _especialidadeSelecionada == e,
                            onSelected: (selected) {
                              setState(() { _especialidadeSelecionada = e; });
                            },
                            selectedColor: AppColors.secondary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.secondary,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: _especialidadeSelecionada == e ? AppColors.secondary : Colors.transparent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Cards de Indicadores
                    Row(
                      children: [
                        _buildIndicatorCard(
                          'Total Atendimentos',
                          '${dados['total']}',
                          'Base Real',
                          Icons.assessment_rounded,
                          AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildIndicatorCard(
                          'Casos de Dor',
                          dados['dorRecorrente'],
                          'Tendência',
                          Icons.trending_up_rounded,
                          AppColors.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Seção de Gráfico
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volume de Atendimentos',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                          const SizedBox(height: 24),
                          if (evolucao.isNotEmpty)
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Ações de Relatório
                    _buildActionButton(
                      onPressed: () => context.push('/relatorios/mapa'),
                      icon: Icons.map_outlined,
                      label: 'Ver Mapa Geográfico',
                      color: Colors.white,
                      textColor: AppColors.primary,
                      isOutlined: true,
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
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
                            SnackBar(
                              content: Text('PDF gerado com sucesso!', style: GoogleFonts.outfit()),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                          await OpenFilex.open(path);
                        }
                      },
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'Exportar Relatório PDF',
                      color: AppColors.primary,
                      textColor: Colors.white,
                    ),
                    const SizedBox(height: 40),
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
              child: Text(variation, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor, size: 22),
        label: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          side: isOutlined ? const BorderSide(color: AppColors.primary, width: 2) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
