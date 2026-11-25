import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Barvni preliv za vsako reko (barva vode, kot jo poznamo).
List<Color> barveReke(String reka) {
  switch (reka.toLowerCase()) {
    case 'soča':
      return const [Color(0xFF2BB5A0), Color(0xFF0E7C6B)]; // smaragdna
    case 'sava bohinjka':
      return const [Color(0xFF5FA8D3), Color(0xFF1F5F8B)]; // alpsko modra
    case 'krka':
      return const [Color(0xFF8DB062), Color(0xFF3F6B2A)]; // zelena
    case 'kolpa':
      return const [Color(0xFF45B7BC), Color(0xFF147A80)]; // topla turkizna
    case 'ljubljanica':
      return const [Color(0xFF94A374), Color(0xFF4B5A35)]; // močvirsko olivna
    default:
      return const [Color(0xFF2BB5A0), Color(0xFF0D3B36)];
  }
}

/// Barvna glava z valovi za revir – uporabljena na seznamu in v podrobnostih.
/// Zaradi skupnega Hero taga se kartica ob tapu gladko razširi v glavo zaslona.
class RekaGlava extends StatelessWidget {
  final String reka;
  final double visina;
  final Widget? otrok;
  final BorderRadius zaobljenost;

  const RekaGlava({
    super.key,
    required this.reka,
    this.visina = 72,
    this.otrok,
    this.zaobljenost = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final barve = barveReke(reka);
    return ClipRRect(
      borderRadius: zaobljenost,
      child: Container(
        height: visina,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: barve,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MirniValovi())),
            if (otrok != null) Positioned.fill(child: otrok!),
          ],
        ),
      ),
    );
  }
}

class _MirniValovi extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    void val(double odDna, double amp, double faza, double prosojnost) {
      final pot = Path()..moveTo(0, s.height);
      for (double x = 0; x <= s.width; x += 4) {
        pot.lineTo(
            x,
            s.height -
                odDna +
                math.sin(x / s.width * 2 * math.pi * 2 + faza) * amp);
      }
      pot
        ..lineTo(s.width, s.height)
        ..close();
      c.drawPath(pot,
          Paint()..color = Colors.white.withValues(alpha: prosojnost));
    }

    val(s.height * 0.35, 5, 0, 0.12);
    val(s.height * 0.2, 4, 2, 0.18);
  }

  @override
  bool shouldRepaint(_MirniValovi o) => false;
}
