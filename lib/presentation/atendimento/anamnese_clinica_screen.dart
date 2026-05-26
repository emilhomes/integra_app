import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class AnamneseClinicaScreen extends StatefulWidget {
  final String pacienteId;
  const AnamneseClinicaScreen({super.key, required this.pacienteId});

  @override
  State<AnamneseClinicaScreen> createState() => _AnamneseClinicaScreenState();
}

class _AnamneseClinicaScreenState extends State<AnamneseClinicaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final _queixaController = TextEditingController();
  final _historicoDoencasController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _alergiasController = TextEditingController();
  final _antecedentesFamiliaresController = TextEditingController();

  @override
  void dispose() {
    _queixaController.dispose();
    _historicoDoencasController.dispose();
    _medicamentosController.dispose();
    _alergiasController.dispose();
    _antecedentesFamiliaresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anamnese Clínica'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Queixa Principal'),
              _buildTextArea(_queixaController, 'Descreva a queixa principal do paciente...'),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Histórico de Doenças'),
              _buildTextArea(_historicoDoencasController, 'Ex: Diabetes, Hipertensão, etc.'),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Medicamentos em Uso'),
              _buildTextArea(_medicamentosController, 'Liste os medicamentos e dosagens...'),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Alergias'),
              _buildTextArea(_alergiasController, 'Alergias alimentares, medicamentosas ou outras...'),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Antecedentes Familiares'),
              _buildTextArea(_antecedentesFamiliaresController, 'Histórico de saúde da família...'),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.push('/anamnese/fisica/${widget.pacienteId}');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Próximo: Anamnese Física', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildTextArea(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo obrigatório';
        return null;
      },
    );
  }
}
