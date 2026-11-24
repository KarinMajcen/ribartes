import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/revir.dart';
import '../models/ulov.dart';
import '../models/vrsta_ribe.dart';
import '../services/revir_service.dart';
import '../services/ulov_service.dart';

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

      // US-08: prvi ulov te vrste odklene kartico.
      if (rezultat.novaKartica) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.emoji_events, size: 48),
            title: const Text('Nova kartica!'),
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
