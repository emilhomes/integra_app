import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/services/camera_service.dart';
import '../../data/models/paciente_model.dart';
import '../../data/repositories/paciente_repository.dart';
import 'bloc/paciente_bloc.dart';

class CadastroPacienteScreen extends StatefulWidget {
  const CadastroPacienteScreen({super.key});

  @override
  State<CadastroPacienteScreen> createState() => _CadastroPacienteScreenState();
}

class _CadastroPacienteScreenState extends State<CadastroPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  DateTime? _dataNascimento;
  bool _digitalizando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _digitalizarDocumento() async {
    setState(() => _digitalizando = true);
    
    try {
      final cameraService = CameraService();
      final foto = await cameraService.fotografarDocumento();
      
      if (foto != null) {
        // SIMULAÇÃO DE OCR (Extração de dados inteligente)
        // Em um cenário real, usaríamos o Google ML Kit ou similar aqui.
        await Future.delayed(const Duration(seconds: 2)); // Simula processamento
        
        setState(() {
          // Dados "extraídos" do documento simulado
          _nomeController.text = 'João Silva Santos';
          _cpfController.text = '12345678900';
          _dataNascimento = DateTime(1990, 05, 15);
          _enderecoController.text = 'Rua das Flores, 123 - Centro';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento processado! Verifique os dados preenchidos.'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao digitalizar: $e');
    } finally {
      if (mounted) setState(() => _digitalizando = false);
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dataNascimento = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PacienteBloc(PacienteRepository()),
      child: BlocConsumer<PacienteBloc, PacienteState>(
        listener: (context, state) {
          if (state is PacienteSucesso) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paciente cadastrado com sucesso!'), backgroundColor: AppColors.secondary),
            );
            context.pop();
          } else if (state is PacienteErro) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.mensagem), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text('Novo Paciente', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
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
                    // Botão de Digitalização Inteligente
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Cadastro Inteligente',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tire foto do RG ou CNH para preencher os dados automaticamente.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _digitalizando ? null : _digitalizarDocumento,
                              icon: _digitalizando 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.camera_alt_rounded, size: 20),
                              label: Text(
                                _digitalizando ? 'Processando...' : 'Digitalizar Documento', 
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w700)
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    _buildSectionTitle('Dados do Paciente'),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Nome Completo',
                      controller: _nomeController,
                      icon: Icons.person_outline_rounded,
                      validator: AppValidators.validarNome,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            label: 'CPF',
                            controller: _cpfController,
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            validator: AppValidators.validarCPF,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () => _selecionarData(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _dataNascimento == null 
                                        ? 'Nascimento' 
                                        : DateFormat('dd/MM/yyyy').format(_dataNascimento!),
                                      style: GoogleFonts.outfit(
                                        fontSize: 14, 
                                        color: _dataNascimento == null ? Colors.grey[400] : Colors.black87
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Telefone',
                      controller: _telefoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: AppValidators.validarTelefone,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Endereço',
                      controller: _enderecoController,
                      icon: Icons.location_on_outlined,
                      validator: AppValidators.validarCampoObrigatorio,
                    ),
                    
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is PacienteCarregando
                            ? null
                            : () {
                                if (_formKey.currentState!.validate() && _dataNascimento != null) {
                                  final novoPaciente = PacienteModel(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    nome: _nomeController.text,
                                    cpf: _cpfController.text,
                                    dataNascimento: _dataNascimento!,
                                    telefone: _telefoneController.text,
                                    endereco: _enderecoController.text,
                                  );
                                  context.read<PacienteBloc>().add(PacienteSalvarSolicitado(novoPaciente));
                                } else if (_dataNascimento == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Por favor, informe a data de nascimento.')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: state is PacienteCarregando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Finalizar Cadastro', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.outfit(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
