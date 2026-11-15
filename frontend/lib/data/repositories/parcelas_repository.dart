import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../models/parcela.dart';

abstract class ParcelasRepository {
  Future<List<Parcela>> listarParcelas();
  Future<Parcela> detalleParcela(String id);
}

class ParcelasRepositoryApi implements ParcelasRepository {
  ParcelasRepositoryApi(this._api);

  final ApiClient _api;

  @override
  Future<List<Parcela>> listarParcelas() async {
    final data = await _api.get(ApiEndpoints.parcelas);
    final list = data is List ? data : (data['items'] as List? ?? []);
    return list
        .map((e) => Parcela.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Parcela> detalleParcela(String id) async {
    final data = await _api.get(ApiEndpoints.parcela(id));
    return Parcela.fromJson(Map<String, dynamic>.from(data));
  }
}

class ParcelasRepositoryMock implements ParcelasRepository {
  @override
  Future<List<Parcela>> listarParcelas() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return [_elEncinar];
  }

  @override
  Future<Parcela> detalleParcela(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _elEncinar;
  }
}

const _elEncinar = Parcela(
  id: 'parcela-demo-1',
  nombre: 'La Verganza',
  cultivo: 'Maíz',
  areaHa: 4.2,
  indicadorRiesgo: 78,
  nivelRiesgo: 'elevado',
  geoJson: {
    'type': 'Polygon',
    'coordinates': [
      [
        [-4.804, 37.852],
        [-4.796, 37.852],
        [-4.795, 37.846],
        [-4.805, 37.846],
        [-4.804, 37.852],
      ],
    ],
  },
);
