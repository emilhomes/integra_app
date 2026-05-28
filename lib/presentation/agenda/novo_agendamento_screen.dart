import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/agendamento_model.dart';
import '../../data/models/paciente_model.dart';
import '../../data/repositories/agendamento_repository.dart';
import '../../data/repositories/paciente_repository.dart';
import '../../core/services/notificacao_service.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  final String? agendamentoId;
  const NovoAgendamentoScreen({super.key, this.agendamentoId});

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  final _agendamentoRepository = AgendamentoRepository();
  final _pacienteRepository = PacienteRepository();
  final _obsController = TextEditingController();

  AgendamentoModel? _agendamentoParaEditar;
  PacienteModel? _pacienteSelecionado;
  // Fallback name/id if the full model isn't loaded yet during edit
  String? _pacienteNomeManual;
  String? _pacienteIdManual;

  DateTime _dataSelecionada = DateTime.now();
  TimeOfDay _horaSelecionada = TimeOfDay.now();
  
  final List<String> _terapiasDisponiveis = [
    'Acupuntura', 'Massagem', 'Ventosaterapia', 'Aromaterapia', 'Reiki'
  ];
  String? _terapiaSelecionada;

  List<PacienteModel> _todosPacientes = [];
  List<PacienteModel> _pacientesFiltrados = [];
  bool _carregandoPacientes = false;
  bool _carregandoAgendamento = false;

  @override
  void initState() {
    super.initState();
    _carregarPacientes();
    if (widget.agendamentoId != null) {
      _carregarAgendamentoParaEdicao();
    }
  }

  Future<void> _carregarAgendamentoParaEdicao() async {
    setState(() => _carregandoAgendamento = true);
    try {
      final a = await _agendamentoRepository.buscarPorId(widget.agendamentoId!);
      if (a != null && mounted) {
        setState(() {
          _agendamentoParaEditar = a;
          _dataSelecionada = a.dataHora;
          _horaSelecionada = TimeOfDay.fromDateTime(a.dataHora);
          _terapiaSelecionada = a.tipoTerapia;
          _obsController.text = a.observacoes;
          _pacienteNomeManual = a.pacienteNome;
          _pacienteIdManual = a.pacienteId;
          
          // Tenta vincular o paciente se a lista já carregou
          if (_todosPacientes.isNotEmpty) {
            try {
              _pacienteSelecionado = _todosPacientes.firstWhere((p) => p.id == a.pacienteId);
            } catch (_) {}
          }
          _carregandoAgendamento = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar agendamento para edição: $e');
      if (mounted) setState(() => _carregandoAgendamento = false);
    }
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
        
        // Se estiver editando e o agendamento já carregou, vincula o paciente
        if (_agendamentoParaEditar != null) {
          try {
            _pacienteSelecionado = _todosPacientes.firstWhere(
              (p) => p.id == _agendamentoParaEditar!.pacienteId
            );
          } catch (_) {}
        }
        
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
      firstDate: DateTime.now().isBefore(_dataSelecionada) ? DateTime.now() : _dataSelecionada,
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
    final pId = _pacienteSelecionado?.id ?? _pacienteIdManual;
    final pNome = _pacienteSelecionado?.nome ?? _pacienteNomeManual;

    if (pId == null || pNome == null || _terapiaSelecionada == null) {
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
      id: _agendamentoParaEditar?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      pacienteId: pId,
      pacienteNome: pNome,
      profissionalId: usuario.uid,
      dataHora: dataHora,
      tipoTerapia: _terapiaSelecionada!,
      observacoes: _obsController.text,
      status: _agendamentoParaEditar?.status ?? AgendamentoStatus.agendado,
    );

    try {
      await _agendamentoRepository.salvar(novoAgendamento);
      
      // Agenda/Atualiza notificação local
      await NotificacaoService.agendarNotificacao(novoAgendamento);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_agendamentoParaEditar == null 
              ? 'Agendamento realizado com sucesso!' 
              : 'Agendamento atualizado com sucesso!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        context.pop(true); // Retorna true para indicar que houve mudança
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
    if (_carregandoAgendamento) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pacienteDisplay = _pacienteSelecionado?.nome ?? _pacienteNomeManual ?? 'Buscar paciente...';

    return Scaffold(
      appBar: AppBar(title: Text(_agendamentoParaEditar == null ? 'Novo Agendamento' : 'Editar Agendamento')),
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
                  hintText: pacienteDisplay,
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
                    setState(() {
                      _pacienteSelecionado = p;
                      _pacienteNomeManual = null;
                      _pacienteIdManual = null;
                    });
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
