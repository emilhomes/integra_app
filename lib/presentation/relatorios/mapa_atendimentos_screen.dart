import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/atendimento_model.dart';
import '../../data/repositories/atendimento_repository.dart';

class MapaAtendimentosScreen extends StatefulWidget {
  const MapaAtendimentosScreen({super.key});

  @override
  State<MapaAtendimentosScreen> createState() => _MapaAtendimentosScreenState();
}

class _MapaAtendimentosScreenState extends State<MapaAtendimentosScreen> {
  final _atendimentoRepository = AtendimentoRepository();
  final _authService = AuthService();
  
  List<AtendimentoModel> _atendimentosComGps = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final user = _authService.usuarioAtual;
    if (user == null) return;

    setState(() => _carregando = true);
    try {
      final todos = await _atendimentoRepository.buscarPorProfissional(user.uid);
      setState(() {
        _atendimentosComGps = todos.where((a) => a.latitude != null && a.longitude != null).toList();
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar mapa: $e');
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Atendimentos'),
      ),
      body: Stack(
        children: [
          if (_carregando)
            const Center(child: CircularProgressIndicator())
          else if (_atendimentosComGps.isEmpty)
            const Center(child: Text('Nenhum atendimento com localização registrada.'))
          else
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_atendimentosComGps.first.latitude!, _atendimentosComGps.first.longitude!),
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.milhomes.integra',
                ),
                MarkerLayer(
                  markers: _atendimentosComGps.map((a) {
                    return Marker(
                      point: LatLng(a.latitude!, a.longitude!),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _exibirPopup(a),
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          
          // Contador no topo
          if (!_carregando && _atendimentosComGps.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '${_atendimentosComGps.length} atendimentos mapeados',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _exibirPopup(AtendimentoModel a) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Local'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(a.data)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Paciente ID: ${a.pacienteId}'),
            const SizedBox(height: 8),
            Text('Terapias: ${a.terapias.join(", ")}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }
}
