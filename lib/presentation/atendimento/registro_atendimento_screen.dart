import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/validators.dart';
import '../../data/models/paciente_model.dart';
import '../../data/repositories/paciente_repository.dart';
import '../../data/models/atendimento_model.dart';
import '../../data/repositories/atendimento_repository.dart';
import 'bloc/atendimento_bloc.dart';

class RegistroAtendimentoScreen extends StatefulWidget {
  final String pacienteId;
  const RegistroAtendimentoScreen({super.key, required this.pacienteId});

  @override
  State<RegistroAtendimentoScreen> createState() => _RegistroAtendimentoScreenState();
}

class _RegistroAtendimentoScreenState extends State<RegistroAtendimentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paController = TextEditingController();
  final _fcController = TextEditingController();
  final _tempController = TextEditingController();
  final _obsController = TextEditingController();
  
  final List<String> _terapiasDisponiveis = [
    'Acupuntura', 'Massagem', 'Ventosaterapia', 'Aromaterapia', 'Reiki'
  ];
  final List<String> _terapiasSelecionadas = [];
  
  File? _fotoCapturada;
  final _cameraService = CameraService();
  final _gpsService = GpsService();
  final _pacienteRepository = PacienteRepository();

  double? _lat;
  double? _lng;
  bool _carregandoGps = false;
  PacienteModel? _paciente;
  bool _carregandoPaciente = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregandoPaciente = true);
    try {
      _paciente = await _pacienteRepository.buscarPorId(widget.pacienteId);
    } catch (e) {
      debugPrint('Erro ao buscar paciente: $e');
    }
    if (mounted) {
      setState(() => _carregandoPaciente = false);
    }
    _capturarGpsInicial();
  }

  Future<void> _capturarGpsInicial() async {
    setState(() => _carregandoGps = true);
    final posicao = await _gpsService.capturarLocalizacao();
    if (mounted) {
      setState(() {
        if (posicao != null) {
          _lat = posicao.latitude;
          _lng = posicao.longitude;
        }
        _carregandoGps = false;
      });
    }
  }

  @override
  void dispose() {
    _paController.dispose();
    _fcController.dispose();
    _tempController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _fotografar() async {
    final foto = await _cameraService.fotografarDocumento();
    if (foto != null) {
      setState(() {
        _fotoCapturada = foto;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AtendimentoBloc(
        AtendimentoRepository(),
        GpsService(),
        StorageService(),
      ),
      child: BlocConsumer<AtendimentoBloc, AtendimentoState>(
        listener: (context, state) {
          if (state is AtendimentoSalvo) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Atendimento registrado com sucesso!'),
                backgroundColor: AppColors.secondary,
              ),
            );
            context.pop();
          } else if (state is AtendimentoErro) {
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
            appBar: AppBar(title: const Text('Novo Atendimento')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card do Paciente
                    Card(
                      elevation: 0,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: _carregandoPaciente 
                          ? const LinearProgressIndicator()
                          : Text(
                              _paciente?.nome ?? 'Paciente não encontrado',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_paciente != null)
                              Text('Idade: ${_paciente!.idade} anos', style: const TextStyle(fontSize: 14)),
                            Text(
                              'ID: ${widget.pacienteId}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sinais Vitais
                    const Text('Sinais Vitais', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_paController, 'PA (ex: 12/8)', Icons.speed, validator: AppValidators.validarCampoObrigatorio)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField(_fcController, 'FC (bpm)', Icons.favorite, keyboardType: TextInputType.number, validator: AppValidators.validarCampoObrigatorio)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField(_tempController, 'Temp (°C)', Icons.thermostat, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: AppValidators.validarCampoObrigatorio)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Terapias
                    const Text('Terapias Aplicadas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _terapiasDisponiveis.map((terapia) {
                        final isSelected = _terapiasSelecionadas.contains(terapia);
                        return FilterChip(
                          label: Text(terapia),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selected ? _terapiasSelecionadas.add(terapia) : _terapiasSelecionadas.remove(terapia);
                            });
                          },
                          selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.secondary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Observações
                    const Text('Observações Clínicas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _obsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Digite as observações...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Foto
                    const Text('Documentação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _fotografar,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Fotografar Documento'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (_fotoCapturada != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_fotoCapturada!, height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Mapa de Localização
                    const Text('Localização do Atendimento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _carregandoGps
                          ? const Center(child: CircularProgressIndicator())
                          : (_lat != null && _lng != null)
                              ? FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(_lat!, _lng!),
                                    initialZoom: 15.0,
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.none,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.milhomes.integra',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(_lat!, _lng!),
                                          width: 40,
                                          height: 40,
                                          child: const Icon(
                                            Icons.location_pin,
                                            color: Colors.red,
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: Text(
                                    'Não foi possível capturar a localização',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                    ),
                    if (_lat != null && _lng != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Lat: ${_lat!.toStringAsFixed(4)}, Lng: ${_lng!.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 40),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (state is AtendimentoSalvando)
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  final auth = AuthService();
                                  final atendimento = AtendimentoModel(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    pacienteId: widget.pacienteId,
                                    profissionalId: auth.usuarioAtual?.uid ?? 'anonimo',
                                    data: DateTime.now(),
                                    terapias: _terapiasSelecionadas,
                                    observacoes: _obsController.text,
                                    latitude: _lat,
                                    longitude: _lng,
                                  );
                                  context.read<AtendimentoBloc>().add(
                                    AtendimentoSalvarSolicitado(
                                      atendimento: atendimento,
                                      foto: _fotoCapturada,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: (state is AtendimentoSalvando)
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Salvar Registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
