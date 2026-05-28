import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';

import '../../data/models/usuario_model.dart';
import '../../data/models/agendamento_model.dart';
import '../../data/repositories/agendamento_repository.dart';
import '../../core/services/conectividade_service.dart';

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
          const SnackBar(
            content: Text('Acesso negado: restrito a Profissionais/Supervisores'),
            backgroundColor: Color(0xFFE02424),
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

      final Future<List<AgendamentoModel>> totalHojeFuture = _agendamentoRepository.buscarHoje(usuario.uid).catchError((e) {
        debugPrint('Erro ao buscar agendamentos de hoje: $e');
        return <AgendamentoModel>[];
      });

      final Future<List<AgendamentoModel>> pendentesHojeFuture = _agendamentoRepository.buscarPendentesHoje(usuario.uid).catchError((e) {
        debugPrint('Erro ao buscar agendamentos pendentes: $e');
        return <AgendamentoModel>[];
      });

      final results = await Future.wait([
        perfilFuture,
        totalHojeFuture,
        pendentesHojeFuture,
      ]);

      final perfil = results[0] as UsuarioModel?;
      final totalHoje = results[1] as List<AgendamentoModel>;
      final pendentesHoje = results[2] as List<AgendamentoModel>;

      if (mounted) {
        setState(() {
          _isProfissional = perfil?.perfilAcesso == 'profissional';
          _totalHoje = totalHoje.length;
          _pendentesHoje = pendentesHoje.length;
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

  @override
  Widget build(BuildContext context) {
    final usuario = _authService.usuarioAtual;
    final nomeExibicao = usuario?.displayName ?? usuario?.email?.split('@').first ?? 'Profissional';
    const primaryColor = Color(0xFF1A56DB);
    const accentColor = Color(0xFF0E9F6E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // HEADER COM GRADIENTE
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A56DB), Color(0xFF1E40AF)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_estaOnline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.amber[800], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Modo offline — dados desatualizados',
                          style: TextStyle(color: Colors.amber[800], fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bom dia,',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                        ),
                        Text(
                          nomeExibicao.startsWith('Dr') ? nomeExibicao : 'Dr. $nomeExibicao',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: Text(
                              _getIniciais(nomeExibicao),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () async {
                            await _authService.logout();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tenha um excelente dia de trabalho',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // CARDS DE RESUMO
                  Row(
                    children: [
                      _buildSummaryCard(
                        context,
                        title: 'Agendamentos',
                        value: _totalHoje.toString(),
                        icon: Icons.calendar_today,
                        color: primaryColor,
                        isLoading: _carregando,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        context,
                        title: 'Pendentes',
                        value: _pendentesHoje.toString(),
                        icon: Icons.assignment_outlined,
                        color: accentColor,
                        isLoading: _carregando,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'Acesso Rápido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // BOTÕES DE ACESSO RÁPIDO
                  _buildQuickAccessCard(
                    context,
                    label: 'Novo Atendimento',
                    subtitle: 'Registrar sessão clínica',
                    icon: Icons.add,
                    color: primaryColor,
                    onTap: () => context.go('/pacientes?modo=atendimento'),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickAccessCard(
                    context,
                    label: 'Pacientes',
                    subtitle: 'Gerenciar prontuários',
                    icon: Icons.people_outline,
                    color: accentColor,
                    onTap: () => context.push('/pacientes'),
                  ),
                  if (_isProfissional) ...[
                    const SizedBox(height: 12),
                    _buildQuickAccessCard(
                      context,
                      label: 'Relatórios',
                      subtitle: 'Análises e exportações',
                      icon: Icons.bar_chart_outlined,
                      color: const Color(0xFF7C3AED),
                      onTap: () => context.push('/relatorios/clinico'),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }
}
