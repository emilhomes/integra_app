import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
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
  List<AgendamentoModel> _agendamentosDoDia = [];
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _carregarAgendamentos(_selectedDay!);
  }

  Future<void> _carregarAgendamentos(DateTime dia) async {
    final usuario = AuthService().usuarioAtual;
    if (usuario == null) return;

    setState(() => _carregando = true);
    try {
      final agendamentos = await _agendamentoRepository.buscarPorDia(usuario.uid, dia);
      if (mounted) {
        setState(() {
          _agendamentosDoDia = agendamentos;
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
        title: const Text('Excluir Agendamento'),
        content: Text('Tem certeza que deseja excluir o agendamento de ${agendamento.pacienteNome}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
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
            const SnackBar(content: Text('Agendamento excluído com sucesso'), backgroundColor: Colors.green),
          );
          _carregarAgendamentos(_selectedDay!);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Agenda'),
      ),
      body: Column(
        children: [
          TableCalendar(
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
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _agendamentosDoDia.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum agendamento para ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _agendamentosDoDia.length,
                        itemBuilder: (context, index) {
                          final agendamento = _agendamentosDoDia[index];
                          return _buildAgendamentoCard(agendamento);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/agenda/novo');
          if (result == true) _carregarAgendamentos(_selectedDay!);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAgendamentoCard(AgendamentoModel agendamento) {
    Color statusColor;
    switch (agendamento.status) {
      case AgendamentoStatus.agendado:
        statusColor = Colors.blue;
        break;
      case AgendamentoStatus.realizado:
        statusColor = Colors.green;
        break;
      case AgendamentoStatus.cancelado:
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(agendamento.dataHora),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agendamento.pacienteNome,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        agendamento.tipoTerapia,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) async {
                        if (value == 'editar') {
                          final result = await context.push('/agenda/editar/${agendamento.id}');
                          if (result == true) _carregarAgendamentos(_selectedDay!);
                        } else if (value == 'excluir') {
                          _excluirAgendamento(agendamento);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'excluir',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Excluir', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        agendamento.status.name.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (agendamento.status == AgendamentoStatus.agendado) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/atendimento/novo/${agendamento.pacienteId}'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar Atendimento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
