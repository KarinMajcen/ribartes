import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Stric ribič – animiran lik, ki ribiča na zavihku Dovolilnice "nadere".
/// Kaj reče, je odvisno od tega, ali ima ribič veljavno dovolilnico.
///
/// Animacije: prihod iz kota, zibanje, mežikanje, premikanje ust med
/// govorjenjem, izpis besedila črko za črko. Tap na strička = nov stavek.
class StricRibic extends StatefulWidget {
  final bool imaVeljavno;

  /// Ko zavihek postane viden, stric pride znova in začne od začetka.
  final bool aktiven;

  /// Gumb "Kupi dovolilnico" v oblačku (ko ribič nima dovolilnice).
  final VoidCallback? onKupi;

  const StricRibic({
    super.key,
    required this.imaVeljavno,
    this.aktiven = true,
    this.onKupi,
  });

  @override
  State<StricRibic> createState() => _StricRibicState();
}

enum RazpolozenjeStrica { jezen, radoveden, vesel }

class _Stavek {
  final String besedilo;
  final RazpolozenjeStrica razpolozenje;
  const _Stavek(this.besedilo, this.razpolozenje);
}

const _meme = 'Kdo ti je rekel, da lahko tukaj ribariš?!';

// Scenarij, ko ribič NIMA veljavne dovolilnice (slovenska verzija memea).
const _brezDovolilnice = [
  _Stavek(_meme, RazpolozenjeStrica.jezen),
  _Stavek('Državna lastnina, praviš? To ni državna lastnina, to je privatna!',
      RazpolozenjeStrica.jezen),
  _Stavek('Pot pod noge, kolega!', RazpolozenjeStrica.jezen),
  _Stavek('... Ali pa kupi dovolilnico. 🎫', RazpolozenjeStrica.radoveden),
];
const _brezDodatno = [
  _Stavek('Tukaj lovim jaz. Že od leta 1974.', RazpolozenjeStrica.jezen),
  _Stavek('Kaj me gledaš? Dovolilnico pokaži!', RazpolozenjeStrica.jezen),
  _Stavek('Postrv te gleda. In te sodi.', RazpolozenjeStrica.jezen),
  _Stavek('Jaz tukaj lovim že, ko je bil Triglav še hribček.',
      RazpolozenjeStrica.jezen),
];

// Scenarij, ko ribič IMA veljavno dovolilnico: stric ga pusti pri miru.
const _zDovolilnico = [
  _Stavek('Aha, imaš dovolilnico ...', RazpolozenjeStrica.radoveden),
  _Stavek('Potem te pa pustim. Dober prijem! 🎣', RazpolozenjeStrica.vesel),
];
const _zDodatno = [
  _Stavek('Največjo ribo sem ujel lani. Bila je TOLIKŠNA. 👐', RazpolozenjeStrica.vesel),
  _Stavek('Če kaj ujameš, je polovica moja.', RazpolozenjeStrica.vesel),
  _Stavek('Spuščena riba je srečna riba. Pa še +10 točk.', RazpolozenjeStrica.vesel),
  _Stavek('Tiho bodi, ribe poslušajo.', RazpolozenjeStrica.radoveden),
];

