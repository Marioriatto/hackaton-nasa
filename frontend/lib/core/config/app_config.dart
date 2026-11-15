import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.apiBaseUrl,
    required this.useMockData,
  });

  final String supabaseUrl;
  final String supabasePublishableKey;
  final String apiBaseUrl;
  final bool useMockData;

  static late final AppConfig instance;

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
    instance = AppConfig._(
      supabaseUrl: _required('SUPABASE_URL'),
      supabasePublishableKey: _required('SUPABASE_PUBLISHABLE_KEY'),
      apiBaseUrl: _required('API_BASE_URL').replaceFirst(RegExp(r'/$'), ''),
      useMockData:
          dotenv.get('USE_MOCK_DATA', fallback: 'true').toLowerCase() == 'true',
    );
  }

  bool get shouldUseMockData =>
      useMockData || apiBaseUrl.contains('TU_BACKEND_AQUI');

  static String _required(String key) {
    final value = dotenv.get(key, fallback: '').trim();
    if (value.isEmpty) {
      throw StateError('Falta configurar $key en .env');
    }
    return value;
  }
}
