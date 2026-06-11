import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/atendimento_model.dart';
import '../../data/repositories/atendimento_repository.dart';
import '../../core/services/clinical_intelligence_service.dart';

class MapaAtendimentosScreen extends StatefulWidget {
  const MapaAtendimentosScreen({super.key});

  @override
  State<MapaAtendimentosScreen> createState() => _MapaAtendimentosScreenState();
}

class _MapaAtendimentosScreenState extends State<MapaAtendimentosScreen> {
  final _atendimentoRepository = AtendimentoRepository();
  final _authService = AuthService();
  
  List<AtendimentoModel> _atendimentosFiltrados = [];
  bool _carregando = true;
  final int _mesesFiltro = 3;

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
      // Calcula a data de início (hoje - 3 meses)
      final dataInicio = DateTime.now().subtract(Duration(days: _mesesFiltro * 30));
      
      final atendimentos = await _atendimentoRepository.buscarPorPeriodo(user.uid, dataInicio);
      
      if (mounted) {
        setState(() {
          _atendimentosFiltrados = atendimentos.where((a) => a.latitude != null && a.longitude != null).toList();
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar mapa: $e');
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mapa de Intercorrência', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          if (_carregando)
            const Center(child: CircularProgressIndicator())
          else if (_atendimentosFiltrados.isEmpty)
            _buildEmptyState()
          else
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_atendimentosFiltrados.first.latitude!, _atendimentosFiltrados.first.longitude!),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.milhomes.integra',
                ),
                MarkerLayer(
                  markers: _atendimentosFiltrados.map((a) {
                    return Marker(
                      point: LatLng(a.latitude!, a.longitude!),
                      width: 45,
                      height: 45,
                      child: GestureDetector(
                        onTap: () => _exibirPopup(a),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          
          // Indicador de Filtro Ativo
          if (!_carregando)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Últimos 3 meses',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_atendimentosFiltrados.length}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhuma intercorrência',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
          Text(
            'nos últimos 3 meses.',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  void _exibirPopup(AtendimentoModel a) {
    final service = ClinicalIntelligenceService();
    final termosDetectados = service.extractClinicalTerms(a.queixaPrincipal ?? '');
    final queixaDisplay = termosDetectados.isEmpty ? 'Nenhum termo clínico detectado' : termosDetectados.join(', ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Detalhes da Intercorrência', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.calendar_today_rounded, 'Data', DateFormat('dd/MM/yyyy HH:mm').format(a.data)),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person_outline_rounded, 'Paciente ID', a.pacienteId),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.spa_outlined, 'Terapias', a.terapias.join(", ")),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.medical_services_outlined, 'Termos Clínicos', queixaDisplay),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              Text(value, style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
