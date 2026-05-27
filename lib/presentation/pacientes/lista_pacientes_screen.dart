import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/paciente_repository.dart';
import 'bloc/paciente_bloc.dart';

class ListaPacientesScreen extends StatelessWidget {
  final String? modo;
  const ListaPacientesScreen({super.key, this.modo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PacienteBloc(PacienteRepository())..add(PacienteCarregamentoSolicitado()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(modo == 'atendimento' ? 'Selecionar Paciente' : 'Pacientes'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: Column(
          children: [
            // Campo de Busca
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) => TextField(
                  onChanged: (value) {
                    context.read<PacienteBloc>().add(PacienteBuscaSolicitada(value));
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar paciente...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            
            // Lista de Pacientes
            Expanded(
              child: BlocBuilder<PacienteBloc, PacienteState>(
                builder: (context, state) {
                  if (state is PacienteCarregando) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (state is PacienteErro) {
                    return Center(child: Text(state.mensagem));
                  }
                  
                  if (state is PacienteCarregado) {
                    final pacientes = state.pacientes;
                    
                    if (pacientes.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum paciente cadastrado ainda',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: pacientes.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final paciente = pacientes[index];
                        return ListTile(
                          title: Text(
                            paciente.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('ID: ${paciente.id}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (modo == 'atendimento') {
                              context.push('/atendimento/novo/${paciente.id}');
                            } else {
                              context.push('/pacientes/${paciente.id}/perfil');
                            }
                          },
                        );
                      },
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/pacientes/cadastro'),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
