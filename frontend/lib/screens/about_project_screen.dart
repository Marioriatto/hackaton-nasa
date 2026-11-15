import 'package:flutter/material.dart';

import 'aqua_debt_tokens.dart';

class AboutProjectScreen extends StatelessWidget {
  const AboutProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AquaScaffold(
      activeItem: 'Acerca del proyecto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(kicker: 'PROYECTO', title: 'AquaDebt'),
          SizedBox(height: 28),
          AquaCard(
            child: Text(
              'AquaDebt es un prototipo científico para visualizar condiciones potenciales de transporte de nutrientes en una parcela piloto. '
              'La experiencia usa datos demostrativos y estructura explicable para comunicar riesgo de forma simple a usuarios no técnicos.',
              style: AquaText.body,
            ),
          ),
          SizedBox(height: 18),
          AquaCard(
            color: AquaColors.footer,
            child: Text(
              'Prototipo, no observaciones reales.\n'
              'No confirma contaminación del agua subterránea y no reemplaza asesoría técnica.',
              style: AquaText.small,
            ),
          ),
        ],
      ),
    );
  }
}
