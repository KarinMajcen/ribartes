import 'package:flutter/material.dart';

import '../models/dovolilnica.dart';
import '../models/revir.dart';
import '../services/dovolilnica_service.dart';
import '../utils/format.dart';
import 'dovolilnica_qr_screen.dart';

/// Zaslon "Nakup dovolilnice" – pokriva US-05.
class NakupScreen extends StatefulWidget {
  final Revir revir;
  const NakupScreen({super.key, required this.revir});

  @override
  State<NakupScreen> createState() => _NakupScreenState();
}

class _NakupScreenState extends State<NakupScreen> {
  final _service = DovolilnicaService();

  VrstaDovolilnice _vrsta = VrstaDovolilnice.dnevna;
  late DateTime _datum = _danes;
  bool _nalaganje = false;
  String? _napaka;

  DateTime get _danes {
    final z = DateTime.now();
    return DateTime(z.year, z.month, z.day);
  }

  bool get _datumVPreteklosti => _datum.isBefore(_danes);

  Future<void> _izberiDatum() async {
    final izbran = await showDatePicker(
      context: context,
      initialDate: _datumVPreteklosti ? _danes : _datum,
      firstDate: _danes, // preteklih dni ni mogoče izbrati
      lastDate: _danes.add(const Duration(days: 365)),
      helpText: 'Datum začetka veljavnosti',
    );
    if (izbran != null) setState(() => _datum = izbran);
  }

  Future<void> _placaj() async {
    final cena = _vrsta.cena(widget.revir);

    // Simulirano plačilo: potrditev namesto pravega plačilnega prehoda.
    final potrdi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.credit_card),
        title: const Text('Potrditev plačila'),
        content: Text(
          '${_vrsta.naziv} dovolilnica – ${widget.revir.ime}\n'
          'Znesek: ${formatCena(cena)}\n\n'
          'To je simulirano plačilo. Kartica ne bo bremenjena.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Prekliči'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Potrdi plačilo'),
          ),
        ],
      ),
    );
    if (potrdi != true || !mounted) return;

    setState(() {
      _nalaganje = true;
      _napaka = null;
    });

    try {
      final id = await _service.kupi(
        revir: widget.revir,
        vrsta: _vrsta,
        datum: _datum,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nakup uspešen. Dobra ribolovna sreča!')),
      );
      // Zamenja zaslon nakupa z zaslonom QR kode (gumb Nazaj ne vrne na nakup).
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DovolilnicaQrScreen(id: id)),
      );
    } on NakupNapaka catch (e) {
      if (mounted) setState(() => _napaka = e.sporocilo);
    } finally {
      if (mounted) setState(() => _nalaganje = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    final barve = Theme.of(context).colorScheme;
    final (veljaOd, veljaDo) = _vrsta.veljavnost(_datum);
    final cena = _vrsta.cena(widget.revir);

    return Scaffold(
      appBar: AppBar(title: const Text('Nakup dovolilnice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.revir.ime, style: besedilo.headlineSmall),
          Text(widget.revir.ribiskaDruzina,
              style: TextStyle(color: barve.onSurfaceVariant)),
          const SizedBox(height: 24),

          Text('Vrsta dovolilnice', style: besedilo.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<VrstaDovolilnice>(
            segments: [
              for (final v in VrstaDovolilnice.values)
                ButtonSegment(value: v, label: Text(v.naziv)),
            ],
            selected: {_vrsta},
            onSelectionChanged: (izbrane) =>
                setState(() => _vrsta = izbrane.first),
          ),
          const SizedBox(height: 24),

          Text('Datum začetka', style: besedilo.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(formatDatum(_datum)),
              trailing: const Icon(Icons.edit),
              onTap: _nalaganje ? null : _izberiDatum,
            ),
          ),
          if (_datumVPreteklosti)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Datum ne sme biti v preteklosti.',
                  style: TextStyle(color: barve.error)),
            ),
          const SizedBox(height: 24),

          Card(
            color: barve.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Povzetek', style: besedilo.titleMedium),
                  const SizedBox(height: 8),
                  Text('Velja od: ${formatDatum(veljaOd)}, 00:00'),
                  Text('Velja do: ${formatDatum(veljaDo)}, 23:59'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Za plačilo', style: besedilo.titleMedium),
                      Text(formatCena(cena), style: besedilo.titleLarge),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_napaka != null) ...[
            const SizedBox(height: 16),
            Text(_napaka!,
                style: TextStyle(color: barve.error),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 80),
        ],
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
                : const Icon(Icons.payment),
            label: Text('Plačaj ${formatCena(cena)}'),
            onPressed: (_nalaganje || _datumVPreteklosti) ? null : _placaj,
          ),
        ),
      ),
    );
  }
}
