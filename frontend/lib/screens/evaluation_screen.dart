import 'package:flutter/material.dart';

import '../core/widgets/plot_image.dart';
import '../data/models/plot_resource.dart';
import '../data/models/resultado_riesgo.dart';
import '../data/repositories/repository_factory.dart';
import 'aqua_debt_tokens.dart';
import 'recommendation_screen.dart';

class EvaluationScreen extends StatelessWidget {
  const EvaluationScreen({super.key, this.parcelaId});

  final String? parcelaId;

  @override
  Widget build(BuildContext context) {
    final id = parcelaId ?? 'parcela-demo-1';
    return AquaScaffold(
      activeItem: 'Evaluación',
      child: FutureBuilder<_EvaluationData>(
        future: _load(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AquaColors.primary),
            );
          }
          if (snapshot.hasError) {
            return AquaCard(
              child: Text(
                'No se pudo cargar la evaluación: ${snapshot.error}',
                style: AquaText.body,
              ),
            );
          }
          final data = snapshot.data!;
          final riesgo = data.riesgo;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                kicker: '03 / ENTENDER LAS CONDICIONES',
                title: 'Una evaluación que se explica',
                subtitle: 'El Encinar · Maíz · Datos demostrativos',
              ),
              const SizedBox(height: 24),
              const _ScenarioSelector(),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 860;
                  return Flex(
                    direction: wide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ExpandedIf(
                        wide: wide,
                        child: _TransportScoreCard(riesgo: riesgo),
                      ),
                      SizedBox(width: wide ? 24 : 0, height: wide ? 0 : 18),
                      _ExpandedIf(
                        wide: wide,
                        child: Column(
                          children: [
                            _FactorCard(
                              title: 'S · Registro agrícola',
                              score: '${riesgo.valorS.toStringAsFixed(0)} / 2',
                              text: riesgo.factores.isNotEmpty
                                  ? riesgo.factores.first
                                  : 'Registro agrícola disponible.',
                            ),
                            const SizedBox(height: 18),
                            _FactorCard(
                              title: 'T · Precipitación',
                              score: '${riesgo.valorT.toStringAsFixed(0)} / 2',
                              text: riesgo.factores.length > 1
                                  ? riesgo.factores[1]
                                  : 'Precipitación NASA GPM disponible.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              if (data.plots.isNotEmpty) ...[
                for (final plot in data.plots) ...[
                  PlotImage(url: plot.url, title: plot.titulo),
                  const SizedBox(height: 16),
                ],
              ],
              AquaCard(
                color: AquaColors.footer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('R = 100 × (S + T) / 4', style: AquaText.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Demo: Bajo < 34 · Moderado 34–66 · Elevado ≥ 67.\nConfianza ${riesgo.confianza.toLowerCase()}: lluvia regional y registro declarado; sin suelo, acuífero ni laboratorio.',
                      style: AquaText.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      SizedBox(
                        width: constraints.maxWidth > 480
                            ? 340
                            : constraints.maxWidth,
                        child: PrimaryButton(
                          text: 'Ver alerta y recomendación  →',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecommendationScreen(parcelaId: id),
                            ),
                          ),
                        ),
                      ),
                      if (constraints.maxWidth > 620) ...[
                        const SizedBox(width: 32),
                        const Expanded(
                          child: Text(
                            'Índice orientativo, no validado para decisiones agronómicas.',
                            style: AquaText.small,
                          ),
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

  Future<_EvaluationData> _load(String parcelaId) async {
    final repo = RepositoryFactory.riesgo;
    final results = await Future.wait([
      repo.obtenerRiesgo(parcelaId),
      repo.obtenerPlots(parcelaId),
    ]);
    return _EvaluationData(
      riesgo: results[0] as ResultadoRiesgo,
      plots: results[1] as List<PlotResource>,
    );
  }
}

class _EvaluationData {
  const _EvaluationData({required this.riesgo, required this.plots});

  final ResultadoRiesgo riesgo;
  final List<PlotResource> plots;
}

class _ScenarioSelector extends StatelessWidget {
  const _ScenarioSelector();

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      color: const Color(0xFFE8EFEB),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ESCENARIO DEMOSTRATIVO', style: AquaText.label),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 640;
              const first = _ScenarioOption(
                text: 'A · Aplicación reciente + lluvia relevante',
                selected: true,
              );
              const second = _ScenarioOption(
                text: 'B · Aplicación registrada + lluvia poco relevante',
              );

              if (!wide) {
                return const Column(
                  children: [first, SizedBox(height: 10), second],
                );
              }

              return const Row(
                children: [
                  Expanded(child: first),
                  SizedBox(width: 12),
                  Expanded(child: second),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScenarioOption extends StatelessWidget {
  const _ScenarioOption({required this.text, this.selected = false});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? AquaColors.primary : AquaColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AquaText.body.copyWith(
          color: selected ? AquaColors.surface : AquaColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TransportScoreCard extends StatelessWidget {
  const _TransportScoreCard({required this.riesgo});

  final ResultadoRiesgo riesgo;

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONDICIONES DE TRANSPORTE', style: AquaText.label),
          const SizedBox(height: 28),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: AquaText.font,
                color: AquaColors.primary,
              ),
              children: [
                TextSpan(
                  text: riesgo.indicador.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 88,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
                const TextSpan(
                  text: ' / 100',
                  style: TextStyle(fontSize: 20, color: AquaColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          DemoPill(
            text:
                riesgo.nivelDemostrativo[0].toUpperCase() +
                riesgo.nivelDemostrativo.substring(1).toLowerCase(),
            warning: riesgo.nivelDemostrativo.toLowerCase() == 'elevado',
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: (riesgo.indicador / 100).clamp(0, 1),
              color: const Color(0xFFD6B75D),
              backgroundColor: AquaColors.footer,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '0 · Bajo                 50 · Moderado               100',
            style: AquaText.small,
          ),
          const SizedBox(height: 24),
          const Text(
            'No es una probabilidad real de contaminación.',
            style: AquaText.body,
          ),
        ],
      ),
    );
  }
}

class _FactorCard extends StatelessWidget {
  const _FactorCard({
    required this.title,
    required this.score,
    required this.text,
  });

  final String title;
  final String score;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AquaText.body.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 18),
                Text(text, style: AquaText.body),
              ],
            ),
          ),
          Text(score, style: AquaText.h2),
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
