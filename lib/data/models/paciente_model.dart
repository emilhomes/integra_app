class PacienteModel {
  final String id;
  final String nome;
  final String cpf;
  final DateTime dataNascimento;
  final String telefone;
  final String endereco;
  final String? fotoPath;

  const PacienteModel({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.dataNascimento,
    required this.telefone,
    required this.endereco,
    this.fotoPath,
  });

  int get idade {
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;
    if (hoje.month < dataNascimento.month || (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }
    return idade;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cpf': cpf,
      'dataNascimento': dataNascimento,
      'telefone': telefone,
      'endereco': endereco,
      'fotoPath': fotoPath,
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
      fotoPath: map['fotoPath'],
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

  PacienteModel copyWith({
    String? id,
    String? nome,
    String? cpf,
    DateTime? dataNascimento,
    String? telefone,
    String? endereco,
    String? fotoPath,
  }) {
    return PacienteModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cpf: cpf ?? this.cpf,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      fotoPath: fotoPath ?? this.fotoPath,
    );
  }
}
