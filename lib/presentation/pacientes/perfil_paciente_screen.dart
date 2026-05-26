import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/paciente_model.dart';
import '../../data/models/atendimento_model.dart';
import '../../data/repositories/paciente_repository.dart';
import '../../data/repositories/atendimento_repository.dart';

class PerfilPacienteScreen extends StatelessWidget {
  final String pacienteId;

  const PerfilPacienteScreen({super.key, required this.pacienteId});

  int _calcularIdade(DateTime nascimento) {
    final hoje = DateTime.now();
    int idade = hoje.year - nascimento.year;
    if (hoje.month < nascimento.month || (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }
    return idade;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Paciente'),
      ),
      body: FutureBuilder<PacienteModel?>(
        future: PacienteRepository().buscarPorId(pacienteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Erro ao carregar dados do paciente.'));
          }

          final paciente = snapshot.data!;
          final idade = _calcularIdade(paciente.dataNascimento);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info do Paciente
                Card(
                  elevation: 0,
                  color: AppColors.primary.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                paciente.nome,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text('ID: ${paciente.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('$idade anos • ${paciente.telefone}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Botões de Ação
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/anamnese/clinica/$pacienteId'),
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text('Ver/Editar Anamnese'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/atendimento/novo/$pacienteId'),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Novo Atendimento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Últimos Atendimentos
                const Text(
                  'Últimos Atendimentos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<AtendimentoModel>>(
                  future: AtendimentoRepository().buscarPorPaciente(pacienteId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final atendimentos = (snapshot.data ?? []).take(3).toList();

                    if (atendimentos.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text('Nenhum atendimento realizado.', style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return Column(
                      children: [
                        ...atendimentos.map((a) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history, color: AppColors.primary),
                          title: Text(DateFormat('dd/MM/yyyy HH:mm').format(a.data)),
                          subtitle: Text(a.terapias.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right, size: 16),
                          onTap: () => context.push('/pacientes/$pacienteId/historico'),
                        )),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => context.push('/pacientes/$pacienteId/historico'),
                            child: const Text('Ver Histórico Completo'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
