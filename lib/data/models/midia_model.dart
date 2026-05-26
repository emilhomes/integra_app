class MidiaModel {
  final String id;
  final String atendimentoId;
  final String caminhoArquivo; // Pode ser URL remota ou caminho local
  final String tipo; // ex: 'receita', 'atestado'

  const MidiaModel({
    required this.id,
    required this.atendimentoId,
    required this.caminhoArquivo,
    required this.tipo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'atendimentoId': atendimentoId,
      'caminhoArquivo': caminhoArquivo,
      'tipo': tipo,
    };
  }

  factory MidiaModel.fromMap(Map<String, dynamic> map) {
    return MidiaModel(
      id: map['id'] ?? '',
      atendimentoId: map['atendimentoId'] ?? '',
      caminhoArquivo: map['caminhoArquivo'] ?? map['url'] ?? '', // Suporta legado 'url'
      tipo: map['tipo'] ?? '',
    );
  }
}
