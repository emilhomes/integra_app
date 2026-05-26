class AtendimentoModel {
  final String id;
  final String pacienteId;
  final String profissionalId;
  final DateTime data;
  final List<String> terapias;
  final String observacoes;
  final double? latitude;
  final double? longitude;

  const AtendimentoModel({
    required this.id,
    required this.pacienteId,
    required this.profissionalId,
    required this.data,
    required this.terapias,
    required this.observacoes,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pacienteId': pacienteId,
      'profissionalId': profissionalId,
      'data': data,
      'terapias': terapias,
      'observacoes': observacoes,
      'latitude': latitude,
      'longitude': longitude,
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
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
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
