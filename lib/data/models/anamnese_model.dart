class AnamneseModel {
  final String id;
  final String pacienteId;
  final String queixaPrincipal;
  final String historicoSaude;
  final List<Map<String, dynamic>> pontosMapeamento;
  final String dadosSociais;

  const AnamneseModel({
    required this.id,
    required this.pacienteId,
    required this.queixaPrincipal,
    required this.historicoSaude,
    required this.pontosMapeamento,
    required this.dadosSociais,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pacienteId': pacienteId,
      'queixaPrincipal': queixaPrincipal,
      'historicoSaude': historicoSaude,
      'pontosMapeamento': pontosMapeamento,
      'dadosSociais': dadosSociais,
    };
  }

  factory AnamneseModel.fromMap(Map<String, dynamic> map) {
    return AnamneseModel(
      id: map['id'] ?? '',
      pacienteId: map['pacienteId'] ?? '',
      queixaPrincipal: map['queixaPrincipal'] ?? '',
      historicoSaude: map['historicoSaude'] ?? '',
      pontosMapeamento: List<Map<String, dynamic>>.from(map['pontosMapeamento'] ?? []),
      dadosSociais: map['dadosSociais'] ?? '',
    );
  }
}
