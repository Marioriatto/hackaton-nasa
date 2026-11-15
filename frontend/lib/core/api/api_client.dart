import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _timeout = const Duration(seconds: 20);

  Future<dynamic> get(String endpoint) async {
    final response = await _send(
      () => _client.get(_uri(endpoint), headers: headers),
    );
    return _decode(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await _send(
      () => _client.post(
        _uri(endpoint),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Map<String, String> get headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String endpoint) =>
      Uri.parse('${AppConfig.instance.apiBaseUrl}$endpoint');

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      if (response.statusCode == 401) {
        await Supabase.instance.client.auth.signOut();
        throw ApiException(
          'Tu sesión expiró. Inicia sesión nuevamente.',
          statusCode: 401,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _messageFor(response),
          statusCode: response.statusCode,
        );
      }
      return response;
    } on SocketException {
      throw ApiException(
        'Sin conexión a internet. Revisa tu red e inténtalo de nuevo.',
      );
    } on TimeoutException {
      throw ApiException('La solicitud tardó demasiado. Intenta nuevamente.');
    }
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String _messageFor(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
      if (decoded is Map && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {
      // Ignorar y usar mensaje genérico.
    }
    return 'Error del servidor (${response.statusCode}). Intenta nuevamente.';
  }
}
