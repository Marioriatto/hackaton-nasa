import 'package:flutter/material.dart';

import '../data/models/parcela.dart';
import '../data/repositories/repository_factory.dart';
import '../features/auth/auth_service.dart';
import 'aqua_debt_tokens.dart';
import 'application_form_screen.dart';
import 'map_screen.dart';
import 'evaluation_screen.dart';

class AquaDebtHomeScreen extends StatelessWidget {
  const AquaDebtHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AquaScaffold(
      activeItem: 'Inicio',
      child: FutureBuilder<List<Parcela>>(
        future: RepositoryFactory.parcelas.listarParcelas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AquaColors.primary),
            );
          }
          if (snapshot.hasError) {
            return AquaCard(
              child: Text(
                'No se pudieron cargar las parcelas: ${snapshot.error}',
                style: AquaText.body,
              ),
            );
          }

          final parcelas = snapshot.data ?? const [];
          final selected = parcelas.isNotEmpty ? parcelas.first : null;
          final title = selected?.nombre ?? 'Sin parcelas registradas';
          final crop = selected?.cultivo ?? 'Cultivo pendiente';
          final risk = selected?.indicadorRiesgo?.toStringAsFixed(0) ?? '--';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => AuthService().signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                ),
              ),
              SectionHeader(
                kicker: 'PARCELA PILOTO / ${crop.toUpperCase()}',
                title: title,
                subtitle: 'Indicador de riesgo · $risk / 100',
              ),
              const SizedBox(height: 28),
              if (parcelas.isEmpty)
                const AquaCard(
                  child: Text(
                    'Aún no hay parcelas asociadas a tu cuenta.',
                    style: AquaText.body,
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 760;
                    final parcelaId = selected!.id;
                    final cards = [
                      _StepCard(
                        number: '01',
                        title: 'Observar el territorio',
                        text: 'Explora la precipitación regional y consulta tus parcelas.',
                        color: AquaColors.blue,
                        button: 'Ver contexto en el mapa',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AquaDebtMapScreen(),
                          ),
                        ),
                      ),
                      _StepCard(
                        number: '02',
                        title: 'Registrar la aplicación',
                        text: 'Completa dónde, cuándo y qué se aplicó en la parcela.',
                        color: AquaColors.primary,
                        button: 'Registrar aplicación',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ApplicationFormScreen(parcelaId: parcelaId),
                          ),
                        ),
                      ),
                      _StepCard(
                        number: '03',
                        title: 'Entender las condiciones',
                        text: 'Revisa un indicador explicable y una recomendación preventiva.',
                        color: AquaColors.accentGreen,
                        button: 'Ir a evaluación',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EvaluationScreen(parcelaId: parcelaId),
                          ),
                        ),
                      ),
                    ];

                    return Flex(
                      direction: wide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          _ExpandedIf(wide: wide, child: cards[i]),
                          if (i != cards.length - 1)
                            SizedBox(
                              width: wide ? 16 : 0,
                              height: wide ? 0 : 16,
                            ),
                        ],
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.text,
    required this.color,
    required this.button,
    required this.onTap,
  });

  final String number;
  final String title;
  final String text;
  final Color color;
  final String button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: AquaText.label.copyWith(color: color, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(title, style: AquaText.h2),
          const SizedBox(height: 8),
          Text(text, style: AquaText.body),
          const SizedBox(height: 22),
          PrimaryButton(text: '$button  →', onPressed: onTap),
        ],
      ),
    );
  }
}

class _ExpandedIf extends StatelessWidget {
  const _ExpandedIf({required this.wide, required this.child});

  final bool wide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return wide ? Expanded(child: child) : child;
  }
}
