class PacienteModel {
  final String id;
  final String nome;
  final String cpf;
  final DateTime dataNascimento;
  final String telefone;
  final String endereco;
  final String? fotoPath;

  // Campos de Anamnese Clínica (Persistentes)
  final String? historicoDoencas;
  final String? medicamentosEmUso;
  final String? alergias;
  final String? antecedentesFamiliares;

  // Campos de Anamnese Social (Persistentes)
  final String? moradia;
  final bool? temSaneamento;
  final String? numResidentes;
  final String? estadoCivil;
  final String? rendaFamiliar;
  final String? acessoSaude;

  const PacienteModel({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.dataNascimento,
    required this.telefone,
    required this.endereco,
    this.fotoPath,
    this.historicoDoencas,
    this.medicamentosEmUso,
    this.alergias,
    this.antecedentesFamiliares,
    this.moradia,
    this.temSaneamento,
    this.numResidentes,
    this.estadoCivil,
    this.rendaFamiliar,
    this.acessoSaude,
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
      'historicoDoencas': historicoDoencas,
      'medicamentosEmUso': medicamentosEmUso,
      'alergias': alergias,
      'antecedentesFamiliares': antecedentesFamiliares,
      'moradia': moradia,
      'temSaneamento': temSaneamento,
      'numResidentes': numResidentes,
      'estadoCivil': estadoCivil,
      'rendaFamiliar': rendaFamiliar,
      'acessoSaude': acessoSaude,
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
      historicoDoencas: map['historicoDoencas'],
      medicamentosEmUso: map['medicamentosEmUso'],
      alergias: map['alergias'],
      antecedentesFamiliares: map['antecedentesFamiliares'],
      moradia: map['moradia'],
      temSaneamento: map['temSaneamento'],
      numResidentes: map['numResidentes'],
      estadoCivil: map['estadoCivil'],
      rendaFamiliar: map['rendaFamiliar'],
      acessoSaude: map['acessoSaude'],
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

  PacienteModel copyWith({
    String? id,
    String? nome,
    String? cpf,
    DateTime? dataNascimento,
    String? telefone,
    String? endereco,
    String? fotoPath,
    String? historicoDoencas,
    String? medicamentosEmUso,
    String? alergias,
    String? antecedentesFamiliares,
    String? moradia,
    bool? temSaneamento,
    String? numResidentes,
    String? estadoCivil,
    String? rendaFamiliar,
    String? acessoSaude,
  }) {
    return PacienteModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cpf: cpf ?? this.cpf,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      telefone: telefone ?? this.telefone,
      endereco: endereco ?? this.endereco,
      fotoPath: fotoPath ?? this.fotoPath,
      historicoDoencas: historicoDoencas ?? this.historicoDoencas,
      medicamentosEmUso: medicamentosEmUso ?? this.medicamentosEmUso,
      alergias: alergias ?? this.alergias,
      antecedentesFamiliares: antecedentesFamiliares ?? this.antecedentesFamiliares,
      moradia: moradia ?? this.moradia,
      temSaneamento: temSaneamento ?? this.temSaneamento,
      numResidentes: numResidentes ?? this.numResidentes,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      rendaFamiliar: rendaFamiliar ?? this.rendaFamiliar,
      acessoSaude: acessoSaude ?? this.acessoSaude,
    );
  }
}
