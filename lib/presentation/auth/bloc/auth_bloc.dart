import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';

// Estados
abstract class AuthState {}

class AuthInicial extends AuthState {}

class AuthCarregando extends AuthState {}

class AuthSucesso extends AuthState {
  final User usuario;
  AuthSucesso(this.usuario);
}

class AuthErro extends AuthState {
  final String mensagem;
  AuthErro(this.mensagem);
}

// Eventos
abstract class AuthEvent {}

class AuthLoginSolicitado extends AuthEvent {
  final String email;
  final String senha;
  AuthLoginSolicitado(this.email, this.senha);
}

class AuthLogoutSolicitado extends AuthEvent {}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInicial()) {
    on<AuthLoginSolicitado>((event, emit) async {
      emit(AuthCarregando());
      try {
        final credential = await _authService.login(event.email, event.senha);
        if (credential != null && credential.user != null) {
          emit(AuthSucesso(credential.user!));
        } else {
          emit(AuthErro('Falha na autenticação. Tente novamente.'));
        }
      } catch (e) {
        emit(AuthErro(_formatarErro(e)));
      }
    });

    on<AuthLogoutSolicitado>((event, emit) async {
      await _authService.logout();
      emit(AuthInicial());
    });
  }

  String _formatarErro(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Usuário não encontrado.';
        case 'wrong-password':
          return 'Senha incorreta.';
        case 'invalid-email':
          return 'E-mail inválido.';
        case 'user-disabled':
          return 'Este usuário foi desativado.';
        default:
          return 'Erro na autenticação: ${e.message}';
      }
    }
    return 'Ocorreu um erro inesperado.';
  }
}
