class Alerta {
  const Alerta({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.nivel,
    required this.fecha,
  });

  final String id;
  final String titulo;
  final String mensaje;
  final String nivel;
  final DateTime fecha;

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
    id: (json['id'] ?? '').toString(),
    titulo: (json['titulo'] ?? '').toString(),
    mensaje: (json['mensaje'] ?? '').toString(),
    nivel: (json['nivel'] ?? '').toString(),
    fecha:
        DateTime.tryParse((json['fecha'] ?? '').toString()) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'mensaje': mensaje,
    'nivel': nivel,
    'fecha': fecha.toIso8601String(),
  };
}
