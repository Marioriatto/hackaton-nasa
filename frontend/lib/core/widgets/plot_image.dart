import 'package:flutter/material.dart';

import '../../screens/aqua_debt_tokens.dart';
import '../api/api_client.dart';

class PlotImage extends StatefulWidget {
  const PlotImage({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<PlotImage> createState() => _PlotImageState();
}

class _PlotImageState extends State<PlotImage> {
  int _retry = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) {
      return _PlotPlaceholder(title: widget.title);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        widget.url,
        key: ValueKey(_retry),
        headers: ApiClient().headers,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _PlotSkeleton();
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
            padding: const EdgeInsets.all(18),
            color: AquaColors.footer,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No se pudo cargar el recurso gráfico.',
                  style: AquaText.body,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _retry++),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlotSkeleton extends StatelessWidget {
  const _PlotSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AquaColors.footer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 16, width: 180, color: AquaColors.border),
          const SizedBox(height: 16),
          Expanded(child: Container(color: AquaColors.border)),
        ],
      ),
    );
  }
}

class _PlotPlaceholder extends StatelessWidget {
  const _PlotPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AquaColors.footer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AquaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AquaText.label),
          const Spacer(),
          const Text(
            'Gráfico disponible cuando el backend entregue la URL del análisis.',
            style: AquaText.body,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: .72,
              minHeight: 10,
              color: AquaColors.blue,
              backgroundColor: AquaColors.border,
            ),
          ),
        ],
      ),
    );
  }
}
