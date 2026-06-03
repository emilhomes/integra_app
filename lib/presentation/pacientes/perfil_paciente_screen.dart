import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/camera_service.dart';
import '../../data/models/paciente_model.dart';
import '../../data/models/atendimento_model.dart';
import '../../data/repositories/paciente_repository.dart';
import '../../data/repositories/atendimento_repository.dart';
import '../../core/services/clinical_intelligence_service.dart';

class PerfilPacienteScreen extends StatefulWidget {
  final String pacienteId;

  const PerfilPacienteScreen({super.key, required this.pacienteId});

  @override
  State<PerfilPacienteScreen> createState() => _PerfilPacienteScreenState();
}

class _PerfilPacienteScreenState extends State<PerfilPacienteScreen> {
  final _pacienteRepository = PacienteRepository();
  final _cameraService = CameraService();
  final _imagePicker = ImagePicker();
  
  PacienteModel? _paciente;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final p = await _pacienteRepository.buscarPorId(widget.pacienteId);
      setState(() {
        _paciente = p;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar paciente: $e');
      setState(() => _carregando = false);
    }
  }

  String _getIniciais(String nome) {
    final partes = nome.trim().split(' ');
    if (partes.length >= 2) {
      return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase();
    } else if (partes.isNotEmpty && partes[0].isNotEmpty) {
      return partes[0][0].toUpperCase();
    }
    return '?';
  }

  Future<void> _escolherOrigemFoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: Text('Tirar Foto', style: GoogleFonts.outfit()),
              onTap: () {
                Navigator.pop(context);
                _tirarFoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text('Escolher da Galeria', style: GoogleFonts.outfit()),
              onTap: () {
                Navigator.pop(context);
                _escolherDaGaleria();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tirarFoto() async {
    final foto = await _cameraService.fotografarDocumento();
    if (foto != null) {
      _atualizarFoto(foto.path);
    }
  }

  Future<void> _escolherDaGaleria() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      _atualizarFoto(image.path);
    }
  }

  Future<void> _atualizarFoto(String path) async {
    if (_paciente == null) return;
    
    final novoPaciente = _paciente!.copyWith(fotoPath: path);
    try {
      await _pacienteRepository.atualizar(novoPaciente);
      setState(() {
        _paciente = novoPaciente;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada com sucesso!'), backgroundColor: AppColors.secondary),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar foto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_paciente == null) {
      return const Scaffold(body: Center(child: Text('Erro ao carregar dados do paciente.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Perfil do Paciente', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          children: [
            // Cabeçalho com Foto e Nome
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          image: _paciente!.fotoPath != null
                              ? DecorationImage(
                                  image: FileImage(File(_paciente!.fotoPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _paciente!.fotoPath == null
                            ? Center(
                                child: Text(
                                  _getIniciais(_paciente!.nome),
                                  style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 40, fontWeight: FontWeight.bold),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _escolherOrigemFoto,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _paciente!.nome,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ID: ${_paciente!.id}',
                      style: GoogleFonts.outfit(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildInfoBadge(Icons.cake_outlined, '${_paciente!.idade} anos'),
                      const SizedBox(width: 16),
                      _buildInfoBadge(Icons.phone_outlined, _paciente!.telefone),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Inteligência Clínica
            _buildIntelligenceSection(),

            const SizedBox(height: 32),

            // Últimos Atendimentos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Últimos Atendimentos',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                TextButton(
                  onPressed: () => context.push('/pacientes/${widget.pacienteId}/historico'),
                  child: Text('Ver Tudo', style: GoogleFonts.outfit(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AtendimentoModel>>(
              future: AtendimentoRepository().buscarPorPaciente(widget.pacienteId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final atendimentos = (snapshot.data ?? []).take(3).toList();

                if (atendimentos.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.history_outlined, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum atendimento realizado.',
                          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: atendimentos.map((a) => _buildAtendimentoTile(a)).toList(),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIntelligenceSection() {
    return FutureBuilder<List<AtendimentoModel>>(
      future: AtendimentoRepository().buscarPorPaciente(widget.pacienteId),
      builder: (context, snapshot) {
        final atendimentos = snapshot.data ?? [];
        final service = ClinicalIntelligenceService();
        final insights = service.generateInsights(atendimentos);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inteligência Clínica',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  if (atendimentos.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => context.push('/pacientes/${widget.pacienteId}/analise', extra: atendimentos),
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: Text('Ver Análise', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Botões de Ações Rápidas (Movidos para cá para melhor fluxo)
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    onPressed: () => context.push('/atendimento/novo/${widget.pacienteId}'),
                    icon: Icons.add_circle_outline,
                    label: 'Novo Registro',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    onPressed: () => context.push('/anamnese/clinica/${widget.pacienteId}'),
                    icon: Icons.assignment_outlined,
                    label: 'Anamnese',
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),

            if (insights.isNotEmpty) ...[
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: insights.length,
                  itemBuilder: (context, index) {
                    final insight = insights[index];
                    return _buildInsightCard(insight);
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInsightCard(IntelligenceInsight insight) {
    Color color;
    IconData icon;
    
    switch (insight.level) {
      case InsightLevel.warning:
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case InsightLevel.success:
        color = Colors.green;
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        color = AppColors.secondary;
        icon = Icons.lightbulb_outline_rounded;
    }

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14)),
      ],
    );
  }

  Widget _buildActionButton({required VoidCallback onPressed, required IconData icon, required String label, required Color color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAtendimentoTile(AtendimentoModel atendimento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.history, color: AppColors.primary, size: 20),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy • HH:mm').format(atendimento.data),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          atendimento.terapias.join(', '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: () => context.push('/pacientes/${widget.pacienteId}/historico'),
      ),
    );
  }
}
