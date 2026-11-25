import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Uvodni zaslon ob zagonu: riba skoči iz vode v loku, za njo kapljice,
/// nato se pokažeta ime aplikacije in slogan. Traja okoli 2 sekundi.
class UvodniZaslon extends StatefulWidget {
  const UvodniZaslon({super.key});

  @override
  State<UvodniZaslon> createState() => _UvodniZaslonState();
}

class _UvodniZaslonState extends State<UvodniZaslon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cas = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1900))
    ..forward();

  @override
  void dispose() {
    _cas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Napis se pokaže v drugi polovici animacije.
    final napis = CurvedAnimation(
        parent: _cas, curve: const Interval(0.5, 1, curve: Curves.easeOut));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4FB3D9), Color(0xFF1B6E8C), Color(0xFF0E4A5F)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _cas,
                builder: (context, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _SkokRibe(_cas.value),
                ),
              ),
            ),
            FadeTransition(
              opacity: napis,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                    .animate(napis),
                child: const Column(
                  children: [
                    Text(
                      'RIBARTes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lovim, torej sem',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class _SkokRibe extends CustomPainter {
  final double t; // 0..1
  _SkokRibe(this.t);

  @override
  void paint(Canvas c, Size s) {
    final gladina = s.height * 0.72;

    // Voda
    c.drawRect(Rect.fromLTWH(0, gladina, s.width, s.height - gladina),
        Paint()..color = Colors.white.withValues(alpha: 0.12));
    final val = Path()..moveTo(0, gladina);
    for (double x = 0; x <= s.width; x += 4) {
      val.lineTo(x, gladina + math.sin(x / 30 + t * 8) * 4);
    }
    c.drawPath(
        val,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    // Skok: riba potuje po paraboli od leve proti desni (t med 0 in 0.75).
    final skok = (t / 0.75).clamp(0.0, 1.0);
    final x = s.width * (0.2 + 0.6 * skok);
    final visinaSkoka = s.height * 0.38;
    final y = gladina - 4 * visinaSkoka * skok * (1 - skok);
    // nagib ribe sledi smeri leta
    final nagib = math.atan2(-4 * visinaSkoka * (1 - 2 * skok), s.width * 0.6);

    // Kapljice ob izstopu in vstopu
    final kapljica = Paint()..color = Colors.white.withValues(alpha: 0.8);
    for (final (zacetek, mesto) in [(0.0, 0.2), (0.95, 0.8)]) {
      final k = ((skok - zacetek).abs() < 0.25)
          ? 1 - (skok - zacetek).abs() / 0.25
          : 0.0;
      if (k <= 0) continue;
      for (var i = 0; i < 6; i++) {
        final kot = -math.pi / 2 + (i - 2.5) * 0.35;
        final r = 30 * (1 - k) + 6;
        c.drawCircle(
          Offset(s.width * mesto + math.cos(kot) * r,
              gladina + math.sin(kot) * r),
          3 * k + 1,
          kapljica,
        );
      }
    }

    // Riba (pod gladino je ne rišemo)
    if (y < gladina + 10 && skok > 0 && skok < 1) {
      c.save();
      c.translate(x, y);
      c.rotate(nagib);
      final telo = Paint()..color = Colors.white;
      c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 70, height: 30), telo);
      c.drawPath(
          Path()
            ..moveTo(-28, 0)
            ..lineTo(-52, -16)
            ..lineTo(-52, 16)
            ..close(),
          telo);
      c.drawCircle(const Offset(20, -4), 3.5,
          Paint()..color = const Color(0xFF0E4A5F));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_SkokRibe o) => o.t != t;
}
