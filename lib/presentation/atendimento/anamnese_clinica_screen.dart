import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/paciente_model.dart';
import '../../data/repositories/paciente_repository.dart';

class AnamneseClinicaScreen extends StatefulWidget {
  final String pacienteId;
  const AnamneseClinicaScreen({super.key, required this.pacienteId});

  @override
  State<AnamneseClinicaScreen> createState() => _AnamneseClinicaScreenState();
}

class _AnamneseClinicaScreenState extends State<AnamneseClinicaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pacienteRepository = PacienteRepository();
  
  final _historicoDoencasController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _antecedentesFamiliaresController = TextEditingController();

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
      _paciente = await _pacienteRepository.buscarPorId(widget.pacienteId);
      if (_paciente != null) {
        _historicoDoencasController.text = _paciente!.historicoDoencas ?? '';
        _medicamentosController.text = _paciente!.medicamentosEmUso ?? '';
        _alergiasController.text = _paciente!.alergias ?? '';
        _antecedentesFamiliaresController.text = _paciente!.antecedentesFamiliares ?? '';
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    if (_paciente == null) return;

    final novoPaciente = _paciente!.copyWith(
      historicoDoencas: _historicoDoencasController.text,
      medicamentosEmUso: _medicamentosController.text,
      alergias: _alergiasController.text,
      antecedentesFamiliares: _antecedentesFamiliaresController.text,
    );

    try {
      await _pacienteRepository.atualizar(novoPaciente);
      if (mounted) {
        context.push('/anamnese/social/${widget.pacienteId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _historicoDoencasController.dispose();
    _medicamentosController.dispose();
    _alergiasController.dispose();
    _antecedentesFamiliaresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Anamnese Clínica', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
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
              Text(
                'Histórico Clínico',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Informações que permanecem no prontuário do paciente.',
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              _buildFieldGroup(
                label: 'Histórico de Doenças',
                child: _buildTextArea(
                  _historicoDoencasController, 
                  'Diabetes, Hipertensão, cirurgias anteriores...',
                  icon: Icons.history_edu_rounded,
                ),
              ),
              
              _buildFieldGroup(
                label: 'Medicamentos em Uso',
                child: _buildTextArea(
                  _medicamentosController, 
                  'Liste remédios, dosagens e horários...',
                  icon: Icons.medication_outlined,
                ),
              ),
              
              _buildFieldGroup(
                label: 'Alergias',
                child: _buildTextArea(
                  _alergiasController, 
                  'Alimentares, medicamentosas ou sazonais...',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              
              _buildFieldGroup(
                label: 'Antecedentes Familiares',
                child: _buildTextArea(
                  _antecedentesFamiliaresController, 
                  'Histórico relevante de pais e avós...',
                  icon: Icons.family_restroom_rounded,
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Próximo: Exame Social', 
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldGroup({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextArea(TextEditingController controller, String hint, {required IconData icon}) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      style: GoogleFonts.outfit(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 45), // Alinha ícone ao topo
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorStyle: GoogleFonts.outfit(fontSize: 12),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
