import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/home_screen.dart';
import '../../screens/aqua_debt_tokens.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session != null) {
          return const AquaDebtHomeScreen();
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            auth.currentSession == null) {
          return const _AuthLoading();
        }
        return const LoginScreen();
      },
    );
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AquaColors.background,
      body: Center(child: CircularProgressIndicator(color: AquaColors.primary)),
    );
  }
}