class _StricRibicState extends State<StricRibic> with TickerProviderStateMixin {
  late final AnimationController _vstop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _zibanje = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);
  late final AnimationController _usta = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120));

  final _nakljucje = math.Random();
  Timer? _tipkanje;
  Timer? _mezik;
  Timer? _samodejno;

  int _korak = 0; // kateri stavek scenarija
  _Stavek? _stavek;
  String _prikazano = '';
  double _oci = 1; // 1 = odprte, 0 = zaprte
  bool _skrit = false;
  bool _govori_ = false; // ali se besedilo še izpisuje

  /// Gumb za nakup pokažemo, ko je stric izrekel celoten scenarij.
  bool get _pokaziKupi =>
      !widget.imaVeljavno &&
      widget.onKupi != null &&
      !_govori_ &&
      _korak >= _scenarij.length - 1 &&
      _prikazano.isNotEmpty;

  List<_Stavek> get _scenarij =>
      widget.imaVeljavno ? _zDovolilnico : _brezDovolilnice;
  List<_Stavek> get _dodatno => widget.imaVeljavno ? _zDodatno : _brezDodatno;

  @override
  void initState() {
    super.initState();
    _naslednjiMezik();
    if (widget.aktiven) _zacni();
  }

  @override
  void didUpdateWidget(StricRibic star) {
    super.didUpdateWidget(star);
    final postalAktiven = widget.aktiven && !star.aktiven;
    final spremenjenoStanje = widget.imaVeljavno != star.imaVeljavno;
    if (postalAktiven || (widget.aktiven && spremenjenoStanje)) _zacni();
  }

  void _zacni() {
    _samodejno?.cancel();
    _tipkanje?.cancel();
    setState(() {
      _skrit = false;
      _korak = 0;
      _stavek = null;
      _prikazano = '';
    });
    _vstop.forward(from: 0);
    _samodejno = Timer(const Duration(milliseconds: 650), () {
      if (mounted) _govori(_scenarij[0]);
    });
  }

  /// Izpiše stavek črko za črko; med tem se usta odpirajo in zapirajo.
  void _govori(_Stavek stavek) {
    _tipkanje?.cancel();
    _samodejno?.cancel();
    setState(() {
      _stavek = stavek;
      _prikazano = '';
      _govori_ = true;
    });
    _usta.repeat(reverse: true);
    var i = 0;
    _tipkanje = Timer.periodic(const Duration(milliseconds: 38), (t) {
      if (!mounted) return t.cancel();
      i++;
      setState(() => _prikazano = stavek.besedilo.substring(0, i));
      if (i >= stavek.besedilo.length) {
        t.cancel();
        _usta.animateTo(0);
        setState(() => _govori_ = false);
        // Scenarij teče sam do konca, potem stric čaka na tap.
        if (_korak < _scenarij.length - 1) {
          _samodejno = Timer(const Duration(milliseconds: 1400), () {
            if (!mounted) return;
            _korak++;
            _govori(_scenarij[_korak]);
          });
        }
      }
    });
  }

  void _tap() {
    if (_korak < _scenarij.length - 1) {
      _korak++;
      _govori(_scenarij[_korak]);
    } else {
      _govori(_dodatno[_nakljucje.nextInt(_dodatno.length)]);
    }
  }

  void _naslednjiMezik() {
    _mezik = Timer(Duration(milliseconds: 2200 + _nakljucje.nextInt(2500)), () {
      if (!mounted) return;
      setState(() => _oci = 0);
      Timer(const Duration(milliseconds: 130), () {
        if (mounted) setState(() => _oci = 1);
      });
      _naslednjiMezik();
    });
  }

  void _odidi() {
    _tipkanje?.cancel();
    _samodejno?.cancel();
    _usta.animateTo(0);
    _vstop.reverse().then((_) {
      if (mounted) setState(() => _skrit = true);
    });
  }

  @override
  void dispose() {
    _tipkanje?.cancel();
    _mezik?.cancel();
    _samodejno?.cancel();
    _vstop.dispose();
    _zibanje.dispose();
    _usta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_skrit) return const SizedBox.shrink();
    final barve = Theme.of(context).colorScheme;
    final razpolozenje = _stavek?.razpolozenje ?? RazpolozenjeStrica.jezen;

    final vstop = CurvedAnimation(parent: _vstop, curve: Curves.elasticOut,
        reverseCurve: Curves.easeIn);

    return SlideTransition(
      position: Tween(begin: const Offset(1.3, 0.4), end: Offset.zero)
          .animate(vstop),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // --- Oblaček ---
          AnimatedOpacity(
            opacity: _prikazano.isEmpty ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 230),
              child: Semantics(
                liveRegion: true,
                label: 'Stric ribič pravi: ${_stavek?.besedilo ?? ''}',
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 28, 10),
                      decoration: BoxDecoration(
                        color: barve.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: barve.outline, width: 1.5),
                        boxShadow: const [
                          BoxShadow(blurRadius: 6, color: Colors.black26)
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _prikazano,
                            style: TextStyle(
                              color: barve.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            child: _pokaziKupi
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: FilledButton.icon(
                                      icon: const Icon(Icons.shopping_cart,
                                          size: 18),
                                      label: const Text('Kupi dovolilnico'),
                                      onPressed: widget.onKupi,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: InkWell(
                        onTap: _odidi,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close,
                              size: 16, color: barve.onSurfaceVariant),
                        ),
                      ),
                    ),
                    // "Rep" oblačka proti stričkovim ustom.
                    Positioned(
                      right: 52,
                      bottom: -10,
                      child: CustomPaint(
                        size: const Size(18, 12),
                        painter: _RepOblacka(
                            barve.surfaceContainerHighest, barve.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // --- Stric ---
          GestureDetector(
            onTap: _tap,
            child: Semantics(
              button: true,
              label: 'Stric ribič, tapni za nov stavek',
              child: AnimatedBuilder(
                animation: Listenable.merge([_zibanje, _usta]),
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_zibanje.value);
                  return Transform.translate(
                    offset: Offset(0, -3 * t),
                    child: Transform.rotate(
                      angle: (t - 0.5) * 0.08,
                      alignment: Alignment.bottomCenter,
                      child: CustomPaint(
                        size: const Size(120, 150),
                        painter: StricSlikar(
                          usta: _usta.value,
                          oci: _oci,
                          razpolozenje: razpolozenje,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Riše strička: klobuk, obraz, obrvi, oči, nos, brke, usta, telovnik, palico.
class StricSlikar extends CustomPainter {
  final double usta; // 0 = zaprta, 1 = odprta
  final double oci; // 1 = odprte, 0 = zaprte
  final RazpolozenjeStrica razpolozenje;

  StricSlikar({required this.usta, required this.oci, required this.razpolozenje});

  static const _koza = Color(0xFFF2C29B);
  static const _nos = Color(0xFFE59A76);
  static const _brki = Color(0xFFE4E4E4);
  static const _brkiSenca = Color(0xFFBDBDBD);
  static const _klobuk = Color(0xFF8C8F5B);
  static const _klobukTrak = Color(0xFF5E6139);
  static const _telovnik = Color(0xFF5F7A3A);
  static const _srajca = Color(0xFFB5452F);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final p = Paint()..isAntiAlias = true;

    // --- Ribiška palica (za stričkom) ---
    p
      ..color = const Color(0xFF6D4C2F)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(w * 0.14, h * 0.98), Offset(w * 0.02, h * 0.05), p);
    final vrvica = Path()
      ..moveTo(w * 0.02, h * 0.05)
      ..quadraticBezierTo(-w * 0.12, h * 0.4, -w * 0.06, h * 0.7);
    c.drawPath(
        vrvica,
        Paint()
          ..color = Colors.grey.shade500
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    // --- Telo: srajca in telovnik ---
    final telo = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.12, h * 0.69, w * 0.76, h * 0.33),
      topLeft: const Radius.circular(28),
      topRight: const Radius.circular(28),
    );
    c.drawRRect(telo, p..color = _telovnik);
    final ovratnik = Path()
      ..moveTo(w * 0.38, h * 0.69)
      ..lineTo(w * 0.5, h * 0.86)
      ..lineTo(w * 0.62, h * 0.69)
      ..close();
    c.drawPath(ovratnik, p..color = _srajca);
    // žepi telovnika
    p.color = _klobukTrak;
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.2, h * 0.84, w * 0.16, h * 0.07),
            const Radius.circular(3)),
        p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.64, h * 0.84, w * 0.16, h * 0.07),
            const Radius.circular(3)),
        p);

    // --- Ušesa in glava ---
    final glavaS = Offset(w * 0.5, h * 0.47);
    final r = w * 0.3;
    p.color = _koza;
    c.drawCircle(Offset(glavaS.dx - r, glavaS.dy + 4), r * 0.22, p);
    c.drawCircle(Offset(glavaS.dx + r, glavaS.dy + 4), r * 0.22, p);
    c.drawCircle(glavaS, r, p);

    // rdeča lica, ko je jezen
    if (razpolozenje == RazpolozenjeStrica.jezen) {
      p.color = Colors.red.withValues(alpha: 0.25);
      c.drawCircle(Offset(glavaS.dx - r * 0.55, glavaS.dy + r * 0.25), r * 0.2, p);
      c.drawCircle(Offset(glavaS.dx + r * 0.55, glavaS.dy + r * 0.25), r * 0.2, p);
    }

    // --- Obrvi (košate, bele) ---
    final obrvi = Paint()
      ..color = _brki
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final yObrv = glavaS.dy - r * 0.32;
    // jezen: notranja konca nižje; radoveden: ena dvignjena; vesel: ravne in visoko
    final (lNot, dNot, lZun, dZun) = switch (razpolozenje) {
      RazpolozenjeStrica.jezen => (8.0, 8.0, -2.0, -2.0),
      RazpolozenjeStrica.radoveden => (0.0, -6.0, 0.0, -2.0),
      RazpolozenjeStrica.vesel => (-3.0, -3.0, 0.0, 0.0),
    };
    c.drawLine(Offset(glavaS.dx - r * 0.62, yObrv + lZun),
        Offset(glavaS.dx - r * 0.15, yObrv + lNot), obrvi);
    c.drawLine(Offset(glavaS.dx + r * 0.15, yObrv + dNot),
        Offset(glavaS.dx + r * 0.62, yObrv + dZun), obrvi);

    // --- Oči (mežikanje = višina elipse) ---
    p.color = const Color(0xFF2B2B2B);
    final yOci = glavaS.dy - r * 0.1;
    for (final x in [glavaS.dx - r * 0.38, glavaS.dx + r * 0.38]) {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(x, yOci), width: 7, height: math.max(1.2, 9 * oci)),
          p);
    }

    // --- Nos ---
    c.drawCircle(Offset(glavaS.dx, glavaS.dy + r * 0.18), r * 0.2,
        p..color = _nos);

    // --- Usta (pod brki) ---
    final yUsta = glavaS.dy + r * 0.62;
    if (razpolozenje == RazpolozenjeStrica.vesel && usta < 0.05) {
      c.drawArc(
          Rect.fromCenter(center: Offset(glavaS.dx, yUsta - 4), width: 20, height: 14),
          0.2,
          math.pi - 0.4,
          false,
          Paint()
            ..color = const Color(0xFF7A2E1F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
    } else {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(glavaS.dx, yUsta),
              width: 14,
              height: 2 + 10 * usta),
          p..color = const Color(0xFF7A2E1F));
    }

    // --- Brki (veliki, sivi) ---
    final yBrki = glavaS.dy + r * 0.4;
    for (final smer in [-1.0, 1.0]) {
      final brk = Path()
        ..moveTo(glavaS.dx, yBrki - 2)
        ..quadraticBezierTo(glavaS.dx + smer * r * 0.35, yBrki - 10,
            glavaS.dx + smer * r * 0.75, yBrki + 2)
        ..quadraticBezierTo(glavaS.dx + smer * r * 0.85, yBrki + 10,
            glavaS.dx + smer * r * 0.6, yBrki + 8)
        ..quadraticBezierTo(glavaS.dx + smer * r * 0.3, yBrki + 12,
            glavaS.dx, yBrki + 5)
        ..close();
      c.drawPath(brk, p..color = _brkiSenca);
      c.save();
      c.translate(0, -1.5);
      c.drawPath(brk, p..color = _brki);
      c.restore();
    }

    // --- Ribiški klobuk ---
    final yKrajevca = glavaS.dy - r * 0.62;
    c.drawOval(
        Rect.fromCenter(
            center: Offset(glavaS.dx, yKrajevca), width: r * 2.6, height: r * 0.5),
        p..color = _klobuk);
    final kapa = RRect.fromRectAndCorners(
      Rect.fromLTWH(glavaS.dx - r * 0.78, yKrajevca - r * 0.72, r * 1.56, r * 0.72),
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
    );
    c.drawRRect(kapa, p..color = _klobuk);
    c.drawRect(
        Rect.fromLTWH(glavaS.dx - r * 0.78, yKrajevca - r * 0.22, r * 1.56, r * 0.16),
        p..color = _klobukTrak);
    // muharska muha za trakom
    final muha = Offset(glavaS.dx + r * 0.45, yKrajevca - r * 0.2);
    c.drawCircle(muha, 3.5, p..color = const Color(0xFFE53935));
    c.drawLine(
        muha,
        muha.translate(7, -9),
        Paint()
          ..color = const Color(0xFFFFC107)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
    c.drawLine(
        muha,
        muha.translate(10, -3),
        Paint()
          ..color = const Color(0xFF4CAF50)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(StricSlikar o) =>
      o.usta != usta || o.oci != oci || o.razpolozenje != razpolozenje;
}

/// Trikotni "rep" oblačka.
class _RepOblacka extends CustomPainter {
  final Color polnilo;
  final Color rob;
  _RepOblacka(this.polnilo, this.rob);

  @override
  void paint(Canvas c, Size s) {
    final pot = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width * 0.75, s.height)
      ..close();
    c.drawPath(pot, Paint()..color = polnilo);
    c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(s.width * 0.75, s.height)
          ..lineTo(s.width, 0),
        Paint()
          ..color = rob
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_RepOblacka o) => o.polnilo != polnilo || o.rob != rob;
}

/// Majhen stric z oblačkom, ki pove en stavek (npr. komentar na zaslonu čuvaja).
/// Ob vsakem novem besedilu ga izpiše črko za črko in med tem premika usta.
class StricKomentar extends StatefulWidget {
  final String besedilo;
  final RazpolozenjeStrica razpolozenje;

  const StricKomentar({
    super.key,
    required this.besedilo,
    this.razpolozenje = RazpolozenjeStrica.radoveden,
  });

  @override
  State<StricKomentar> createState() => _StricKomentarState();
}

class _StricKomentarState extends State<StricKomentar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _usta = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120));
  Timer? _tipkanje;
  String _prikazano = '';

  @override
  void initState() {
    super.initState();
    _govori();
  }

  @override
  void didUpdateWidget(StricKomentar star) {
    super.didUpdateWidget(star);
    if (star.besedilo != widget.besedilo) _govori();
  }

  void _govori() {
    _tipkanje?.cancel();
    _prikazano = '';
    _usta.repeat(reverse: true);
    var i = 0;
    _tipkanje = Timer.periodic(const Duration(milliseconds: 35), (t) {
      if (!mounted) return t.cancel();
      i++;
      setState(() => _prikazano = widget.besedilo.substring(0, i));
      if (i >= widget.besedilo.length) {
        t.cancel();
        _usta.animateTo(0);
      }
    });
  }

  @override
  void dispose() {
    _tipkanje?.cancel();
    _usta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Stric ribič pravi: ${widget.besedilo}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 72,
            height: 90,
            child: FittedBox(
              child: AnimatedBuilder(
                animation: _usta,
                builder: (context, _) => CustomPaint(
                  size: const Size(120, 150),
                  painter: StricSlikar(
                    usta: _usta.value,
                    oci: 1,
                    razpolozenje: widget.razpolozenje,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Text(
                _prikazano,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
