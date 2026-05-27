import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/atendimento_model.dart';
import '../../data/repositories/atendimento_repository.dart';
import '../atendimento/bloc/atendimento_bloc.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/storage_service.dart';

class HistoricoPacienteScreen extends StatelessWidget {
  final String pacienteId;

  const HistoricoPacienteScreen({super.key, required this.pacienteId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AtendimentoBloc(
            AtendimentoRepository(),
            GpsService(),
            StorageService(),
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Histórico do Paciente'),
        ),
        body: FutureBuilder<List<AtendimentoModel>>(
          future: AtendimentoRepository().buscarPorPaciente(pacienteId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar histórico: ${snapshot.error}'));
            }

            final atendimentos = snapshot.data ?? [];

            if (atendimentos.isEmpty) {
              return const Center(
                child: Text('Nenhum atendimento registrado para este paciente.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: atendimentos.length,
              itemBuilder: (context, index) {
                final atendimento = atendimentos[index];
                return _buildAtendimentoCard(atendimento);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAtendimentoCard(AtendimentoModel atendimento) {
    final hasGps = atendimento.latitude != null && atendimento.longitude != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.event, color: Colors.white, size: 20),
            ),
            title: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(atendimento.data),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          if (atendimento.terapias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: atendimento.terapias.map((t) => Chip(
                  label: Text(t, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              atendimento.observacoes,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          
          // Mapa ou Indicador de Localização
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasGps
                ? FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(atendimento.latitude!, atendimento.longitude!),
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.milhomes.integra',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(atendimento.latitude!, atendimento.longitude!),
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, color: Colors.grey, size: 16),
                        SizedBox(width: 8),
                        Text('Localização não registrada', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
