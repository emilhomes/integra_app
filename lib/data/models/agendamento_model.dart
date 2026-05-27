enum AgendamentoStatus { agendado, realizado, cancelado }

class AgendamentoModel {
  final String id;
  final String pacienteId;
  final String pacienteNome;
  final String profissionalId;
  final DateTime dataHora;
  final String tipoTerapia;
  final String observacoes;
  final AgendamentoStatus status;

  const AgendamentoModel({
    required this.id,
    required this.pacienteId,
    required this.pacienteNome,
    required this.profissionalId,
    required this.dataHora,
    required this.tipoTerapia,
    required this.observacoes,
    this.status = AgendamentoStatus.agendado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pacienteId': pacienteId,
      'pacienteNome': pacienteNome,
      'profissionalId': profissionalId,
      'dataHora': dataHora,
      'tipoTerapia': tipoTerapia,
      'observacoes': observacoes,
      'status': status.name,
    };
  }

  factory AgendamentoModel.fromMap(Map<String, dynamic> map) {
    return AgendamentoModel(
      id: map['id'] ?? '',
      pacienteId: map['pacienteId'] ?? '',
      pacienteNome: map['pacienteNome'] ?? '',
      profissionalId: map['profissionalId'] ?? '',
      dataHora: _parseDateTime(map['dataHora']),
      tipoTerapia: map['tipoTerapia'] ?? '',
      observacoes: map['observacoes'] ?? '',
      status: AgendamentoStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'agendado'),
        orElse: () => AgendamentoStatus.agendado,
      ),
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

  AgendamentoModel copyWith({
    String? id,
    String? pacienteId,
    String? pacienteNome,
    String? profissionalId,
    DateTime? dataHora,
    String? tipoTerapia,
    String? observacoes,
    AgendamentoStatus? status,
  }) {
    return AgendamentoModel(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      pacienteNome: pacienteNome ?? this.pacienteNome,
      profissionalId: profissionalId ?? this.profissionalId,
      dataHora: dataHora ?? this.dataHora,
      tipoTerapia: tipoTerapia ?? this.tipoTerapia,
      observacoes: observacoes ?? this.observacoes,
      status: status ?? this.status,
    );
  }
}
