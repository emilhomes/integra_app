class RelatorioModel {
  final String id;
  final String tipo;
  final DateTime dataGeracao;
  final String conteudo;

  const RelatorioModel({
    required this.id,
    required this.tipo,
    required this.dataGeracao,
    required this.conteudo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'dataGeracao': dataGeracao,
      'conteudo': conteudo,
    };
  }

  factory RelatorioModel.fromMap(Map<String, dynamic> map) {
    return RelatorioModel(
      id: map['id'] ?? '',
      tipo: map['tipo'] ?? '',
      dataGeracao: _parseDateTime(map['dataGeracao']),
      conteudo: map['conteudo'] ?? '',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.parse(value);
    try {
      return value.toDate();
    } catch (_) {
      return DateTime.now();
    }
  }
}
