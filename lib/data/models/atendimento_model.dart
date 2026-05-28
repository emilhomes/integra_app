class AtendimentoModel {
  final String id;
  final String pacienteId;
  final String profissionalId;
  final DateTime data;
  final List<String> terapias;
  final String observacoes;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? assinaturaPath;

  const AtendimentoModel({
    required this.id,
    required this.pacienteId,
    required this.profissionalId,
    required this.data,
    required this.terapias,
    required this.observacoes,
    this.status = 'concluido',
    this.latitude,
    this.longitude,
    this.assinaturaPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pacienteId': pacienteId,
      'profissionalId': profissionalId,
      'data': data,
      'terapias': terapias,
      'observacoes': observacoes,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'assinaturaPath': assinaturaPath,
    };
  }

  factory AtendimentoModel.fromMap(Map<String, dynamic> map) {
    return AtendimentoModel(
      id: map['id'] ?? '',
      pacienteId: map['pacienteId'] ?? '',
      profissionalId: map['profissionalId'] ?? '',
      data: _parseDateTime(map['data']),
      terapias: List<String>.from(map['terapias'] ?? []),
      observacoes: map['observacoes'] ?? '',
      status: map['status'] ?? 'concluido',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      assinaturaPath: map['assinaturaPath'],
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

  AtendimentoModel copyWith({
    String? id,
    String? pacienteId,
    String? profissionalId,
    DateTime? data,
    List<String>? terapias,
    String? observacoes,
    String? status,
    double? latitude,
    double? longitude,
    String? assinaturaPath,
  }) {
    return AtendimentoModel(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      profissionalId: profissionalId ?? this.profissionalId,
      data: data ?? this.data,
      terapias: terapias ?? this.terapias,
      observacoes: observacoes ?? this.observacoes,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      assinaturaPath: assinaturaPath ?? this.assinaturaPath,
    );
  }
}
