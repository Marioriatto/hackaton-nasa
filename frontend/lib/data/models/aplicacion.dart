class Aplicacion {
  const Aplicacion({
    required this.id,
    required this.parcelaId,
    required this.fecha,
    required this.fertilizante,
    this.dosis,
  });

  final String id;
  final String parcelaId;
  final DateTime fecha;
  final String fertilizante;
  final double? dosis;

  factory Aplicacion.fromJson(Map<String, dynamic> json) => Aplicacion(
    id: (json['id'] ?? '').toString(),
    parcelaId: (json['parcela_id'] ?? json['parcelaId'] ?? '').toString(),
    fecha:
        DateTime.tryParse((json['fecha'] ?? '').toString()) ?? DateTime.now(),
    fertilizante: (json['fertilizante'] ?? '').toString(),
    dosis: json['dosis'] == null ? null : _toDouble(json['dosis']),
  );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'parcela_id': parcelaId,
    'fecha': fecha.toIso8601String(),
    'fertilizante': fertilizante,
    'dosis': dosis,
  };
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
