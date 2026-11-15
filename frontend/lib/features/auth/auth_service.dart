import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthUiException(_mapAuthMessage(e.message));
    } on SocketException {
      throw AuthUiException(
        'Sin conexión. Revisa tu red e inténtalo de nuevo.',
      );
    }
  }

  Future<void> signUp({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'nombre_completo': nombre},
      );
      if (response.session == null) {
        throw AuthUiException(
          'Cuenta creada. Revisa tu correo para confirmar el registro.',
        );
      }
    } on AuthUiException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthUiException(_mapAuthMessage(e.message));
    } on SocketException {
      throw AuthUiException(
        'Sin conexión. Revisa tu red e inténtalo de nuevo.',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.aquadebt://login-callback/',
      );
    } on AuthException catch (e) {
      throw AuthUiException(_mapAuthMessage(e.message));
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  String _mapAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'Credenciales inválidas. Verifica tu correo y contraseña.';
    }
    if (lower.contains('already') || lower.contains('registered')) {
      return 'Este correo ya está registrado.';
    }
    if (lower.contains('confirm')) {
      return 'Tu correo está pendiente de confirmar.';
    }
    return 'No pudimos completar la autenticación. Intenta nuevamente.';
  }
}

class AuthUiException implements Exception {
  AuthUiException(this.message);

  final String message;

  @override
  String toString() => message;
}
