import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/alerta.dart';
import '../models/lluvia_dia.dart';
import '../models/plot_resource.dart';
import '../models/resultado_riesgo.dart';

abstract class RiesgoRepository {
  Future<List<LluviaDia>> obtenerLluvia(String parcelaId);
  Future<ResultadoRiesgo> obtenerRiesgo(String parcelaId);
  Future<List<PlotResource>> obtenerPlots(String parcelaId);
  Future<List<Alerta>> obtenerAlertas();
}

class RiesgoRepositoryApi implements RiesgoRepository {
  RiesgoRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<List<LluviaDia>> obtenerLluvia(String parcelaId) async {
    final data = await _api.get(ApiEndpoints.lluvia(parcelaId));
    final list = data is List ? data : (data['items'] as List? ?? []);
    return list
        .map((e) => LluviaDia.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<ResultadoRiesgo> obtenerRiesgo(String parcelaId) async {
    final data = await _api.get(ApiEndpoints.riesgo(parcelaId));
    return ResultadoRiesgo.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<List<PlotResource>> obtenerPlots(String parcelaId) async {
    final data = await _api.get(ApiEndpoints.plots(parcelaId));
    final list = data is List ? data : (data['items'] as List? ?? []);
    return list
        .map((e) => PlotResource.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<Alerta>> obtenerAlertas() async {
    final data = await _api.get(ApiEndpoints.alertas);
    final list = data is List ? data : (data['items'] as List? ?? []);
    return list
        .map((e) => Alerta.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class RiesgoRepositoryMock implements RiesgoRepository {
  @override
  Future<List<LluviaDia>> obtenerLluvia(String parcelaId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now();
    return List.generate(
      7,
      (i) => LluviaDia(
        fecha: now.subtract(Duration(days: 6 - i)),
        mm: [0, 4, 12, 8, 3, 6, 3][i].toDouble(),
      ),
    );
  }

  @override
  Future<ResultadoRiesgo> obtenerRiesgo(String parcelaId) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return const ResultadoRiesgo(
      valorS: 2,
      valorT: 2,
      indicador: 78,
      nivelDemostrativo: 'elevado',
      confianza: 'Limitada',
      factores: [
        'Aplicación reciente registrada en la parcela piloto.',
        '36 mm acumulados en la ventana demostrativa de 72 horas.',
        'Sin datos locales de suelo, acuífero ni laboratorio.',
      ],
    );
  }

  @override
  Future<List<PlotResource>> obtenerPlots(String parcelaId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      PlotResource(
        id: 'plot-demo-1',
        titulo: 'Precipitación acumulada',
        tipo: 'imagen',
        url: '',
      ),
    ];
  }

  @override
  Future<List<Alerta>> obtenerAlertas() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      Alerta(
        id: 'alerta-demo-1',
        titulo: 'Riesgo elevado de transporte',
        mensaje: 'Revisar calendario de futuras aplicaciones y evitar excesos de riego.',
        nivel: 'elevado',
        fecha: DateTime.now(),
      ),
    ];
  }
}
