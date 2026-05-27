import 'package:go_router/go_router.dart';
// Importações das telas (placeholders por enquanto)
import '../presentation/auth/login_screen.dart';
import '../presentation/dashboard/dashboard_screen.dart';
import '../presentation/pacientes/lista_pacientes_screen.dart';
import '../presentation/pacientes/cadastro_paciente_screen.dart';
import '../presentation/pacientes/perfil_paciente_screen.dart';
import '../presentation/pacientes/historico_paciente_screen.dart';
import '../presentation/atendimento/registro_atendimento_screen.dart';
import '../presentation/atendimento/anamnese_clinica_screen.dart';
import '../presentation/atendimento/anamnese_fisica_screen.dart';
import '../presentation/atendimento/anamnese_social_screen.dart';
import '../presentation/relatorios/relatorio_clinico_screen.dart';
import '../presentation/relatorios/relatorio_estagio_screen.dart';
import '../presentation/agenda/agenda_screen.dart';
import '../presentation/agenda/novo_agendamento_screen.dart';
import '../core/services/auth_service.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String pacientes = '/pacientes';
  static const String pacientesCadastro = '/pacientes/cadastro';
  static const String pacientesHistorico = '/pacientes/:id/historico';
  static const String atendimentoNovo = '/atendimento/novo';
  static const String agenda = '/agenda';
  static const String agendaNovo = '/agenda/novo';
  static const String anamneseClinica = '/anamnese/clinica';
  static const String anamneseFisica = '/anamnese/fisica';
  static const String anamneseSocial = '/anamnese/social';
  static const String relatoriosClinico = '/relatorios/clinico';
  static const String relatoriosEstagio = '/relatorios/estagio';

  static final router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
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
        routes: [
          GoRoute(
            path: 'cadastro',
            name: 'pacientesCadastro',
            builder: (context, state) => const CadastroPacienteScreen(),
          ),
          GoRoute(
            path: ':id/perfil',
            name: 'pacientesPerfil',
            builder: (context, state) => PerfilPacienteScreen(
              pacienteId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: ':id/historico',
            name: 'pacientesHistorico',
            builder: (context, state) => HistoricoPacienteScreen(
              pacienteId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/atendimento/novo/:pacienteId',
        name: 'atendimentoNovo',
        builder: (context, state) => RegistroAtendimentoScreen(
          pacienteId: state.pathParameters['pacienteId']!,
        ),
      ),
      GoRoute(
        path: '/anamnese/clinica/:pacienteId',
        name: 'anamneseClinica',
        builder: (context, state) => AnamneseClinicaScreen(
          pacienteId: state.pathParameters['pacienteId']!,
        ),
      ),
      GoRoute(
        path: '/anamnese/fisica/:pacienteId',
        name: 'anamneseFisica',
        builder: (context, state) => AnamneseFisicaScreen(
          pacienteId: state.pathParameters['pacienteId']!,
        ),
      ),
      GoRoute(
        path: '/anamnese/social/:pacienteId',
        name: 'anamneseSocial',
        builder: (context, state) => AnamneseSocialScreen(
          pacienteId: state.pathParameters['pacienteId']!,
        ),
      ),
      GoRoute(
        path: '/relatorios/clinico',
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
      GoRoute(
        path: '/relatorios/estagio',
        name: 'relatoriosEstagio',
        builder: (context, state) => const RelatorioEstagioScreen(),
      ),
      GoRoute(
        path: agenda,
        name: 'agenda',
        builder: (context, state) => const AgendaScreen(),
      ),
      GoRoute(
        path: agendaNovo,
        name: 'agendaNovo',
        builder: (context, state) => const NovoAgendamentoScreen(),
      ),
    ],
  );
}
