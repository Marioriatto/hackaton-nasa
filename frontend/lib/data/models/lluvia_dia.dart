class LluviaDia {
  const LluviaDia({required this.fecha, required this.mm});

  final DateTime fecha;
  final double mm;

  factory LluviaDia.fromJson(Map<String, dynamic> json) => LluviaDia(
    fecha:
        DateTime.tryParse((json['fecha'] ?? json['date'] ?? '').toString()) ??
        DateTime.now(),
    mm: _toDouble(json['mm'] ?? json['rain_mm']),
  );

  Map<String, dynamic> toJson() => {'fecha': fecha.toIso8601String(), 'mm': mm};
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
