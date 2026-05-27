import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/agendamento_model.dart';
import '../../data/models/paciente_model.dart';
import '../../data/repositories/agendamento_repository.dart';
import '../../data/repositories/paciente_repository.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  const NovoAgendamentoScreen({super.key});

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  final _agendamentoRepository = AgendamentoRepository();
  final _pacienteRepository = PacienteRepository();
  final _obsController = TextEditingController();

  PacienteModel? _pacienteSelecionado;
  DateTime _dataSelecionada = DateTime.now();
  TimeOfDay _horaSelecionada = TimeOfDay.now();
  
  final List<String> _terapiasDisponiveis = [
    'Acupuntura', 'Massagem', 'Ventosaterapia', 'Aromaterapia', 'Reiki'
  ];
  String? _terapiaSelecionada;

  List<PacienteModel> _todosPacientes = [];
  List<PacienteModel> _pacientesFiltrados = [];
  bool _carregandoPacientes = false;

  @override
  void initState() {
    super.initState();
    _carregarPacientes();
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _carregarPacientes() async {
    setState(() => _carregandoPacientes = true);
    try {
      _todosPacientes = await _pacienteRepository.buscarTodos();
      setState(() {
        _pacientesFiltrados = _todosPacientes;
        _carregandoPacientes = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar pacientes: $e');
      setState(() => _carregandoPacientes = false);
    }
  }

  void _filtrarPacientes(String query) {
    setState(() {
      _pacientesFiltrados = _todosPacientes
          .where((p) => p.nome.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() => _dataSelecionada = picked);
    }
  }

  Future<void> _selecionarHora(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada,
    );
    if (picked != null && picked != _horaSelecionada) {
      setState(() => _horaSelecionada = picked);
    }
  }

  Future<void> _salvar() async {
    if (_pacienteSelecionado == null || _terapiaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o paciente e a terapia')),
      );
      return;
    }

    final usuario = AuthService().usuarioAtual;
    if (usuario == null) return;

    final dataHora = DateTime(
      _dataSelecionada.year,
      _dataSelecionada.month,
      _dataSelecionada.day,
      _horaSelecionada.hour,
      _horaSelecionada.minute,
    );

    final novoAgendamento = AgendamentoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pacienteId: _pacienteSelecionado!.id,
      pacienteNome: _pacienteSelecionado!.nome,
      profissionalId: usuario.uid,
      dataHora: dataHora,
      tipoTerapia: _terapiaSelecionada!,
      observacoes: _obsController.text,
    );

    try {
      await _agendamentoRepository.salvar(novoAgendamento);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento realizado com sucesso!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Agendamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paciente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SearchAnchor(
              builder: (context, controller) {
                return SearchBar(
                  controller: controller,
                  hintText: _pacienteSelecionado?.nome ?? 'Buscar paciente...',
                  onChanged: _filtrarPacientes,
                  onTap: () => controller.openView(),
                  leading: const Icon(Icons.search),
                );
              },
              suggestionsBuilder: (context, controller) {
                if (_carregandoPacientes) return [const Center(child: CircularProgressIndicator())];
                return _pacientesFiltrados.map((p) => ListTile(
                  title: Text(p.nome),
                  subtitle: Text('ID: ${p.id}'),
                  onTap: () {
                    setState(() => _pacienteSelecionado = p);
                    controller.closeView(p.nome);
                  },
                )).toList();
              },
            ),
            const SizedBox(height: 24),
            
            const Text('Data e Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selecionarData(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('dd/MM/yyyy').format(_dataSelecionada)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selecionarHora(context),
                    icon: const Icon(Icons.access_time),
                    label: Text(_horaSelecionada.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Tipo de Terapia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _terapiasDisponiveis.map((terapia) {
                final isSelected = _terapiaSelecionada == terapia;
                return ChoiceChip(
                  label: Text(terapia),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _terapiaSelecionada = selected ? terapia : null);
                  },
                  selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text('Observações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _obsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Alguma observação importante...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirmar Agendamento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
