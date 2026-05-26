import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class AnamneseSocialScreen extends StatefulWidget {
  final String pacienteId;
  const AnamneseSocialScreen({super.key, required this.pacienteId});

  @override
  State<AnamneseSocialScreen> createState() => _AnamneseSocialScreenState();
}

class _AnamneseSocialScreenState extends State<AnamneseSocialScreen> {
  final _formKey = GlobalKey<FormState>();

  // Opções para dropdowns
  final List<String> _moradias = ['Própria', 'Alugada', 'Cedida', 'Outros'];
  final List<String> _rendas = ['Até 1 SM', '1 a 3 SM', '3 a 5 SM', 'Acima de 5 SM'];
  
  bool _temSaneamento = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anamnese Social')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Habitação e Saneamento'),
              _buildDropdown('Tipo de Moradia', _moradias, (v) {}),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Possui saneamento básico?'),
                value: _temSaneamento,
                onChanged: (v) => setState(() => _temSaneamento = v),
                activeThumbColor: AppColors.secondary,
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Estrutura Familiar'),
              _buildTextField('Número de residentes na casa', keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField('Estado Civil'),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Socioeconômico'),
              _buildDropdown('Renda Familiar Estimada', _rendas, (v) {}),
              const SizedBox(height: 16),
              _buildTextField('Acesso à Saúde (Ex: SUS, Plano Privado)'),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Anamnese salva com sucesso!'),
                          backgroundColor: AppColors.secondary,
                        ),
                      );
                      context.go('/pacientes');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Salvar Anamnese', style: TextStyle(fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildTextField(String label, {TextInputType? keyboardType}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Selecione uma opção' : null,
    );
  }
}
