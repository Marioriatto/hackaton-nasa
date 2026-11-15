import 'package:flutter/material.dart';

import '../data/models/aplicacion.dart';
import '../data/repositories/repository_factory.dart';
import 'aqua_debt_tokens.dart';
import 'evaluation_screen.dart';

class ApplicationFormScreen extends StatefulWidget {
  const ApplicationFormScreen({super.key, this.parcelaId});

  final String? parcelaId;

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _nameController = TextEditingController(text: 'El Encinar');
  final _fertilizerController = TextEditingController(
    text: 'Urea · registro de ejemplo',
  );
  final _dateController = TextEditingController(text: '12 / 11 / 2026');
  final _doseController = TextEditingController(text: 'Sin especificar');
  final _doseUnitController = TextEditingController(text: 'no interviene en R');

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _fertilizerController.dispose();
    _dateController.dispose();
    _doseController.dispose();
    _doseUnitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final parcelaId = widget.parcelaId ?? 'parcela-demo-1';
      await RepositoryFactory.aplicaciones.registrarAplicacion(
        Aplicacion(
          id: '',
          parcelaId: parcelaId,
          fecha: DateTime.now(),
          fertilizante: _fertilizerController.text.trim(),
          dosis: double.tryParse(_doseController.text),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EvaluationScreen(parcelaId: parcelaId),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AquaScaffold(
      activeItem: 'Registrar aplicación',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            kicker: '02 / REGISTRAR LA APLICACIÓN',
            title: 'Cada aplicación cuenta',
            subtitle: 'Completa el caso piloto para explorar las condiciones de transporte.',
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
                    child: _AgriculturalFormCard(
                      loading: _loading,
                      error: _error,
                      onSubmit: _submit,
                    ),
                  ),
                  SizedBox(width: wide ? 24 : 0, height: wide ? 0 : 18),
                  _ExpandedIf(wide: wide, child: const _ExplainerCard()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AgriculturalFormCard extends StatelessWidget {
  const _AgriculturalFormCard({
    required this.onSubmit,
    required this.loading,
    this.error,
  });

  final VoidCallback onSubmit;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registro agrícola', style: AquaText.h2),
          const SizedBox(height: 6),
          const Text(
            '* Campos obligatorios · Datos locales de demostración',
            style: AquaText.small,
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCols = constraints.maxWidth > 620;
              final fields = const [
                _MockField(label: 'Nombre de parcela *', value: 'El Encinar'),
                _MockField(
                  label: 'Ubicación de demostración *',
                  value: 'Córdoba · 37,850 N / −4,800 O',
                ),
                _MockField(
                  label: 'Cultivo del caso piloto *',
                  value: 'Maíz · único cultivo de la demo',
                ),
                _MockField(
                  label: 'Fertilizante nitrogenado *',
                  value: 'Urea · registro de ejemplo',
                ),
                _MockField(
                  label: 'Fecha de aplicación *',
                  value: '12 / 11 / 2026',
                ),
                _MockField(
                  label: 'Dosis (opcional)',
                  value: 'Sin especificar · no interviene en R',
                ),
              ];

              if (!twoCols) {
                return Column(
                  children: [
                    for (final field in fields) ...[
                      field,
                      const SizedBox(height: 18),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < fields.length; i += 2) ...[
                    Row(
                      children: [
                        Expanded(child: fields[i]),
                        const SizedBox(width: 24),
                        Expanded(child: fields[i + 1]),
                      ],
                    ),
                    const SizedBox(height: 26),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          if (error != null) ...[
            Text(
              error!,
              style: AquaText.small.copyWith(color: AquaColors.warningText),
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 363,
              child: PrimaryButton(
                text: loading ? 'Registrando...' : 'Registrar y evaluar  →',
                onPressed: loading ? null : onSubmit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockField extends StatelessWidget {
  const _MockField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AquaText.small.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 50,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AquaColors.background,
            border: Border.all(color: AquaColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: AquaText.small.copyWith(color: AquaColors.primary),
          ),
        ),
      ],
    );
  }
}

class _ExplainerCard extends StatelessWidget {
  const _ExplainerCard();

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      color: AquaColors.primary,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DE TU PARCELA AL INDICADOR',
            style: TextStyle(
              fontFamily: AquaText.font,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB4D8C2),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Un registro.\nUna evaluación explicable.',
            style: TextStyle(
              fontFamily: AquaText.font,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: AquaColors.surface,
            ),
          ),
          SizedBox(height: 44),
          Text(
            '01  Indica dónde y cuándo aplicaste.\n\n02  Consulta la lluvia del periodo.\n\n03  Revisa el contexto y las medidas preventivas.',
            style: TextStyle(
              fontFamily: AquaText.font,
              fontSize: 14,
              height: 1.45,
              color: AquaColors.successSoft,
            ),
          ),
          SizedBox(height: 80),
          Text(
            'Sin cuentas ni almacenamiento remoto.\nNo calculamos dosis ni concentraciones.',
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
