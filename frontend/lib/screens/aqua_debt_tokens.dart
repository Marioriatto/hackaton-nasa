import 'package:flutter/material.dart';

/// Visual tokens extracted from the AquaDebt Figma design.
class AquaColors {
  static const background = Color(0xFFF5F8F5);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF174D3C);
  static const primarySoft = Color(0xFFEAF3ED);
  static const muted = Color(0xFF61786D);
  static const body = Color(0xFF52665B);
  static const blue = Color(0xFF168CB5);
  static const cardGreen = Color(0xFFDFE9DC);
  static const footer = Color(0xFFEAF1EB);
  static const chip = Color(0xFFF0F5F1);
  static const border = Color(0xFFDCE6DD);
  static const accentGreen = Color(0xFF39A56B);
  static const successSoft = Color(0xFFE0EEE5);
  static const warning = Color(0xFFFFF2CA);
  static const warningText = Color(0xFF775D10);
  static const warningDark = Color(0xFF604E18);
  static const progressWarning = Color(0xFFD6B75D);
  static const scenario = Color(0xFFE8EFEB);
  static const footerText = Color(0xFF345A49);
  static const successMuted = Color(0xFFB4D8C2);
}

class AquaText {
  static const font = 'Inter';

  static const title = TextStyle(
    fontFamily: font,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AquaColors.primary,
  );

  static const h1 = TextStyle(
    fontFamily: font,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AquaColors.primary,
  );

  static const h2 = TextStyle(
    fontFamily: font,
    fontSize: 25,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AquaColors.primary,
  );

  static const label = TextStyle(
    fontFamily: font,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: .2,
    color: AquaColors.muted,
  );

  static const body = TextStyle(
    fontFamily: font,
    fontSize: 14,
    height: 1.45,
    color: AquaColors.body,
  );

  static const small = TextStyle(
    fontFamily: font,
    fontSize: 12,
    height: 1.45,
    color: AquaColors.body,
  );
}

class AquaScaffold extends StatelessWidget {
  const AquaScaffold({
    super.key,
    required this.activeItem,
    required this.child,
    this.footer = true,
  });

  final String activeItem;
  final Widget child;
  final bool footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AquaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AquaHeader(activeItem: activeItem),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: child,
                ),
              ),
            ),
            if (footer) const AquaFooter(),
          ],
        ),
      ),
    );
  }
}

class AquaHeader extends StatelessWidget {
  const AquaHeader({super.key, required this.activeItem});

  final String activeItem;

  static void navigate(BuildContext context, String item) {
    final route = switch (item) {
      'Inicio' => '/home',
      'Mapa' => '/map',
      'Registrar aplicación' => '/application',
      'Evaluación' => '/evaluation',
      'Acerca del proyecto' => '/about',
      _ => null,
    };
    if (route == null) return;
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      'Inicio',
      'Mapa',
      'Registrar aplicación',
      'Evaluación',
      'Acerca del proyecto',
    ];

    return Container(
      color: AquaColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AquaColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '≈',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AquaDebt', style: AquaText.title),
                  Text(
                    'OBSERVAR. PREVENIR. PROTEGER.',
                    style: TextStyle(
                      fontFamily: AquaText.font,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: AquaColors.muted,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const DemoPill(text: '●  Modo demostración'),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in items) ...[
                  NavChip(
                    text: item,
                    selected: item == activeItem,
                    onTap: item == activeItem
                        ? null
                        : () => navigate(context, item),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavChip extends StatelessWidget {
  const NavChip({
    super.key,
    required this.text,
    this.selected = false,
    this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        hoverColor: AquaColors.primarySoft,
        splashColor: AquaColors.primarySoft,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AquaColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: AquaText.font,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AquaColors.primary : AquaColors.body,
            ),
          ),
        ),
      ),
    );
  }
}

class DemoPill extends StatelessWidget {
  const DemoPill({super.key, required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: warning ? AquaColors.warning : AquaColors.chip,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: AquaText.small.copyWith(
          fontWeight: FontWeight.w600,
          color: warning ? AquaColors.warningText : AquaColors.body,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.subtitle,
  });

  final String kicker;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker, style: AquaText.label.copyWith(color: AquaColors.blue)),
        const SizedBox(height: 8),
        Text(title, style: AquaText.h1),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: AquaText.body),
        ],
      ],
    );
  }
}

class AquaCard extends StatelessWidget {
  const AquaCard({
    super.key,
    required this.child,
    this.color = AquaColors.surface,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.text, this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AquaColors.primary,
          foregroundColor: AquaColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: AquaText.font,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

class AquaFooter extends StatelessWidget {
  const AquaFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AquaColors.footer,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Este indicador muestra condiciones potenciales de transporte de nutrientes. No confirma contaminación del agua subterránea.',
            style: TextStyle(
              fontFamily: AquaText.font,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF345A49),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'AquaDebt | NASA Space Apps Challenge 2026',
            style: AquaText.small,
          ),
          Text(
            'Prototipo científico · Datos de ejemplo, no observaciones reales',
            style: AquaText.small,
          ),
        ],
      ),
    );
  }
}
