import 'dart:io';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/revir.dart';
import '../models/ulov.dart';
import '../models/vrsta_ribe.dart';
import '../services/revir_service.dart';
import '../services/ulov_service.dart';
import '../widgets/ribji_konfeti.dart';

/// Zaslon "Nov ulov" – pokriva US-07 (in US-09: ujemi in spusti).
class NovUlovScreen extends StatefulWidget {
  const NovUlovScreen({super.key});

  @override
  State<NovUlovScreen> createState() => _NovUlovScreenState();
}

class _NovUlovScreenState extends State<NovUlovScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dolzinaCtrl = TextEditingController();
  final _tezaCtrl = TextEditingController();
  final _service = UlovService();

  late final Stream<List<VrstaRibe>> _vrsteTok = _service.vrsteRib();
  late final Stream<List<Revir>> _revirjiTok = RevirService().vsiRevirji();

  // V spustnih seznamih hranimo ID-je (nizi se primerjajo zanesljivo).
  String? _vrstaId;
  String? _revirId;
  Map<String, VrstaRibe> _vrste = {};
  Map<String, Revir> _revirji = {};

  XFile? _foto;
  bool _spuscena = false;
  bool _nalaganje = false;
  String? _napaka;

  @override
  void dispose() {
    _dolzinaCtrl.dispose();
    _tezaCtrl.dispose();
    super.dispose();
  }

  double? _stevilo(String besedilo) =>
      double.tryParse(besedilo.trim().replaceAll(',', '.'));

  Future<void> _izberiFoto(ImageSource vir) async {
    try {
      final foto = await ImagePicker().pickImage(
        source: vir,
        maxWidth: 1600, // manjša datoteka, dovolj ostra za album
        imageQuality: 75,
      );
      if (foto != null) setState(() => _foto = foto);
    } on PlatformException {
      // Scenarij "zavrnjeno dovoljenje za kamero" iz US-07.
      setState(() => _napaka = vir == ImageSource.camera
          ? 'Brez dovoljenja za kamero fotografije ni mogoče dodati.'
          : 'Brez dovoljenja za galerijo fotografije ni mogoče dodati.');
    }
  }

  Future<void> _shrani() async {
    setState(() => _napaka = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _nalaganje = true);
    try {
      final vrsta = _vrste[_vrstaId]!;
      final fotoPot =
          _foto == null ? null : await _service.shraniFotografijo(_foto!);

      final rezultat = await _service.shrani(
        vrsta: vrsta,
        revir: _revirId == null ? null : _revirji[_revirId],
        dolzinaCm: _stevilo(_dolzinaCtrl.text)!,
        tezaKg: _stevilo(_tezaCtrl.text),
        fotoPot: fotoPot,
        spuscena: _spuscena,
      );
      if (!mounted) return;

      // US-08: prvi ulov te vrste odklene kartico – s konfeti iz ribic.
      if (rezultat.novaKartica) {
        // Po izrisu okna, da konfeti padajo NAD oknom "Nova kartica!".
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) RibjiKonfeti.pokazi(context);
        });
        HapticFeedback.heavyImpact(); // telefon zavibrira
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            // Pokal "poskoči" in se zavrti v pravi položaj.
            icon: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.elasticOut,
              builder: (context, v, child) => Transform.rotate(
                angle: (1 - v) * 0.8,
                child: Transform.scale(scale: v, child: child),
              ),
              child: const Icon(Icons.emoji_events,
                  size: 72, color: Color(0xFFFFB300)),
            ),
            title: Text(vrsta.redka ? '✨ Redka kartica! ✨' : 'Nova kartica!'),
            content: Text(
              '${vrsta.ime[0].toUpperCase()}${vrsta.ime.substring(1)} je '
              'zdaj v tvojem ribjem albumu.',
              textAlign: TextAlign.center,
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Super!'),
              ),
            ],
          ),
        );
        if (!mounted) return;
      }

      final sporocila = <String>[
        if (rezultat.prejeteTocke > 0)
          '+${rezultat.prejeteTocke} točk za ujemi in spusti!'
        else
          'Ulov je shranjen.',
        if (!rezultat.poslano) 'Ni povezave – ulov bo poslan, ko bo povezava.',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sporocila.join(' '))),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _napaka = 'Ulova ni bilo mogoče shraniti.');
    } finally {
      if (mounted) setState(() => _nalaganje = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nov ulov')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Vrsta ribe (obvezno) ---
            StreamBuilder<List<VrstaRibe>>(
              stream: _vrsteTok,
              builder: (context, snapshot) {
                final seznam = snapshot.data ?? [];
                _vrste = {for (final v in seznam) v.id: v};
                return DropdownButtonFormField<String>(
                  initialValue: _vrstaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Vrsta ribe *',
                    prefixIcon: Icon(Icons.phishing),
                  ),
                  items: [
                    for (final v in seznam)
                      DropdownMenuItem(value: v.id, child: Text(v.ime)),
                  ],
                  onChanged: (id) => setState(() => _vrstaId = id),
                  validator: (id) => id == null ? 'Izberite vrsto ribe.' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // --- Revir (neobvezno, potreben za lestvico po rekah) ---
            StreamBuilder<List<Revir>>(
              stream: _revirjiTok,
              builder: (context, snapshot) {
                final seznam = snapshot.data ?? [];
                _revirji = {for (final r in seznam) r.id: r};
                return DropdownButtonFormField<String?>(
                  initialValue: _revirId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Revir',
                    prefixIcon: Icon(Icons.water),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Brez revirja')),
                    for (final r in seznam)
                      DropdownMenuItem<String?>(value: r.id, child: Text(r.ime)),
                  ],
                  onChanged: (id) => setState(() => _revirId = id),
                );
              },
            ),
            const SizedBox(height: 16),

            // --- Ravnilo: drsnik in riba, ki raste ---
            _Ravnilo(
              dolzina: _stevilo(_dolzinaCtrl.text) ?? 0,
              onSpremeni: (cm) => setState(
                  () => _dolzinaCtrl.text = cm.toStringAsFixed(0)),
            ),
            const SizedBox(height: 8),

            // --- Mere ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dolzinaCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Dolžina *',
                      suffixText: 'cm',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final x = _stevilo(v ?? '');
                      if (x == null) return 'Vnesite dolžino.';
                      if (x <= 0 || x > 300) return 'Med 1 in 300 cm.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tezaCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Teža',
                      suffixText: 'kg',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null; // neobvezno
                      final x = _stevilo(v);
                      if (x == null || x <= 0 || x > 150) {
                        return 'Med 0 in 150 kg.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Fotografija ---
            if (_foto != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_foto!.path),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      tooltip: 'Odstrani fotografijo',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _foto = null),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Fotografiraj'),
                      onPressed: () => _izberiFoto(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Iz galerije'),
                      onPressed: () => _izberiFoto(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),

            // --- Ujemi in spusti (US-09) ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.eco),
              title: const Text('Vrnjena v reko'),
              subtitle: Text('Ujemi in spusti: +${Tocke.zaSpuscenoRibo} točk'),
              value: _spuscena,
              onChanged: (v) => setState(() => _spuscena = v),
            ),

            if (_napaka != null) ...[
              const SizedBox(height: 8),
              Text(_napaka!,
                  style: TextStyle(color: barve.error),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: _nalaganje
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Shrani'),
            onPressed: _nalaganje ? null : _shrani,
          ),
        ),
      ),
    );
  }
}

