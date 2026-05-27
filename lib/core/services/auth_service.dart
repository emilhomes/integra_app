import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/usuario_model.dart';

/// ADMINISTRAÇÃO DE USUÁRIOS NO FIREBASE:
/// 1. Crie o usuário no Firebase Auth (E-mail/Senha).
/// 2. Crie um documento na coleção 'usuarios' no Firestore com o ID igual ao UID do Auth.
/// 3. Campos obrigatórios no documento:
///    - id: (String) UID do usuário
///    - nome: (String) Nome completo
///    - email: (String) E-mail do usuário
///    - perfilAcesso: (String) 'profissional' ou 'estagiario'
/// 4. Por padrão, novos logins criam perfil 'estagiario' se o documento não existir.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter para o usuário atual
  User? get usuarioAtual => _auth.currentUser;

  // Stream para monitorar o estado da autenticação
  Stream<User?> get userStateStream => _auth.authStateChanges();

  // Login com e-mail e senha
  Future<UserCredential?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _garantirDocumentoUsuario(credential.user!);
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Garante que o usuário tenha um documento no Firestore
  Future<void> _garantirDocumentoUsuario(User user) async {
    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    if (!doc.exists) {
      final novoUsuario = UsuarioModel(
        id: user.uid,
        nome: user.displayName ?? user.email?.split('@').first ?? 'Usuário',
        email: user.email ?? '',
        perfilAcesso: 'estagiario',
      );
      await _firestore.collection('usuarios').doc(user.uid).set(novoUsuario.toMap());
    }
  }

  // Busca o perfil completo do usuário no Firestore
  Future<UsuarioModel?> buscarPerfilUsuario() async {
    final user = usuarioAtual;
    if (user == null) return null;

    debugPrint('DEBUG AUTH: Buscando perfil para UID: ${user.uid}');
    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      debugPrint('DEBUG AUTH: Perfil encontrado: ${doc.data()}');
      return UsuarioModel.fromMap(doc.data()!);
    }
    debugPrint('DEBUG AUTH: Perfil NÃO encontrado no Firestore');
    return null;
  }

  // Verifica se o usuário é profissional
  Future<bool> isProfissional() async {
    final perfil = await buscarPerfilUsuario();
    return perfil?.perfilAcesso == 'profissional';
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
