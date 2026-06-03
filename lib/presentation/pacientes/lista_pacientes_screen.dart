import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/paciente_model.dart';
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            modo == 'atendimento' ? 'Selecionar Paciente' : 'Pacientes', 
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 24)
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        body: Column(
          children: [
            // Campo de Busca Moderno
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Builder(
                builder: (context) => TextField(
                  onChanged: (value) {
                    context.read<PacienteBloc>().add(PacienteBuscaSolicitada(value));
                  },
                  style: GoogleFonts.outfit(),
                  decoration: InputDecoration(
                    hintText: 'Buscar paciente por nome...',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      return _buildEmptyState();
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: pacientes.length,
                      itemBuilder: (context, index) {
                        final paciente = pacientes[index];
                        return _buildPacienteCard(context, paciente);
                      },
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/pacientes/cadastro'),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
          label: Text('Cadastrar', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhum paciente encontrado',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece cadastrando seu primeiro paciente.',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildPacienteCard(BuildContext context, PacienteModel paciente) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            image: paciente.fotoPath != null
                ? DecorationImage(image: FileImage(File(paciente.fotoPath!)), fit: BoxFit.cover)
                : null,
          ),
          child: paciente.fotoPath == null
              ? Center(
                  child: Text(
                    paciente.nome[0].toUpperCase(),
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                )
              : null,
        ),
        title: Text(
          paciente.nome,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.primary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.cake_outlined, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('${paciente.idade} anos', style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(width: 12),
                Icon(Icons.phone_outlined, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(paciente.telefone, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[300]),
        onTap: () {
          if (modo == 'atendimento') {
            context.push('/atendimento/novo/${paciente.id}');
          } else {
            context.push('/pacientes/${paciente.id}/perfil');
          }
        },
      ),
    );
  }
}
