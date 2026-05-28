import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/camera_service.dart';
import '../../data/models/paciente_model.dart';
import '../../data/models/atendimento_model.dart';
import '../../data/repositories/paciente_repository.dart';
import '../../data/repositories/atendimento_repository.dart';

class PerfilPacienteScreen extends StatefulWidget {
  final String pacienteId;

  const PerfilPacienteScreen({super.key, required this.pacienteId});

  @override
  State<PerfilPacienteScreen> createState() => _PerfilPacienteScreenState();
}

class _PerfilPacienteScreenState extends State<PerfilPacienteScreen> {
  final _pacienteRepository = PacienteRepository();
  final _cameraService = CameraService();
  final _imagePicker = ImagePicker();
  
  PacienteModel? _paciente;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final p = await _pacienteRepository.buscarPorId(widget.pacienteId);
      setState(() {
        _paciente = p;
        _carregando = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar paciente: $e');
      setState(() => _carregando = false);
    }
  }

  int _calcularIdade(DateTime nascimento) {
    final hoje = DateTime.now();
    int idade = hoje.year - nascimento.year;
    if (hoje.month < nascimento.month || (hoje.month == nascimento.month && hoje.day < nascimento.day)) {
      idade--;
    }
    return idade;
  }

  String _getIniciais(String nome) {
    final partes = nome.trim().split(' ');
    if (partes.length >= 2) {
      return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase();
    } else if (partes.isNotEmpty && partes[0].isNotEmpty) {
      return partes[0][0].toUpperCase();
    }
    return '?';
  }

  Future<void> _escolherOrigemFoto() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Tirar Foto'),
              onTap: () {
                Navigator.pop(context);
                _tirarFoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Escolher da Galeria'),
              onTap: () {
                Navigator.pop(context);
                _escolherDaGaleria();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tirarFoto() async {
    final foto = await _cameraService.fotografarDocumento();
    if (foto != null) {
      _atualizarFoto(foto.path);
    }
  }

  Future<void> _escolherDaGaleria() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      _atualizarFoto(image.path);
    }
  }

  Future<void> _atualizarFoto(String path) async {
    if (_paciente == null) return;
    
    final novoPaciente = _paciente!.copyWith(fotoPath: path);
    try {
      await _pacienteRepository.atualizar(novoPaciente);
      setState(() {
        _paciente = novoPaciente;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada com sucesso!'), backgroundColor: AppColors.secondary),
        );
      }
    } catch (e) {
      debugPrint('Erro ao salvar foto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_paciente == null) {
      return const Scaffold(body: Center(child: Text('Erro ao carregar dados do paciente.')));
    }

    final idade = _calcularIdade(_paciente!.dataNascimento);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Paciente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar e Foto
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A56DB), // Azul Safira
                    image: _paciente!.fotoPath != null
                        ? DecorationImage(
                            image: FileImage(File(_paciente!.fotoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _paciente!.fotoPath == null
                      ? Center(
                          child: Text(
                            _getIniciais(_paciente!.nome),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _escolherOrigemFoto,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _paciente!.nome,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text('ID: ${_paciente!.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$idade anos • ${_paciente!.telefone}'),
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
                    onPressed: () => context.push('/anamnese/clinica/${widget.pacienteId}'),
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
                    onPressed: () => context.push('/atendimento/novo/${widget.pacienteId}'),
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
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Últimos Atendimentos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<AtendimentoModel>>(
              future: AtendimentoRepository().buscarPorPaciente(widget.pacienteId),
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
                      onTap: () => context.push('/pacientes/${widget.pacienteId}/historico'),
                    )),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.push('/pacientes/${widget.pacienteId}/historico'),
                        child: const Text('Ver Histórico Completo'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
