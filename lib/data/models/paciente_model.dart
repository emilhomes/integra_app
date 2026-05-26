class PacienteModel {
  final String id;
  final String nome;
  final String cpf;
  final DateTime dataNascimento;
  final String telefone;
  final String endereco;

  const PacienteModel({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.dataNascimento,
    required this.telefone,
    required this.endereco,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cpf': cpf,
      'dataNascimento': dataNascimento,
      'telefone': telefone,
      'endereco': endereco,
    };
  }

  factory PacienteModel.fromMap(Map<String, dynamic> map) {
    return PacienteModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      cpf: map['cpf'] ?? '',
      dataNascimento: _parseDateTime(map['dataNascimento']),
      telefone: map['telefone'] ?? '',
      endereco: map['endereco'] ?? '',
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.parse(value);
    // Generic check for Firestore Timestamp without explicit import if possible,
    // or just assume if it has toDate it's a Timestamp.
    try {
      return value.toDate();
    } catch (_) {
      return DateTime.now();
    }
  }
}
