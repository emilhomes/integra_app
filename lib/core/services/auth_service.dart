import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter para o usuário atual
  User? get usuarioAtual => _auth.currentUser;

  // Stream para monitorar o estado da autenticação
  Stream<User?> get userStateStream => _auth.authStateChanges();

  // Login com e-mail e senha
  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