/// Ravnilo: riba, ki raste z dolžino, merilo v cm in drsnik.
class _Ravnilo extends StatelessWidget {
  final double dolzina;
  final ValueChanged<double> onSpremeni;
  const _Ravnilo({required this.dolzina, required this.onSpremeni});

  static const _najvec = 120.0;

  String get _opis {
    if (dolzina <= 0) return 'Povleci drsnik ali vpiši dolžino';
    if (dolzina < 20) return 'Ribica za akvarij 🐠';
    if (dolzina < 35) return 'Lepa riba 👍';
    if (dolzina < 50) return 'Kar spodobna! 💪';
    if (dolzina < 60) return 'Kapitalec! 🏆';
    return 'To pa ni od muh! 🐋';
  }

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;
    final vrednost = dolzina.clamp(0.0, _najvec);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          children: [
            SizedBox(
              height: 70,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: vrednost),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                builder: (context, v, _) => CustomPaint(
                  size: const Size(double.infinity, 70),
                  painter: _RibaNaRavnilu(
                    delez: v / _najvec,
                    riba: barve.primary,
                    crte: barve.outline,
                  ),
                ),
              ),
            ),
            Text(
              dolzina > 0
                  ? '${dolzina.toStringAsFixed(0)} cm · $_opis'
                  : _opis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: vrednost,
              min: 0,
              max: _najvec,
              divisions: _najvec.toInt(),
              label: '${vrednost.toStringAsFixed(0)} cm',
              onChanged: (v) => onSpremeni(v < 1 ? 1 : v),
            ),
          ],
        ),
      ),
    );
  }
}

class _RibaNaRavnilu extends CustomPainter {
  final double delez; // 0..1 dolžine ravnila
  final Color riba;
  final Color crte;
  _RibaNaRavnilu({required this.delez, required this.riba, required this.crte});

  @override
  void paint(Canvas c, Size s) {
    // Merilo: črtica vsakih 10 cm, daljša vsakih 50 cm.
    final yRavnila = s.height - 8;
    final p = Paint()
      ..color = crte
      ..strokeWidth = 1;
    c.drawLine(Offset(0, yRavnila), Offset(s.width, yRavnila), p);
    for (var cm = 0; cm <= 120; cm += 10) {
      final x = s.width * cm / 120;
      final dolga = cm % 50 == 0;
      c.drawLine(Offset(x, yRavnila), Offset(x, yRavnila - (dolga ? 10 : 5)), p);
    }

    if (delez <= 0) return;
    // Riba: telo od leve do deleža širine, višina sorazmerna dolžini.
    final dolzinaRibe = math.max(18.0, s.width * delez);
    final visina = (dolzinaRibe * 0.32).clamp(10.0, s.height - 20);
    final sredina = Offset(dolzinaRibe * 0.45, yRavnila - 8 - visina / 2);
    final telo = Paint()..color = riba;
    c.drawOval(
        Rect.fromCenter(
            center: sredina, width: dolzinaRibe * 0.82, height: visina),
        telo);
    // rep na levi
    final repX = sredina.dx - dolzinaRibe * 0.38;
    c.drawPath(
        Path()
          ..moveTo(repX + 4, sredina.dy)
          ..lineTo(repX - dolzinaRibe * 0.07, sredina.dy - visina * 0.45)
          ..lineTo(repX - dolzinaRibe * 0.07, sredina.dy + visina * 0.45)
          ..close(),
        telo);
    // oko na desni
    c.drawCircle(
        Offset(sredina.dx + dolzinaRibe * 0.28, sredina.dy - visina * 0.12),
        math.max(1.5, visina * 0.09),
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RibaNaRavnilu o) => o.delez != delez || o.riba != riba;
}
