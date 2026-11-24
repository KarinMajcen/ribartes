import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/dovolilnica.dart';
import '../models/revir.dart';
import '../services/dovolilnica_service.dart';
import '../services/revir_service.dart';
import '../utils/format.dart';

/// Izid preverjanja – vsak ima svojo barvo in besedilo.
enum _Izid { veljavna, seNeVelja, potekla, drugRevir, neObstaja, neznana, niPovezave }

class _Rezultat {
  final _Izid izid;
  final Dovolilnica? dovolilnica;
  const _Rezultat(this.izid, [this.dovolilnica]);
}

/// Zaslon "Preveri dovolilnico" za ribiškega čuvaja – pokriva US-11.
class PreveriDovolilnicoScreen extends StatefulWidget {
  const PreveriDovolilnicoScreen({super.key});

  @override
  State<PreveriDovolilnicoScreen> createState() =>
      _PreveriDovolilnicoScreenState();
}

class _PreveriDovolilnicoScreenState extends State<PreveriDovolilnicoScreen> {
  final _kamera = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _service = DovolilnicaService();
  late final Stream<List<Revir>> _revirjiTok = RevirService().vsiRevirji();

  /// Revir, na katerem je čuvaj (null = ne preverjamo revirja).
  String? _mojRevirId;
  Map<String, Revir> _revirji = {};

  bool _obdeluje = false;
  _Rezultat? _rezultat;

  @override
  void dispose() {
    _kamera.dispose();
    super.dispose();
  }

  /// Skupna pot za skeniranje in ročni vnos.
  Future<void> _preveri(String vsebina) async {
    if (_obdeluje || _rezultat != null) return; // en rezultat naenkrat
    setState(() => _obdeluje = true);

    final id = Dovolilnica.idIzQr(vsebina);
    _Rezultat rezultat;

    if (id == null) {
      rezultat = const _Rezultat(_Izid.neznana);
    } else {
      try {
        final d = await _service.preberiZaPreverjanje(id);
        if (d == null) {
          rezultat = const _Rezultat(_Izid.neObstaja);
        } else if (_mojRevirId != null && d.revirId != _mojRevirId) {
          rezultat = _Rezultat(_Izid.drugRevir, d);
        } else {
          rezultat = switch (d.stanje) {
            StanjeDovolilnice.veljavna => _Rezultat(_Izid.veljavna, d),
            StanjeDovolilnice.seNeVelja => _Rezultat(_Izid.seNeVelja, d),
            StanjeDovolilnice.potekla => _Rezultat(_Izid.potekla, d),
          };
        }
      } on TimeoutException {
        rezultat = const _Rezultat(_Izid.niPovezave);
      } on FirebaseException catch (e) {
        rezultat = _Rezultat(
            e.code == 'unavailable' ? _Izid.niPovezave : _Izid.neObstaja);
      }
    }

    if (!mounted) return;
    setState(() {
      _rezultat = rezultat;
      _obdeluje = false;
    });
  }

  void _naslednja() => setState(() => _rezultat = null);

  Future<void> _rocniVnos() async {
    final ctrl = TextEditingController();
    final vnos = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Številka dovolilnice'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'npr. 3fK9aQ…',
            helperText: 'Številka je pod QR kodo na ribičevem telefonu.',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Prekliči')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Preveri')),
        ],
      ),
    );
    ctrl.dispose();
    if (vnos != null && vnos.trim().isNotEmpty) {
      _rezultat = null;
      await _preveri(vnos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preveri dovolilnico'),
        actions: [
          IconButton(
            tooltip: 'Svetilka',
            icon: const Icon(Icons.flashlight_on),
            onPressed: () => _kamera.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Vpiši številko ročno',
            icon: const Icon(Icons.keyboard),
            onPressed: _rocniVnos,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Izbira revirja, na katerem je čuvaj ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: StreamBuilder<List<Revir>>(
              stream: _revirjiTok,
              builder: (context, snapshot) {
                final seznam = snapshot.data ?? [];
                _revirji = {for (final r in seznam) r.id: r};
                return DropdownButtonFormField<String?>(
                  initialValue: _mojRevirId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Moj revir',
                    prefixIcon: Icon(Icons.water),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Ne preverjaj revirja')),
                    for (final r in seznam)
                      DropdownMenuItem<String?>(value: r.id, child: Text(r.ime)),
                  ],
                  onChanged: (id) => setState(() => _mojRevirId = id),
                );
              },
            ),
          ),

          // --- Kamera ---
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _kamera,
                  onDetect: (capture) {
                    final vsebina = capture.barcodes.isEmpty
                        ? null
                        : capture.barcodes.first.rawValue;
                    if (vsebina != null) _preveri(vsebina);
                  },
                ),
                // Okvir, kamor naj čuvaj usmeri kodo.
                IgnorePointer(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (_obdeluje) const CircularProgressIndicator(),
              ],
            ),
          ),

          // --- Rezultat ali navodilo ---
          SafeArea(
            top: false,
            child: _rezultat == null
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Usmerite kamero v QR kodo na ribičevem telefonu.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : _PanelRezultata(
                    rezultat: _rezultat!,
                    revirji: _revirji,
                    onNaslednja: _naslednja,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PanelRezultata extends StatelessWidget {
  final _Rezultat rezultat;
  final Map<String, Revir> revirji;
  final VoidCallback onNaslednja;

  const _PanelRezultata({
    required this.rezultat,
    required this.revirji,
    required this.onNaslednja,
  });

  @override
  Widget build(BuildContext context) {
    final d = rezultat.dovolilnica;

    final (barva, ikona, naslov) = switch (rezultat.izid) {
      _Izid.veljavna => (Colors.green.shade700, Icons.check_circle, 'Veljavna'),
      _Izid.seNeVelja => (
          Colors.orange.shade800,
          Icons.schedule,
          'Še ne velja – velja od ${formatDatum(d!.veljaOd)}'
        ),
      _Izid.potekla => (
          Colors.red.shade700,
          Icons.cancel,
          'Ni veljavna – potekla ${formatDatum(d!.veljaDo)}'
        ),
      _Izid.drugRevir => (
          Colors.orange.shade800,
          Icons.wrong_location,
          'Velja za drug revir: ${d!.revirIme}'
        ),
      _Izid.neObstaja => (
          Colors.red.shade700,
          Icons.help,
          'Dovolilnica ne obstaja'
        ),
      _Izid.neznana => (Colors.grey.shade700, Icons.qr_code, 'Neznana koda'),
      _Izid.niPovezave => (
          Colors.grey.shade700,
          Icons.wifi_off,
          'Ni povezave – dovolilnice ni mogoče preveriti'
        ),
    };

    final obdobje = d == null
        ? ''
        : d.vrsta == VrstaDovolilnice.dnevna
            ? formatDatum(d.veljaOd)
            : '${formatDatum(d.veljaOd)} – ${formatDatum(d.veljaDo)}';

    return Container(
      width: double.infinity,
      color: barva,
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(ikona, color: Colors.white, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    naslov,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (d != null) ...[
              const SizedBox(height: 12),
              _Podatek('Ribič', d.imeRibica),
              _Podatek('Revir', d.revirIme),
              _Podatek('Dovolilnica', '${d.vrsta.naziv} · $obdobje'),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Skeniraj naslednjo'),
                onPressed: onNaslednja,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Podatek extends StatelessWidget {
  final String oznaka;
  final String vrednost;
  const _Podatek(this.oznaka, this.vrednost);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(oznaka, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(child: Text(vrednost)),
        ],
      ),
    );
  }
}
