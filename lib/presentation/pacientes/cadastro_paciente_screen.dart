import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
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

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dataNascimento) {
      setState(() {
        _dataNascimento = picked;
      });
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
              const SnackBar(
                content: Text('Paciente cadastrado com sucesso!'),
                backgroundColor: AppColors.secondary,
              ),
            );
            context.pop();
          } else if (state is PacienteErro) {
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
            appBar: AppBar(
              title: const Text('Novo Paciente'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados Pessoais',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Nome Completo',
                      controller: _nomeController,
                      icon: Icons.person_outline,
                      validator: AppValidators.validarNome,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _dataNascimento == null 
                          ? 'Data de Nascimento' 
                          : 'Nascimento: ${DateFormat('dd/MM/yyyy').format(_dataNascimento!)}',
                      ),
                      leading: const Icon(Icons.calendar_today_outlined),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _selecionarData(context),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'CPF',
                      controller: _cpfController,
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      validator: AppValidators.validarCPF,
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
                    
                    const SizedBox(height: 32),
                    const Text(
                      'Histórico Básico',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    _buildField(label: 'Alergias conhecidas', maxLines: 2),
                    const SizedBox(height: 16),
                    _buildField(label: 'Medicamentos em uso', maxLines: 2),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: state is PacienteCarregando
                            ? null
                            : () {
                                if (_formKey.currentState!.validate() && _dataNascimento != null) {
                                  final novoPaciente = PacienteModel(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(), // ID temporário
                                    nome: _nomeController.text,
                                    cpf: _cpfController.text,
                                    dataNascimento: _dataNascimento!,
                                    telefone: _telefoneController.text,
                                    endereco: _enderecoController.text,
                                  );
                                  context.read<PacienteBloc>().add(PacienteSalvarSolicitado(novoPaciente));
                                } else if (_dataNascimento == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Selecione a data de nascimento')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: state is PacienteCarregando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Salvar Cadastro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    TextEditingController? controller,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
