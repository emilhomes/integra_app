import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/agendamento_model.dart';
import '../../data/repositories/agendamento_repository.dart';
import '../../core/services/notificacao_service.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _agendamentoRepository = AgendamentoRepository();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<AgendamentoModel> _todosAgendamentos = [];
  bool _carregando = false;
  bool _verRealizados = false;

  List<AgendamentoModel> get _agendamentosFiltrados {
    if (_verRealizados) return _todosAgendamentos;
    return _todosAgendamentos
        .where((a) => a.status != AgendamentoStatus.realizado)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarAgendamentos(_selectedDay!);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedDay != null) {
      _carregarAgendamentos(_selectedDay!);
    }
  }

  Future<void> _carregarAgendamentos(DateTime dia) async {
    final usuario = AuthService().usuarioAtual;
    if (usuario == null) return;

    setState(() => _carregando = true);
    try {
      final agendamentos = await _agendamentoRepository.buscarPorDia(
        usuario.uid, 
        dia,
      );
      if (mounted) {
        setState(() {
          _todosAgendamentos = agendamentos;
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar agendamentos: $e');
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _excluirAgendamento(AgendamentoModel agendamento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Agendamento', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja excluir o agendamento de ${agendamento.pacienteNome}?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Excluir', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _agendamentoRepository.excluir(agendamento.id);
        await NotificacaoService.cancelarNotificacao(agendamento.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Agendamento excluído com sucesso'), backgroundColor: AppColors.secondary),
          );
          _carregarAgendamentos(_selectedDay!);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Minha Agenda', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _carregarAgendamentos(selectedDay);
                }
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                markerDecoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                defaultTextStyle: GoogleFonts.outfit(),
                weekendTextStyle: GoogleFonts.outfit(color: Colors.redAccent),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary),
                leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.w600),
                weekendStyle: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDay == null ? 'Próximos compromissos' : 'Agenda de ${DateFormat('dd/MM').format(_selectedDay!)}',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _verRealizados = !_verRealizados);
                        },
                        icon: Icon(
                          _verRealizados ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        label: Text(
                          _verRealizados ? 'Esconder realizados' : 'Ver realizados',
                          style: GoogleFonts.outfit(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: _carregando
                        ? const Center(child: CircularProgressIndicator())
                        : _agendamentosFiltrados.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: _agendamentosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final agendamento = _agendamentosFiltrados[index];
                                  return _buildAgendamentoCard(agendamento);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/agenda/novo');
          if (result == true) _carregarAgendamentos(_selectedDay!);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Agendar', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhum agendamento',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
          Text(
            'para este dia.',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendamentoCard(AgendamentoModel agendamento) {
    final isRealizado = agendamento.status == AgendamentoStatus.realizado;
    Color statusColor;
    
    switch (agendamento.status) {
      case AgendamentoStatus.agendado: statusColor = AppColors.primary; break;
      case AgendamentoStatus.realizado: statusColor = Colors.green; break;
      case AgendamentoStatus.cancelado: statusColor = Colors.red; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isRealizado ? Colors.grey : statusColor).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(agendamento.dataHora),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800, 
                      color: isRealizado ? Colors.grey : statusColor, 
                      fontSize: 16
                    ),
                  ),
                ],
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    agendamento.pacienteNome,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, 
                      fontSize: 17, 
                      color: isRealizado ? Colors.grey : AppColors.primary
                    ),
                  ),
                ),
                if (isRealizado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Concluído',
                      style: GoogleFonts.outfit(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.green
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              agendamento.tipoTerapia,
              style: GoogleFonts.outfit(
                fontSize: 13, 
                color: isRealizado ? Colors.grey[400] : Colors.grey[600]
              ),
            ),
            trailing: isRealizado ? null : PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) async {
                if (value == 'editar') {
                  final result = await context.push('/agenda/editar/${agendamento.id}');
                  if (result == true) _carregarAgendamentos(_selectedDay!);
                } else if (value == 'excluir') {
                  _excluirAgendamento(agendamento);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'editar', child: Row(children: [const Icon(Icons.edit_outlined, size: 20), const SizedBox(width: 8), Text('Editar', style: GoogleFonts.outfit())])),
                PopupMenuItem(value: 'excluir', child: Row(children: [const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red), const SizedBox(width: 8), Text('Excluir', style: GoogleFonts.outfit(color: Colors.red))])),
              ],
            ),
          ),
          if (agendamento.status == AgendamentoStatus.agendado)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.push(
                      '/atendimento/novo/${agendamento.pacienteId}?agendamentoId=${agendamento.id}',
                    );
                    _carregarAgendamentos(_selectedDay!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Iniciar Atendimento', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
