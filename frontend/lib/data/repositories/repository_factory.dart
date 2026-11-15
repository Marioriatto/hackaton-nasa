import '../../core/api/api_client.dart';
import '../../core/config/app_config.dart';
import 'aplicaciones_repository.dart';
import 'parcelas_repository.dart';
import 'riesgo_repository.dart';

class RepositoryFactory {
  RepositoryFactory._();

  static final ApiClient _api = ApiClient();

  static ParcelasRepository get parcelas => AppConfig.instance.shouldUseMockData
      ? ParcelasRepositoryMock()
      : ParcelasRepositoryApi(_api);

  static AplicacionesRepository get aplicaciones =>
      AppConfig.instance.shouldUseMockData
      ? AplicacionesRepositoryMock()
      : AplicacionesRepositoryApi(_api);

  static RiesgoRepository get riesgo => AppConfig.instance.shouldUseMockData
      ? RiesgoRepositoryMock()
      : RiesgoRepositoryApi(_api);
}
