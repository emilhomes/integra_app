class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String perfilAcesso; // 'profissional' ou 'estagiario'

  const UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfilAcesso,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'perfilAcesso': perfilAcesso,
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      perfilAcesso: map['perfilAcesso'] ?? 'estagiario',
    );
  }
}
