import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/aplicacion.dart';

abstract class AplicacionesRepository {
  Future<Aplicacion> registrarAplicacion(Aplicacion aplicacion);
}

class AplicacionesRepositoryApi implements AplicacionesRepository {
  AplicacionesRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<Aplicacion> registrarAplicacion(Aplicacion aplicacion) async {
    final data = await _api.post(
      ApiEndpoints.aplicaciones,
      aplicacion.toJson(),
    );
    return Aplicacion.fromJson(Map<String, dynamic>.from(data));
  }
}

class AplicacionesRepositoryMock implements AplicacionesRepository {
  @override
  Future<Aplicacion> registrarAplicacion(Aplicacion aplicacion) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return Aplicacion(
      id: 'aplicacion-demo-1',
      parcelaId: aplicacion.parcelaId,
      fecha: aplicacion.fecha,
      fertilizante: aplicacion.fertilizante,
      dosis: aplicacion.dosis,
    );
  }
}
