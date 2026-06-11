import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/validators.dart';
import '../../data/models/paciente_model.dart';
import '../../data/repositories/paciente_repository.dart';
import '../../data/repositories/agendamento_repository.dart';
import '../../data/models/atendimento_model.dart';
import '../../data/repositories/atendimento_repository.dart';
import '../../core/services/clinical_intelligence_service.dart';
import 'bloc/atendimento_bloc.dart';

class RegistroAtendimentoScreen extends StatefulWidget {
  final String pacienteId;
  final String? agendamentoId;
  const RegistroAtendimentoScreen({super.key, required this.pacienteId, this.agendamentoId});

  @override
  State<RegistroAtendimentoScreen> createState() => _RegistroAtendimentoScreenState();
}

class _RegistroAtendimentoScreenState extends State<RegistroAtendimentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _queixaController = TextEditingController();
  final _paController = TextEditingController();
  final _fcController = TextEditingController();
  final _tempController = TextEditingController();
  final _obsController = TextEditingController();
  
  final List<String> _terapiasDisponiveis = [
    'Acupuntura', 'Massagem', 'Ventosaterapia', 'Aromaterapia', 'Reiki'
  ];
  final List<String> _terapiasSelecionadas = [];
  
  List<Map<String, dynamic>> _pontosDorTensao = [];
  String? _assinaturaPath;
  final _gpsService = GpsService();
  final _pacienteRepository = PacienteRepository();
  final _agendamentoRepository = AgendamentoRepository();

  double? _lat;
  double? _lng;
  bool _carregandoGps = false;
  PacienteModel? _paciente;
  bool _carregandoPaciente = true;
  double? _mediaFCHistorica;
  List<IntelligenceInsight> _insightsRecentes = [];
  final _fcFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
    _fcFocusNode.addListener(_monitorarSinaisVitais);
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _carregandoPaciente = true);
    
    try {
      // Busca dados em paralelo para ser mais rápido
      final results = await Future.wait([
        _pacienteRepository.buscarPorId(widget.pacienteId),
        AtendimentoRepository().buscarPorPaciente(widget.pacienteId),
      ]);

      _paciente = results[0] as PacienteModel?;
      final atendimentos = results[1] as List<AtendimentoModel>;

      if (atendimentos.isNotEmpty) {
        final fcs = atendimentos
            .where((a) => a.fc != null && double.tryParse(a.fc!) != null)
            .map((a) => double.parse(a.fc!))
            .toList();
        if (fcs.isNotEmpty) {
          _mediaFCHistorica = fcs.reduce((a, b) => a + b) / fcs.length;
        }

        // Gera insights de forma assíncrona para não travar a UI
        final service = ClinicalIntelligenceService();
        _insightsRecentes = service.generateInsights(atendimentos);
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados: $e');
    } finally {
      if (mounted) {
        setState(() => _carregandoPaciente = false);
      }
      _capturarGpsInicial();
    }
  }

  Future<void> _capturarGpsInicial() async {
    setState(() => _carregandoGps = true);
    final posicao = await _gpsService.capturarLocalizacao();
    if (mounted) {
      setState(() {
        if (posicao != null) {
          _lat = posicao.latitude;
          _lng = posicao.longitude;
        }
        _carregandoGps = false;
      });
    }
  }

  void _monitorarSinaisVitais() {
    // Só dispara o alerta ao perder o foco (terminar de preencher)
    if (_fcFocusNode.hasFocus) return;

    if (_fcController.text.isEmpty) return;
    final valor = double.tryParse(_fcController.text);
    if (valor == null) return;

    String? mensagem;
    
    // 1. Alerta por valor absoluto (Taquicardia ou Bradicardia)
    if (valor > 100) {
      mensagem = 'Alerta: Frequência Cardíaca Elevada ($valor bpm - Taquicardia).';
    } else if (valor < 50) {
      mensagem = 'Alerta: Frequência Cardíaca Baixa ($valor bpm - Bradicardia).';
    }
    // 2. Alerta por variação histórica (Mais sensível: > 10 bpm)
    else if (_mediaFCHistorica != null && (valor - _mediaFCHistorica!).abs() > 10) {
      mensagem = 'Alerta: Frequência Cardíaca ($valor bpm) fora do padrão habitual (~${_mediaFCHistorica!.toStringAsFixed(0)} bpm).';
    }

    if (mensagem != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fcFocusNode.removeListener(_monitorarSinaisVitais);
    _fcFocusNode.dispose();
    _queixaController.dispose();
    _paController.dispose();
    _fcController.dispose();
    _tempController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _abrirMapaCorporal() async {
    final result = await context.push<List<Map<String, dynamic>>>(
      '/anamnese/fisica/${widget.pacienteId}',
      extra: _pontosDorTensao,
    );
    if (result != null) {
      setState(() {
        _pontosDorTensao = result;
      });
    }
  }

  Future<void> _coletarAssinatura() async {
    final result = await context.push<String>('/atendimento/assinatura/${widget.pacienteId}');
    if (result != null) {
      setState(() {
        _assinaturaPath = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AtendimentoBloc(
        AtendimentoRepository(),
        GpsService(),
        StorageService(),
      ),
      child: BlocConsumer<AtendimentoBloc, AtendimentoState>(
        listener: (context, state) async {
          if (state is AtendimentoSalvo) {
            if (widget.agendamentoId != null) {
              try {
                await _agendamentoRepository.atualizarStatus(widget.agendamentoId!, 'realizado');
              } catch (e) {
                debugPrint('Erro ao atualizar status do agendamento: $e');
              }
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Atendimento registrado e agendamento concluído!'),
                  backgroundColor: Colors.green,
                ),
              );
              context.go('/agenda');
            }
          } else if (state is AtendimentoErro) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.mensagem),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text('Novo Atendimento', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: AppColors.primary,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card do Paciente (Simplificado)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _carregandoPaciente 
                                  ? const LinearProgressIndicator()
                                  : Text(
                                      _paciente?.nome ?? 'Paciente não encontrado',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary),
                                    ),
                                if (_paciente != null)
                                  Text('${_paciente!.idade} anos • ID: ${widget.pacienteId}', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Avaliação Inicial
                    _buildSectionTitle('Avaliação Inicial'),
                    _buildTextArea(_queixaController, 'O que o paciente está sentindo hoje?', label: 'Queixa Principal', icon: Icons.chat_bubble_outline),
                    const SizedBox(height: 8),
                    // Atalhos para queixas comuns (Doenças)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Febre', 'Dor de cabeça', 'Dor na lombar', 'Ansiedade', 'Insônia', 'Estresse', 'Tensão muscular'
                        ].map((queixa) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(queixa, style: GoogleFonts.outfit(fontSize: 12)),
                            onPressed: () {
                              if (_queixaController.text.isEmpty) {
                                _queixaController.text = queixa;
                              } else {
                                if (!_queixaController.text.contains(queixa)) {
                                  _queixaController.text += ', $queixa';
                                }
                              }
                            },
                            backgroundColor: Colors.white,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSelectionButton(
                      onPressed: _abrirMapaCorporal,
                      icon: Icons.accessibility_new,
                      label: 'Mapa de Dor/Tensão',
                      value: _pontosDorTensao.isEmpty ? 'Nenhum ponto marcado' : '${_pontosDorTensao.length} pontos marcados',
                      isFilled: _pontosDorTensao.isNotEmpty,
                    ),
                    const SizedBox(height: 32),

                    // Sinais Vitais
                    _buildSectionTitle('Sinais Vitais'),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_paController, 'PA', Icons.speed, hint: '12/8')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_fcController, 'FC', Icons.favorite, hint: 'bpm', keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTextField(_tempController, 'Temp', Icons.thermostat, hint: '°C', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Terapias
                    _buildSectionTitle('Terapias Aplicadas'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _terapiasDisponiveis.map((terapia) {
                        final isSelected = _terapiasSelecionadas.contains(terapia);
                        return FilterChip(
                          label: Text(terapia, style: GoogleFonts.outfit(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selected ? _terapiasSelecionadas.add(terapia) : _terapiasSelecionadas.remove(terapia);
                            });
                          },
                          selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.secondary,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppColors.secondary : Colors.transparent)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Observações
                    _buildSectionTitle('Evolução / Observações'),
                    _buildTextArea(_obsController, 'Relate a evolução do paciente...', icon: Icons.edit_note),
                    const SizedBox(height: 32),

                    // Assinatura
                    _buildSectionTitle('Confirmação'),
                    _buildSelectionButton(
                      onPressed: _coletarAssinatura,
                      icon: Icons.gesture,
                      label: 'Assinatura do Paciente',
                      value: _assinaturaPath == null ? 'Coleta pendente' : 'Assinatura coletada',
                      isFilled: _assinaturaPath != null,
                    ),
                    const SizedBox(height: 32),

                    // Localização
                    _buildSectionTitle('Localização'),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _carregandoGps
                          ? const Center(child: CircularProgressIndicator())
                          : (_lat != null && _lng != null)
                              ? FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(_lat!, _lng!),
                                    initialZoom: 15.0,
                                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.milhomes.integra',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(_lat!, _lng!),
                                          width: 40,
                                          height: 40,
                                          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : const Center(child: Text('GPS Indisponível', style: TextStyle(color: Colors.red))),
                    ),
                    const SizedBox(height: 48),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (state is AtendimentoSalvando)
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  final auth = AuthService();
                                  final atendimento = AtendimentoModel(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    pacienteId: widget.pacienteId,
                                    profissionalId: auth.usuarioAtual?.uid ?? 'anonimo',
                                    data: DateTime.now(),
                                    terapias: _terapiasSelecionadas,
                                    observacoes: _obsController.text,
                                    latitude: _lat,
                                    longitude: _lng,
                                    assinaturaPath: _assinaturaPath,
                                    queixaPrincipal: _queixaController.text,
                                    pontosDorTensao: _pontosDorTensao,
                                    pa: _paController.text,
                                    fc: _fcController.text,
                                    temperatura: _tempController.text,
                                  );
                                  context.read<AtendimentoBloc>().add(
                                    AtendimentoSalvarSolicitado(
                                      atendimento: atendimento,
                                      foto: null, // Removido
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: (state is AtendimentoSalvando)
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Salvar Registro', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmallInsightCard(IntelligenceInsight insight) {
    final color = insight.level == InsightLevel.warning ? Colors.orange : AppColors.secondary;
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(insight.level == InsightLevel.warning ? Icons.warning_amber_rounded : Icons.lightbulb_outline, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                Text(insight.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[800])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {String? hint, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        ),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  Widget _buildTextArea(TextEditingController controller, String hint, {String? label, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          ),
        TextFormField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionButton({required VoidCallback onPressed, required IconData icon, required String label, required String value, bool isFilled = false}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isFilled ? AppColors.secondary.withValues(alpha: 0.5) : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isFilled ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isFilled ? AppColors.secondary : AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  Text(value, style: GoogleFonts.outfit(fontSize: 12, color: isFilled ? AppColors.secondary : Colors.grey[600], fontWeight: isFilled ? FontWeight.w600 : FontWeight.normal)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
