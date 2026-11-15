class Parcela {
  const Parcela({
    required this.id,
    required this.nombre,
    required this.cultivo,
    required this.areaHa,
    required this.geoJson,
    this.indicadorRiesgo,
    this.nivelRiesgo,
  });

  final String id;
  final String nombre;
  final String cultivo;
  final double areaHa;
  final Map<String, dynamic> geoJson;
  final double? indicadorRiesgo;
  final String? nivelRiesgo;

  factory Parcela.fromJson(Map<String, dynamic> json) => Parcela(
    id: json['id'].toString(),
    nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
    cultivo: (json['cultivo'] ?? json['crop'] ?? '').toString(),
    areaHa: _toDouble(json['area_ha'] ?? json['areaHa']),
    geoJson: Map<String, dynamic>.from(
      json['geojson'] ?? json['geometry'] ?? {},
    ),
    indicadorRiesgo: json['indicador_riesgo'] == null
        ? null
        : _toDouble(json['indicador_riesgo']),
    nivelRiesgo: json['nivel_riesgo']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'cultivo': cultivo,
    'area_ha': areaHa,
    'geojson': geoJson,
    'indicador_riesgo': indicadorRiesgo,
    'nivel_riesgo': nivelRiesgo,
  };
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
