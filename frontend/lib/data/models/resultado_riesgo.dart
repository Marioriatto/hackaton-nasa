class ResultadoRiesgo {
  const ResultadoRiesgo({
    required this.valorS,
    required this.valorT,
    required this.indicador,
    required this.nivelDemostrativo,
    required this.confianza,
    required this.factores,
  });

  final double valorS;
  final double valorT;
  final double indicador;
  final String nivelDemostrativo;
  final String confianza;
  final List<String> factores;

  factory ResultadoRiesgo.fromJson(Map<String, dynamic> json) =>
      ResultadoRiesgo(
        valorS: _toDouble(json['valor_s'] ?? json['valorS']),
        valorT: _toDouble(json['valor_t'] ?? json['valorT']),
        indicador: _toDouble(json['indicador']),
        nivelDemostrativo: (json['nivel_demostrativo'] ?? 'moderado')
            .toString(),
        confianza: (json['confianza'] ?? 'Limitada').toString(),
        factores: (json['factores'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'valor_s': valorS,
    'valor_t': valorT,
    'indicador': indicador,
    'nivel_demostrativo': nivelDemostrativo,
    'confianza': confianza,
    'factores': factores,
  };
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
