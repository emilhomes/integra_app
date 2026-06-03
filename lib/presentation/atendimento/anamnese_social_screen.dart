import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/paciente_model.dart';
import '../../data/repositories/paciente_repository.dart';

class AnamneseSocialScreen extends StatefulWidget {
  final String pacienteId;
  const AnamneseSocialScreen({super.key, required this.pacienteId});

  @override
  State<AnamneseSocialScreen> createState() => _AnamneseSocialScreenState();
}

class _AnamneseSocialScreenState extends State<AnamneseSocialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pacienteRepository = PacienteRepository();

  final _moradiaController = TextEditingController();
  final _numResidentesController = TextEditingController();
  final _estadoCivilController = TextEditingController();
  final _rendaController = TextEditingController();
  final _acessoSaudeController = TextEditingController();
  
  bool _temSaneamento = true;
  PacienteModel? _paciente;
  bool _carregando = true;

  final List<String> _moradias = ['Própria', 'Alugada', 'Cedida', 'Outros'];
  final List<String> _rendas = ['Até 1 SM', '1 a 3 SM', '3 a 5 SM', 'Acima de 5 SM'];

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
        _moradiaController.text = _paciente!.moradia ?? '';
        _numResidentesController.text = _paciente!.numResidentes ?? '';
        _estadoCivilController.text = _paciente!.estadoCivil ?? '';
        _rendaController.text = _paciente!.rendaFamiliar ?? '';
        _acessoSaudeController.text = _paciente!.acessoSaude ?? '';
        _temSaneamento = _paciente!.temSaneamento ?? true;
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
      moradia: _moradiaController.text,
      numResidentes: _numResidentesController.text,
      estadoCivil: _estadoCivilController.text,
      rendaFamiliar: _rendaController.text,
      acessoSaude: _acessoSaudeController.text,
      temSaneamento: _temSaneamento,
    );

    try {
      await _pacienteRepository.atualizar(novoPaciente);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anamnese salva com sucesso!'), backgroundColor: AppColors.secondary),
        );
        context.go('/pacientes/${widget.pacienteId}/perfil');
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
    _moradiaController.dispose();
    _numResidentesController.dispose();
    _estadoCivilController.dispose();
    _rendaController.dispose();
    _acessoSaudeController.dispose();
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
        title: Text('Anamnese Social', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
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
                'Perfil Social',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Condições socioeconômicas e habitacionais.',
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Habitação'),
              _buildDropdown('Tipo de Moradia', _moradias, _moradiaController),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: Text('Possui saneamento básico?', style: GoogleFonts.outfit(fontSize: 16)),
                  value: _temSaneamento,
                  onChanged: (v) => setState(() => _temSaneamento = v),
                  activeColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Estrutura Familiar'),
              _buildTextField('Número de residentes na casa', _numResidentesController, icon: Icons.people_outline, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField('Estado Civil', _estadoCivilController, icon: Icons.favorite_border),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Socioeconômico'),
              _buildDropdown('Renda Familiar Estimada', _rendas, _rendaController),
              const SizedBox(height: 16),
              _buildTextField('Acesso à Saúde (Ex: SUS, Plano)', _acessoSaudeController, icon: Icons.health_and_safety_outlined),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Salvar Anamnese', 
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {required IconData icon, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _buildDropdown(String label, List<String> options, TextEditingController controller) {
    return DropdownButtonFormField<String>(
      value: options.contains(controller.text) ? controller.text : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.home_outlined, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: options.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: GoogleFonts.outfit()),
        );
      }).toList(),
      onChanged: (v) {
        setState(() {
          controller.text = v ?? '';
        });
      },
    );
  }
}
