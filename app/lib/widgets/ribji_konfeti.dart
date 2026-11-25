import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Konfeti iz ribic: ribice padajo z vrha zaslona, se vrtijo in zibljejo.
/// Uporaba: [RibjiKonfeti.pokazi] ga za nekaj sekund položi čez cel zaslon.
class RibjiKonfeti extends StatefulWidget {
  const RibjiKonfeti({super.key});

  /// Prikaže konfete čez celotno aplikacijo in jih po koncu sam odstrani.
  static void pokazi(BuildContext context) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry vnos;
    vnos = OverlayEntry(
      builder: (_) => const IgnorePointer(child: RibjiKonfeti()),
    );
    overlay.insert(vnos);
    Future.delayed(const Duration(milliseconds: 3200), vnos.remove);
  }

  @override
  State<RibjiKonfeti> createState() => _RibjiKonfetiState();
}

class _Delec {
  final double x; // začetni vodoravni položaj (0..1)
  final double zamik; // kdaj začne padati (0..0.4)
  final double hitrost; // 0.7..1.3
  final double vrtenje; // obratov med padanjem
  final double nihaj; // širina zibanja
  final String emoji;
  final double velikost;

  _Delec(math.Random r)
      : x = r.nextDouble(),
        zamik = r.nextDouble() * 0.4,
        hitrost = 0.7 + r.nextDouble() * 0.6,
        vrtenje = (r.nextDouble() - 0.5) * 4,
        nihaj = 10 + r.nextDouble() * 30,
        emoji = const ['🐟', '🐠', '🐡', '🎣', '⭐'][r.nextInt(5)],
        velikost = 20 + r.nextDouble() * 18;
}

class _RibjiKonfetiState extends State<RibjiKonfeti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cas = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3000))
    ..forward();
  final _delci = List.generate(45, (_) => _Delec(math.Random()));

  @override
  void dispose() {
    _cas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cas,
      builder: (context, _) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _KonfetiSlikar(_delci, _cas.value),
      ),
    );
  }
}

class _KonfetiSlikar extends CustomPainter {
  final List<_Delec> delci;
  final double t;
  _KonfetiSlikar(this.delci, this.t);

  @override
  void paint(Canvas c, Size s) {
    for (final d in delci) {
      final lokalni = ((t - d.zamik) / (1 - d.zamik)).clamp(0.0, 1.0);
      if (lokalni <= 0) continue;
      final y = -50 + (s.height + 100) * lokalni * d.hitrost;
      final x = d.x * s.width + math.sin(lokalni * 10 + d.x * 6) * d.nihaj;
      // proti koncu zbledijo
      final prosojnost = lokalni > 0.8 ? (1 - lokalni) / 0.2 : 1.0;

      final tp = TextPainter(
        text: TextSpan(
          text: d.emoji,
          style: TextStyle(
            fontSize: d.velikost,
            color: Colors.black.withValues(alpha: prosojnost),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      c.save();
      c.translate(x, y);
      c.rotate(lokalni * d.vrtenje * math.pi);
      tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_KonfetiSlikar o) => o.t != t;
}
