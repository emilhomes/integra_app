class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String perfil;

  const UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'perfil': perfil,
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      perfil: map['perfil'] ?? '',
    );
  }
}
