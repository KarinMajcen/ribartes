import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import '../tema/tema.dart';

/// Animirana glava domačega zaslona: pozdrav glede na uro, nasvet dneva,
/// valovi, ki se premikajo, in ribica, ki plava čez.
class ValoviGlava extends StatefulWidget {
  final String ime;
  const ValoviGlava({super.key, required this.ime});

  @override
  State<ValoviGlava> createState() => _ValoviGlavaState();
}

const _nasveti = [
  'Ob oblačnem vremenu ribe prijemajo bolje.',
  'Najboljši ribolov je ob zori in mraku.',
  'Spuščena riba je jutri večja riba.',
  'Senca ribiča na vodi prestraši postrv.',
  'Mokre roke, preden primeš ribo – tako ji ne poškoduješ sluzi.',
  'Po nevihti je voda kalna, poskusi z večjo vabo.',
  'Tiho ob vodi: ribe čutijo tresljaje korakov.',
];

class _ValoviGlavaState extends State<ValoviGlava>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cas = AnimationController(
      vsync: this, duration: const Duration(seconds: 8))
    ..repeat();

  String get _pozdrav {
    final ura = DateTime.now().hour;
    if (ura >= 5 && ura < 11) return 'Dobro jutro';
    if (ura >= 11 && ura < 18) return 'Dober dan';
    if (ura >= 18 && ura < 22) return 'Dober večer';
    return 'Lahko noč';
  }

  /// Noč: od 20. do 6. ure – temno nebo, luna in zvezde.
  bool get _noc {
    final ura = DateTime.now().hour;
    return ura >= 20 || ura < 6;
  }

  String get _nasvet {
    final z = DateTime.now();
    final danVLetu = z.difference(DateTime(z.year)).inDays;
    return _nasveti[danVLetu % _nasveti.length];
  }

  @override
  void dispose() {
    _cas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;
    final ime = widget.ime.isEmpty ? 'ribič' : widget.ime;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _noc
                ? const [Color(0xFF0B1D3A), Color(0xFF1F2F5C)]
                : const [Paleta.soca, Paleta.tolmun],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _cas,
                builder: (context, _) => CustomPaint(
                  painter: _Valovi(_cas.value, noc: _noc),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_pozdrav, $ime!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Nasvet dneva: $_nasvet',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dva sloja sinusnih valov in ribica, ki plava čez sliko.
class _Valovi extends CustomPainter {
  final double t; // 0..1, ponavlja se
  final bool noc;
  _Valovi(this.t, {this.noc = false});

  /// Zvezde na stalnih mestih (seme 7), vsaka utripa v svojem ritmu.
  void _zvezde(Canvas c, Size s) {
    final r = math.Random(7);
    for (var i = 0; i < 28; i++) {
      final x = r.nextDouble() * s.width;
      final y = r.nextDouble() * s.height * 0.6;
      final utrip = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 3 + i));
      c.drawCircle(Offset(x, y), 0.8 + r.nextDouble() * 1.3,
          Paint()..color = Colors.white.withValues(alpha: utrip));
    }
  }

  /// Polmesec: svetel krog, ki ga deloma prekrije krog barve neba.
  void _luna(Canvas c, Size s) {
    final sredisce = Offset(s.width - 48, 34);
    c.drawCircle(sredisce, 22,
        Paint()
          ..color = const Color(0xFFFFF59D).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    c.drawCircle(sredisce, 16, Paint()..color = const Color(0xFFFFF8E1));
    c.drawCircle(sredisce.translate(7, -5), 14,
        Paint()..color = const Color(0xFF15264A));
  }

  void _val(Canvas c, Size s, double visina, double amplituda, double faza,
      Color barva) {
    final pot = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width; x += 4) {
      final y = s.height -
          visina +
          math.sin((x / s.width * 2 * math.pi * 1.5) + faza) * amplituda;
      pot.lineTo(x, y);
    }
    pot
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(pot, Paint()..color = barva);
  }

  @override
  void paint(Canvas c, Size s) {
    final faza = t * 2 * math.pi;
    if (noc) {
      _zvezde(c, s);
      _luna(c, s);
    }

    // Ribica plava od leve proti desni in se rahlo pozibava.
    final x = -30 + (s.width + 60) * t;
    final y = s.height - 34 + math.sin(faza * 3) * 4;
    c.save();
    c.translate(x, y);
    final riba = Paint()..color = Colors.white.withValues(alpha: 0.85);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 22, height: 11), riba);
    c.drawPath(
        Path()
          ..moveTo(-9, 0)
          ..lineTo(-17, -6)
          ..lineTo(-17, 6)
          ..close(),
        riba);
    c.drawCircle(const Offset(6, -1.5), 1.5,
        Paint()..color = Paleta.tolmun);
    c.restore();

    _val(c, s, 28, 6, faza, Colors.white.withValues(alpha: 0.18));
    _val(c, s, 18, 5, -faza * 1.3 + 1, Colors.white.withValues(alpha: 0.28));
  }

  @override
  bool shouldRepaint(_Valovi o) => o.t != t || o.noc != noc;
}
