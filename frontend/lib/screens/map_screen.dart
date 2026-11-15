import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/models/parcela.dart';
import '../data/repositories/repository_factory.dart';
import 'aqua_debt_tokens.dart';
import 'application_form_screen.dart';
import 'evaluation_screen.dart';

class AquaDebtMapScreen extends StatelessWidget {
  const AquaDebtMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AquaScaffold(
      activeItem: 'Mapa',
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
          if (parcelas.isEmpty) {
            return const AquaCard(
              child: Text(
                'No hay parcelas para mostrar en el mapa.',
                style: AquaText.body,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                kicker: '01 / OBSERVAR EL TERRITORIO',
                title: 'Tu parcela, en contexto',
                subtitle: 'Explora la precipitación regional y consulta el caso piloto.',
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 860;
                  final selected = parcelas.first;
                  return Flex(
                    direction: wide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ExpandedIf(
                        wide: wide,
                        flex: 2,
                        child: _MapPanel(parcelas: parcelas),
                      ),
                      SizedBox(width: wide ? 24 : 0, height: wide ? 0 : 18),
                      _ExpandedIf(
                        wide: wide,
                        child: _SelectedParcelCard(
                          parcela: selected,
                          onRegister: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ApplicationFormScreen(parcelaId: selected.id),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Referencia: NASA GPM IMERG V07 · la visualización depende de las geometrías GeoJSON del backend.\n'
                'Información de acuíferos no disponible. No se representan concentraciones de contaminantes.',
                style: AquaText.small,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapPanel extends StatefulWidget {
  const _MapPanel({required this.parcelas});

  final List<Parcela> parcelas;

  @override
  State<_MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<_MapPanel> {
  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    final polygons = widget.parcelas
        .map(_toPolygon)
        .whereType<Polygon>()
        .toSet();
    final allPoints = widget.parcelas.expand(_polygonPoints).toList();
    final initial = allPoints.isNotEmpty ? allPoints.first : const LatLng(0, 0);

    return AquaCard(
      color: AquaColors.cardGreen,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 420,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initial,
                  zoom: 14,
                ),
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                polygons: polygons,
                onMapCreated: (controller) {
                  _controller = controller;
                  _fitBounds(allPoints);
                },
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AquaColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '●  MAPA LOCAL · NO ES UNA CAPA EN VIVO',
                    style: AquaText.label.copyWith(color: AquaColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Polygon? _toPolygon(Parcela parcela) {
    final points = _polygonPoints(parcela);
    if (points.length < 3) return null;
    return Polygon(
      polygonId: PolygonId(parcela.id),
      points: points,
      fillColor: AquaColors.primary.withValues(alpha: .32),
      strokeColor: AquaColors.primary,
      strokeWidth: 2,
      consumeTapEvents: true,
      onTap: () => _showParcelSheet(context, parcela),
    );
  }

  List<LatLng> _polygonPoints(Parcela parcela) {
    final coordinates = parcela.geoJson['coordinates'];
    if (coordinates is! List ||
        coordinates.isEmpty ||
        coordinates.first is! List) {
      return const [];
    }
    return (coordinates.first as List)
        .whereType<List>()
        .where((pair) => pair.length >= 2)
        .map(
          (pair) =>
              LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble()),
        )
        .toList();
  }

  Future<void> _fitBounds(List<LatLng> points) async {
    if (_controller == null || points.length < 2) return;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    await _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        48,
      ),
    );
  }
}

void _showParcelSheet(BuildContext context, Parcela parcela) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(parcela.nombre, style: AquaText.h2),
          const SizedBox(height: 6),
          Text(
            '${parcela.cultivo} · ${parcela.areaHa.toStringAsFixed(1)} ha',
            style: AquaText.body,
          ),
          const SizedBox(height: 12),
          DemoPill(
            text:
                'Indicador ${parcela.indicadorRiesgo?.toStringAsFixed(0) ?? '--'} / 100',
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            text: 'Ir a evaluación  →',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EvaluationScreen(parcelaId: parcela.id),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _SelectedParcelCard extends StatelessWidget {
  const _SelectedParcelCard({required this.parcela, required this.onRegister});

  final Parcela parcela;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return AquaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PARCELA SELECCIONADA', style: AquaText.label),
          const SizedBox(height: 8),
          Text(parcela.nombre, style: AquaText.h2),
          const SizedBox(height: 8),
          Text(
            '${parcela.cultivo} · ${parcela.areaHa.toStringAsFixed(1)} ha',
            style: AquaText.body,
          ),
          const Divider(height: 40, color: AquaColors.border),
          const Text('Indicador de riesgo', style: AquaText.body),
          Text(
            '${parcela.indicadorRiesgo?.toStringAsFixed(0) ?? '--'} / 100',
            style: const TextStyle(
              fontFamily: AquaText.font,
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: AquaColors.blue,
            ),
          ),
          const Text(
            'Valor demostrativo; depende de la API de riesgo.',
            style: AquaText.small,
          ),
          const SizedBox(height: 24),
          const Text('CAPAS VISIBLES', style: AquaText.label),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DemoPill(text: '☑ Parcela'),
              DemoPill(text: '☑ Riesgo'),
            ],
          ),
          const SizedBox(height: 28),
          PrimaryButton(text: 'Registrar aplicación  →', onPressed: onRegister),
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
