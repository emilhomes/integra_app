import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/atendimento_model.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/dashboard/dashboard_screen.dart';
import '../presentation/pacientes/lista_pacientes_screen.dart';
import '../presentation/pacientes/cadastro_paciente_screen.dart';
import '../presentation/pacientes/perfil_paciente_screen.dart';
import '../presentation/pacientes/historico_paciente_screen.dart';
import '../presentation/pacientes/analise_paciente_screen.dart';
import '../presentation/atendimento/registro_atendimento_screen.dart';
import '../presentation/atendimento/anamnese_clinica_screen.dart';
import '../presentation/atendimento/anamnese_fisica_screen.dart';
import '../presentation/atendimento/anamnese_social_screen.dart';
import '../presentation/relatorios/relatorio_clinico_screen.dart';
import '../presentation/relatorios/relatorio_estagio_screen.dart';
import '../presentation/agenda/agenda_screen.dart';
import '../presentation/agenda/novo_agendamento_screen.dart';
import '../presentation/atendimento/assinatura_screen.dart';
import '../presentation/relatorios/mapa_atendimentos_screen.dart';
import '../presentation/assistente/assistente_screen.dart';
import '../presentation/shared/scaffold_with_navbar.dart';
import '../core/services/auth_service.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String pacientes = '/pacientes';
  static const String pacientesCadastro = '/pacientes/cadastro';
  static const String pacientesPerfil = '/pacientes/:id/perfil';
  static const String pacientesHistorico = '/pacientes/:id/historico';
  static const String atendimentoNovo = '/atendimento/novo/:pacienteId';
  static const String atendimentoAssinatura = '/atendimento/assinatura/:id';
  static const String agenda = '/agenda';
  static const String assistente = '/assistente';
  static const String agendaNovo = '/agenda/novo';
  static const String agendaEditar = '/agenda/editar/:agendamentoId';
  static const String relatoriosMapa = '/relatorios/mapa';
  static const String anamneseClinica = '/anamnese/clinica/:pacienteId';
  static const String anamneseFisica = '/anamnese/fisica/:pacienteId';
  static const String anamneseSocial = '/anamnese/social/:pacienteId';
  static const String relatoriosClinico = '/relatorios/clinico';
  static const String relatoriosEstagio = '/relatorios/estagio';

  static final router = GoRouter(
    initialLocation: login,
    refreshListenable: GoRouterRefreshStream(AuthService().userStateStream),
    redirect: (context, state) {
      final auth = AuthService();
      final user = auth.usuarioAtual;
      final isLoggingIn = state.matchedLocation == login;

      if (user == null) {
        return isLoggingIn ? null : login;
      }

      if (isLoggingIn) {
        return dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => login,
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      // SHELL ROUTE PARA TELAS COM NAVBAR
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavbar(child: child),
        routes: [
          GoRoute(
            path: dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: pacientes,
            name: 'pacientes',
            builder: (context, state) {
              final modo = state.uri.queryParameters['modo'];
              return ListaPacientesScreen(modo: modo);
            },
          ),
          GoRoute(
            path: agenda,
            name: 'agenda',
            builder: (context, state) => const AgendaScreen(),
          ),
          GoRoute(
            path: assistente,
            name: 'assistente',
            builder: (context, state) => const AssistenteScreen(),
          ),
          GoRoute(
            path: relatoriosClinico,
            name: 'relatoriosClinico',
            builder: (context, state) => const RelatorioClinicoScreen(),
            redirect: (context, state) async {
              final auth = AuthService();
              final isProf = await auth.isProfissional();
              if (!isProf) {
                return '/dashboard?erro=acesso_negado';
              }
              return null;
            },
          ),
        ],
      ),
      // ROTAS FORA DO SHELL (SEM NAVBAR)
      GoRoute(
        path: pacientesCadastro,
        name: 'pacientesCadastro',
        builder: (context, state) => const CadastroPacienteScreen(),
      ),
      GoRoute(
        path: pacientesPerfil,
        name: 'pacientesPerfil',
        builder: (context, state) => PerfilPacienteScreen(
          pacienteId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: pacientesHistorico,
        name: 'pacientesHistorico',
        builder: (context, state) => HistoricoPacienteScreen(
          pacienteId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: atendimentoNovo,
        name: 'atendimentoNovo',
        builder: (context, state) {
          final pacienteId = state.pathParameters['pacienteId']!;
          final agendamentoId = state.uri.queryParameters['agendamentoId'];
          return RegistroAtendimentoScreen(
            pacienteId: pacienteId,
            agendamentoId: agendamentoId,
          );
        },
      ),
      GoRoute(
        path: anamneseClinica,
        name: 'anamneseClinica',
        builder: (context, state) => AnamneseClinicaScreen(
          pacienteId: state.pathParameters['pacienteId']!,
        ),
      ),
      GoRoute(
        path: anamneseFisica,
        name: 'anamneseFisica',
        builder: (context, state) => AnamneseFisicaScreen(
          pacienteId: state.pathParameters['pacienteId']!,
          pontosIniciais: state.extra as List<Map<String, dynamic>>?,
        ),
      ),
      GoRoute(
        path: anamneseSocial,
        name: 'anamneseSocial',
        builder: (context, state) => AnamneseSocialScreen(
          pacienteId: state.pathParameters['pacienteId']!,
        ),
      ),
      GoRoute(
        path: '/pacientes/:id/analise',
        name: 'pacientesAnalise',
        builder: (context, state) => AnalisePacienteScreen(
          pacienteId: state.pathParameters['id']!,
          atendimentos: state.extra as List<AtendimentoModel>,
        ),
      ),
      GoRoute(
        path: relatoriosEstagio,
        name: 'relatoriosEstagio',
        builder: (context, state) => const RelatorioEstagioScreen(),
      ),
      GoRoute(
        path: agendaNovo,
        name: 'agendaNovo',
        builder: (context, state) => const NovoAgendamentoScreen(),
      ),
      GoRoute(
        path: agendaEditar,
        name: 'agendaEditar',
        builder: (context, state) {
          final id = state.pathParameters['agendamentoId'];
          return NovoAgendamentoScreen(agendamentoId: id);
        },
      ),
      GoRoute(
        path: atendimentoAssinatura,
        name: 'atendimentoAssinatura',
        builder: (context, state) => AssinaturaScreen(
          atendimentoId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: relatoriosMapa,
        name: 'relatoriosMapa',
        builder: (context, state) => const MapaAtendimentosScreen(),
      ),
    ],
  );
}
