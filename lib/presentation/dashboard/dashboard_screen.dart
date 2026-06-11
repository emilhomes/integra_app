import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notificacao_service.dart';

import '../../data/models/usuario_model.dart';
import '../../data/models/agendamento_model.dart';
import '../../data/repositories/agendamento_repository.dart';
import '../../core/services/conectividade_service.dart';
import '../../core/constants/app_colors.dart';
import '../shared/shimmer_loading.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _agendamentoRepository = AgendamentoRepository();
  final _authService = AuthService();
  final _conectividadeService = ConectividadeService();
  
  bool _carregando = true;
  int _totalHoje = 0;
  int _pendentesHoje = 0;
  List<AgendamentoModel> _agendamentosHoje = [];
  bool _isProfissional = false;
  bool _estaOnline = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _verificarErroAcesso();
    _monitorarConexao();
  }

  void _monitorarConexao() {
    _conectividadeService.monitorarConexao().listen((online) {
      if (mounted) {
        setState(() => _estaOnline = online);
      }
    });
  }

  void _verificarErroAcesso() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      if (uri.queryParameters['erro'] == 'acesso_negado') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acesso negado: restrito a Profissionais/Supervisores', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFFE02424),
          ),
        );
      }
    });
  }

  Future<void> _carregarDados() async {
    final usuario = _authService.usuarioAtual;
    if (usuario == null) return;

    setState(() => _carregando = true);
    
    try {
      final Future<UsuarioModel?> perfilFuture = _authService.buscarPerfilUsuario().catchError((e) {
        debugPrint('Erro ao buscar perfil: $e');
        return null;
      });

      final Future<List<AgendamentoModel>> hojeFuture = _agendamentoRepository.buscarHoje(usuario.uid).catchError((e) {
        debugPrint('Erro ao buscar agendamentos de hoje: $e');
        return <AgendamentoModel>[];
      });

      final results = await Future.wait([
        perfilFuture,
        hojeFuture,
      ]);

      final perfil = results[0] as UsuarioModel?;
      final agendamentos = results[1] as List<AgendamentoModel>;

      if (mounted) {
        setState(() {
          _isProfissional = perfil?.perfilAcesso == 'profissional';
          _agendamentosHoje = agendamentos;
          _totalHoje = agendamentos.length;
          _pendentesHoje = agendamentos.where((a) => a.status == AgendamentoStatus.agendado).length;
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint('Erro crítico no carregamento do dashboard: $e');
      if (mounted) setState(() => _carregando = false);
    }
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

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia,';
    if (hora < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  String _formatarNome(String nome) {
    if (nome.isEmpty) return 'Profissional';
    final formatado = nome[0].toUpperCase() + nome.substring(1);
    return formatado.startsWith('Dr') ? formatado : 'Dr. $formatado';
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _authService.usuarioAtual;
    final nomeBruto = usuario?.displayName ?? usuario?.email?.split('@').first ?? 'Profissional';
    final nomeExibicao = _formatarNome(nomeBruto);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // HEADER MODERNO
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSaudacao(),
                          style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
                        ),
                        Text(
                          nomeExibicao,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Perfil ou Configurações
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                _getIniciais(nomeBruto),
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                          onPressed: () async {
                            await _authService.logout();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                if (!_estaOnline) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Modo Offline',
                          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Centraliza conteúdo da coluna
                children: [
                  const SizedBox(height: 24),
                  
                  // CARDS DE RESUMO (ESTILO NUBANK)
                  Row(
                    children: [
                      _buildSummaryCard(
                        title: 'Atendimentos',
                        value: _totalHoje.toString(),
                        icon: Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        isLoading: _carregando,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        title: 'Restantes',
                        value: _pendentesHoje.toString(),
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.secondary,
                        isLoading: _carregando,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Acesso Rápido',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildQuickAccessRow(),

                  const SizedBox(height: 16),
                  // TODO: remover antes da entrega
                  ElevatedButton.icon(
                    onPressed: () => NotificacaoService.testarNotificacao(),
                    icon: const Icon(Icons.notification_important_rounded),
                    label: const Text('Testar Notificação'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.secondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Agenda de Hoje',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      TextButton(
                        onPressed: () => context.go('/agenda'),
                        child: Text('Ver Tudo', style: GoogleFonts.outfit(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildTodaySchedule(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            isLoading 
              ? const ShimmerLoading(width: 40, height: 32)
              : Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: color)),
            Text(title, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessRow() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildQuickCircle(
              onTap: () => context.go('/pacientes?modo=atendimento'),
              icon: Icons.add_task_rounded,
              label: 'Novo Atend.',
              color: AppColors.primary,
            ),
            _buildQuickCircle(
              onTap: () => context.push('/pacientes'),
              icon: Icons.people_alt_rounded,
              label: 'Pacientes',
              color: AppColors.secondary,
            ),
            if (_isProfissional)
              _buildQuickCircle(
                onTap: () => context.push('/relatorios/clinico'),
                icon: Icons.analytics_rounded,
                label: 'Relatórios',
                color: Colors.orange,
              ),
            _buildQuickCircle(
              onTap: () => context.go('/agenda'),
              icon: Icons.event_note_rounded,
              label: 'Agenda',
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCircle({required VoidCallback onTap, required IconData icon, required String label, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10), // Espaçamento simétrico para centralizar
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    if (_carregando) {
      return const ShimmerLoading(width: double.infinity, height: 100);
    }

    if (_agendamentosHoje.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(Icons.event_available_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tudo limpo por aqui!',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[600]),
            ),
            Text(
              'Você não tem agendamentos hoje.',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _agendamentosHoje.take(3).map((a) => _buildScheduleTile(a)).toList(),
    );
  }

  Widget _buildScheduleTile(AgendamentoModel agendamento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              DateFormat('HH:mm').format(agendamento.dataHora),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agendamento.pacienteNome,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary),
                ),
                Text(
                  agendamento.tipoTerapia,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (agendamento.status == AgendamentoStatus.agendado)
            IconButton(
              onPressed: () => context.push('/atendimento/novo/${agendamento.pacienteId}'),
              icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.secondary),
              style: IconButton.styleFrom(backgroundColor: AppColors.secondary.withValues(alpha: 0.1)),
            ),
        ],
      ),
    );
  }
}
