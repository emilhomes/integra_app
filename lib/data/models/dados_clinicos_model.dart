class DadosClinicosModel {
  final String id;
  final String atendimentoId;
  final String pressaoArterial;
  final int frequenciaCardiaca;
  final double temperatura;

  const DadosClinicosModel({
    required this.id,
    required this.atendimentoId,
    required this.pressaoArterial,
    required this.frequenciaCardiaca,
    required this.temperatura,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'atendimentoId': atendimentoId,
      'pressaoArterial': pressaoArterial,
      'frequenciaCardiaca': frequenciaCardiaca,
      'temperatura': temperatura,
    };
  }

  factory DadosClinicosModel.fromMap(Map<String, dynamic> map) {
    return DadosClinicosModel(
      id: map['id'] ?? '',
      atendimentoId: map['atendimentoId'] ?? '',
      pressaoArterial: map['pressaoArterial'] ?? '',
      frequenciaCardiaca: map['frequenciaCardiaca'] ?? 0,
      temperatura: (map['temperatura'] ?? 0.0).toDouble(),
    );
  }
}
