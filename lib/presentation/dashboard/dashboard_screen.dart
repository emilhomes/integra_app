import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

import '../../data/models/usuario_model.dart';
import '../../data/models/agendamento_model.dart';
import '../../data/repositories/agendamento_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _agendamentoRepository = AgendamentoRepository();
  final _authService = AuthService();
  bool _carregando = true;
  int _totalHoje = 0;
  int _pendentesHoje = 0;
  bool _isProfissional = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _verificarErroAcesso();
  }

  void _verificarErroAcesso() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      if (uri.queryParameters['erro'] == 'acesso_negado') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acesso negado: restrito a Profissionais/Supervisores'),
            backgroundColor: AppColors.error,
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
          debugPrint('DEBUG DASHBOARD: Is Profissional? $_isProfissional');
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

  @override
  Widget build(BuildContext context) {
    final usuario = _authService.usuarioAtual;
    final nomeUsuario = usuario?.displayName ?? usuario?.email?.split('@').first ?? 'Profissional';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ÍNTEGRA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $nomeUsuario!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Cards de Resumo
            Row(
              children: [
                _buildSummaryCard(
                  context,
                  title: 'Agendamentos',
                  value: _totalHoje.toString(),
                  icon: Icons.calendar_today,
                  color: AppColors.primary,
                  isLoading: _carregando,
                  subtitle: _totalHoje == 0 ? 'Nenhum atendimento hoje' : null,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  context,
                  title: 'Pendentes',
                  value: _pendentesHoje.toString(),
                  icon: Icons.pending_actions,
                  color: AppColors.secondary,
                  isLoading: _carregando,
                  subtitle: _pendentesHoje == 0 ? 'Tudo em dia!' : null,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Acesso Rápido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Botões de Acesso Rápido
            _buildQuickAccessButton(
              context,
              label: 'Novo Atendimento',
              icon: Icons.add_circle_outline,
              onTap: () => context.go('/pacientes?modo=atendimento'),
            ),
            _buildQuickAccessButton(
              context,
              label: 'Pacientes',
              icon: Icons.people_outline,
              onTap: () => context.push('/pacientes'),
            ),
            if (_isProfissional)
              _buildQuickAccessButton(
                context,
                label: 'Relatórios',
                icon: Icons.bar_chart_outlined,
                onTap: () => context.push('/relatorios/clinico'),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pacientes'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Agenda'),
          if (_isProfissional)
            const BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Relatórios'),
        ],
        onTap: (index) {
          if (index == 1) context.push('/pacientes');
          if (index == 2) context.push('/agenda');
          if (index == 3 && _isProfissional) context.push('/relatorios/clinico');
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (isLoading)
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isLoading ? '...' : value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8),
              ),
            ),
            if (subtitle != null && !isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton(BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Icon(icon, color: Colors.grey[700]),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
