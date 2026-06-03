import 'dart:io';
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

class HistoricoPacienteScreen extends StatefulWidget {
  final String pacienteId;

  const HistoricoPacienteScreen({super.key, required this.pacienteId});

  @override
  State<HistoricoPacienteScreen> createState() => _HistoricoPacienteScreenState();
}

class _HistoricoPacienteScreenState extends State<HistoricoPacienteScreen> {
  final _atendimentoRepository = AtendimentoRepository();
  List<AtendimentoModel> _todosAtendimentos = [];
  List<AtendimentoModel> _atendimentosFiltrados = [];
  bool _carregando = true;

  String _terapiaFiltro = 'Todos';
  DateTimeRange? _periodoFiltro;

  final List<String> _filtrosTerapia = [
    'Todos', 'Acupuntura', 'Massagem', 'Ventosaterapia', 'Aromaterapia', 'Reiki'
  ];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _carregando = true);
    try {
      _todosAtendimentos = await _atendimentoRepository.buscarPorPaciente(widget.pacienteId);
      _atendimentosFiltrados = _todosAtendimentos;
    } catch (e) {
      debugPrint('Erro ao carregar histórico: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _atendimentosFiltrados = _todosAtendimentos.where((a) {
        final matchesTerapia = _terapiaFiltro == 'Todos' || a.terapias.contains(_terapiaFiltro);
        
        bool matchesPeriodo = true;
        if (_periodoFiltro != null) {
          final dataAtendimento = DateTime(a.data.year, a.data.month, a.data.day);
          matchesPeriodo = dataAtendimento.isAfter(_periodoFiltro!.start.subtract(const Duration(days: 1))) &&
                           dataAtendimento.isBefore(_periodoFiltro!.end.add(const Duration(days: 1)));
        }

        return matchesTerapia && matchesPeriodo;
      }).toList();
    });
  }

  Future<void> _selecionarPeriodo() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _periodoFiltro,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _periodoFiltro = picked;
      });
      _aplicarFiltros();
    }
  }

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
        body: Column(
          children: [
            _buildFiltrosBar(),
            if (_terapiaFiltro != 'Todos' || _periodoFiltro != null)
              _buildActiveFilters(),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _atendimentosFiltrados.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _atendimentosFiltrados.length,
                          itemBuilder: (context, index) {
                            final atendimento = _atendimentosFiltrados[index];
                            return _buildAtendimentoCard(atendimento);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          IconButton(
            onPressed: _selecionarPeriodo,
            icon: Icon(Icons.calendar_today, color: _periodoFiltro != null ? AppColors.primary : Colors.grey),
            tooltip: 'Filtrar por período',
          ),
          const VerticalDivider(width: 20, indent: 8, endIndent: 8),
          ..._filtrosTerapia.map((t) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(t, style: TextStyle(fontSize: 12, color: _terapiaFiltro == t ? Colors.white : Colors.black87)),
                  selected: _terapiaFiltro == t,
                  onSelected: (selected) {
                    setState(() => _terapiaFiltro = t);
                    _aplicarFiltros();
                  },
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_terapiaFiltro != 'Todos')
            Chip(
              label: Text(_terapiaFiltro, style: const TextStyle(fontSize: 11)),
              onDeleted: () {
                setState(() => _terapiaFiltro = 'Todos');
                _aplicarFiltros();
              },
              deleteIcon: const Icon(Icons.close, size: 14),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              side: BorderSide.none,
            ),
          if (_periodoFiltro != null)
            Chip(
              label: Text(
                '${DateFormat('dd/MM').format(_periodoFiltro!.start)} - ${DateFormat('dd/MM').format(_periodoFiltro!.end)}',
                style: const TextStyle(fontSize: 11),
              ),
              onDeleted: () {
                setState(() => _periodoFiltro = null);
                _aplicarFiltros();
              },
              deleteIcon: const Icon(Icons.close, size: 14),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhum atendimento encontrado para este filtro',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
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
          
          if (atendimento.queixaPrincipal != null && atendimento.queixaPrincipal!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Queixa Principal:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                  Text(atendimento.queixaPrincipal!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),

          if (atendimento.pa != null || atendimento.fc != null || atendimento.temperatura != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 16,
                children: [
                  if (atendimento.pa != null) _buildVitalInfo('PA', atendimento.pa!, Icons.speed),
                  if (atendimento.fc != null) _buildVitalInfo('FC', '${atendimento.fc} bpm', Icons.favorite),
                  if (atendimento.temperatura != null) _buildVitalInfo('Temp', '${atendimento.temperatura} °C', Icons.thermostat),
                ],
              ),
            ),

          if (atendimento.terapias.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Evolução:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                Text(
                  atendimento.observacoes,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),

          if (atendimento.assinaturaPath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Text('Assinado pelo paciente', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _mostrarAssinatura(atendimento.assinaturaPath!),
                    child: const Text('Ver Assinatura'),
                  ),
                ],
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

  void _mostrarAssinatura(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Assinatura do Paciente', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Image.file(File(path), width: double.infinity, fit: BoxFit.contain),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalInfo(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
