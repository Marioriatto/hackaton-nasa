import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'features/auth/auth_gate.dart';
import 'screens/aqua_debt_tokens.dart';
import 'screens/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();

  await Supabase.initialize(
    url: AppConfig.instance.supabaseUrl,
    publishableKey: AppConfig.instance.supabasePublishableKey,
  );

  runApp(const AquaDebtApp());
}

class AquaDebtApp extends StatelessWidget {
  const AquaDebtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaDebt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AquaColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AquaColors.primary),
        fontFamily: AquaText.font,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AquaColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AquaColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AquaColors.primary),
          ),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/home': (_) => const AquaDebtHomeScreen(),
        '/map': (_) => const AquaDebtMapScreen(),
        '/application': (_) => const ApplicationFormScreen(),
        '/evaluation': (_) => const EvaluationScreen(),
        '/about': (_) => const AboutProjectScreen(),
      },
    );
  }
}
