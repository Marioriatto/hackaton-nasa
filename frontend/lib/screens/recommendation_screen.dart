import 'package:flutter/material.dart';

import '../data/models/alerta.dart';
import '../data/models/resultado_riesgo.dart';
import '../data/repositories/repository_factory.dart';
import 'aqua_debt_tokens.dart';
import 'evaluation_screen.dart';
import 'map_screen.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key, this.parcelaId});

  final String? parcelaId;

  @override
  Widget build(BuildContext context) {
    final id = parcelaId ?? 'parcela-demo-1';
    return AquaScaffold(
      activeItem: 'Evaluación',
      child: FutureBuilder<_RecommendationData>(
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
                'No se pudo cargar la recomendación: ${snapshot.error}',
                style: AquaText.body,
              ),
            );
          }
          final data = snapshot.data!;
          final alerta = data.alertas.isNotEmpty ? data.alertas.first : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                kicker: '04 / ACTUAR CON PREVENCIÓN',
                title: 'Anticiparse también es cuidar',
                subtitle: 'El Encinar · Maíz · Recomendación preventiva a partir del escenario demostrativo.',
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 860;
                  return Flex(
                    direction: wide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ExpandedIf(
                        wide: wide,
                        flex: 2,
                        child: Column(
                          children: [
                            _AlertCard(riesgo: data.riesgo, alerta: alerta),
                            const SizedBox(height: 18),
                            _RecommendationCard(alerta: alerta),
                          ],
                        ),
                      ),
                      SizedBox(width: wide ? 24 : 0, height: wide ? 0 : 18),
                      _ExpandedIf(
                        wide: wide,
                        child: _ReasoningCard(riesgo: data.riesgo),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 620;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: narrow ? constraints.maxWidth : 290,
                        child: PrimaryButton(
                          text: '←  Volver a la evaluación',
                          onPressed: () => Navigator.of(context)
                              .pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EvaluationScreen(parcelaId: id),
                                ),
                              ),
                        ),
                      ),
                      SizedBox(
                        width: narrow ? constraints.maxWidth : 260,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AquaDebtMapScreen(),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AquaColors.primary,
                            side: const BorderSide(color: AquaColors.primary),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Ver contexto en el mapa'),
                        ),
                      ),
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

  Future<_RecommendationData> _load(String parcelaId) async {
    final repo = RepositoryFactory.riesgo;
    final results = await Future.wait([
      repo.obtenerRiesgo(parcelaId),
      repo.obtenerAlertas(),
    ]);
    return _RecommendationData(
      riesgo: results[0] as ResultadoRiesgo,
      alertas: results[1] as List<Alerta>,
    );
  }
}

class _RecommendationData {
  const _RecommendationData({required this.riesgo, required this.alertas});

  final ResultadoRiesgo riesgo;
  final List<Alerta> alertas;
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.riesgo, this.alerta});

  final ResultadoRiesgo riesgo;
  final Alerta? alerta;

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      color: AquaColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            riesgo.nivelDemostrativo.toLowerCase() == 'elevado'
                ? 'A · Lluvia relevante'
                : 'B · Lluvia escasa',
            style: AquaText.label.copyWith(color: AquaColors.warningText),
          ),
          const SizedBox(height: 12),
          Text(
            alerta?.titulo ??
                'Riesgo ${riesgo.nivelDemostrativo} de transporte',
            style: const TextStyle(
              fontFamily: AquaText.font,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF604E18),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            alerta?.mensaje ?? 'El indicador sugiere revisar medidas preventivas según el contexto de la parcela.',
            style: AquaText.body.copyWith(color: const Color(0xFF604E18)),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({this.alerta});

  final Alerta? alerta;

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECOMENDACIÓN PREVENTIVA', style: AquaText.label),
          const SizedBox(height: 18),
          Text(
            alerta?.mensaje ?? 'Revisar el calendario de futuras aplicaciones y evitar excesos de riego, siguiendo las necesidades del cultivo y la asesoría técnica.',
            style: const TextStyle(
              fontFamily: AquaText.font,
              fontSize: 17,
              height: 1.45,
              color: AquaColors.body,
            ),
          ),
          const SizedBox(height: 22),
          const Divider(color: AquaColors.border),
          const SizedBox(height: 14),
          Text(
            'No se recomiendan dosis ni sustituciones de sustancias. Consulta a tu asesor técnico.',
            style: AquaText.small.copyWith(color: AquaColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ReasoningCard extends StatelessWidget {
  const _ReasoningCard({required this.riesgo});

  final ResultadoRiesgo riesgo;

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      color: AquaColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EL RAZONAMIENTO, A LA VISTA',
            style: TextStyle(
              fontFamily: AquaText.font,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB4D8C2),
            ),
          ),
          const SizedBox(height: 28),
          _ReasonRow(
            number: '01',
            title: 'Registro',
            text: riesgo.factores.isNotEmpty
                ? riesgo.factores[0]
                : 'Aplicación registrada en la parcela.',
          ),
          const SizedBox(height: 18),
          _ReasonRow(
            number: '02',
            title: 'Precipitación',
            text: riesgo.factores.length > 1
                ? riesgo.factores[1]
                : 'Precipitación regional disponible.',
          ),
          const SizedBox(height: 18),
          _ReasonRow(
            number: '03',
            title: 'Proyecto',
            text: riesgo.factores.length > 2
                ? riesgo.factores[2]
                : 'Indicador demostrativo para observar, prevenir y proteger.',
          ),
          const SizedBox(height: 56),
          const Text(
            'Confianza limitada\nLa escala regional no describe por sí sola el suelo ni el agua de esta parcela.',
            style: TextStyle(
              fontFamily: AquaText.font,
              fontSize: 12,
              height: 1.45,
              color: Color(0xFFB4D8C2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontFamily: AquaText.font,
            color: Color(0xFFB4D8C2),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AquaText.font,
                  color: AquaColors.surface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(
                  fontFamily: AquaText.font,
                  color: AquaColors.successSoft,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpandedIf extends StatelessWidget {
  const _ExpandedIf({required this.wide, required this.child, this.flex = 1});

  final bool wide;
  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return wide ? Expanded(flex: flex, child: child) : child;
  }
}
