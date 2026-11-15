class PlotResource {
  const PlotResource({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.url,
    this.datos,
  });

  final String id;
  final String titulo;
  final String tipo;
  final String url;
  final Map<String, dynamic>? datos;

  factory PlotResource.fromJson(Map<String, dynamic> json) => PlotResource(
    id: (json['id'] ?? '').toString(),
    titulo: (json['titulo'] ?? '').toString(),
    tipo: (json['tipo'] ?? 'imagen').toString(),
    url: (json['url'] ?? '').toString(),
    datos: json['datos'] is Map
        ? Map<String, dynamic>.from(json['datos'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'tipo': tipo,
    'url': url,
    'datos': datos,
  };
}
