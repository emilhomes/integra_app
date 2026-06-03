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

  // Novos campos para Avaliação por Atendimento
  final String? queixaPrincipal;
  final List<Map<String, dynamic>>? pontosDorTensao;
  final String? pa;
  final String? fc;
  final String? temperatura;

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
    this.queixaPrincipal,
    this.pontosDorTensao,
    this.pa,
    this.fc,
    this.temperatura,
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
      'queixaPrincipal': queixaPrincipal,
      'pontosDorTensao': pontosDorTensao,
      'pa': pa,
      'fc': fc,
      'temperatura': temperatura,
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
      queixaPrincipal: map['queixaPrincipal'],
      pontosDorTensao: map['pontosDorTensao'] != null 
          ? List<Map<String, dynamic>>.from(map['pontosDorTensao']) 
          : null,
      pa: map['pa'],
      fc: map['fc'],
      temperatura: map['temperatura'],
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
    String? queixaPrincipal,
    List<Map<String, dynamic>>? pontosDorTensao,
    String? pa,
    String? fc,
    String? temperatura,
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
      queixaPrincipal: queixaPrincipal ?? this.queixaPrincipal,
      pontosDorTensao: pontosDorTensao ?? this.pontosDorTensao,
      pa: pa ?? this.pa,
      fc: fc ?? this.fc,
      temperatura: temperatura ?? this.temperatura,
    );
  }
}
