import 'package:flutter/material.dart';

import '../models/dovolilnica.dart';
import '../services/dovolilnica_service.dart';
import '../utils/format.dart';
import 'dovolilnica_qr_screen.dart';

/// Zaslon "Moje dovolilnice" – pokriva US-06.
class MojeDovolilniceScreen extends StatelessWidget {
  const MojeDovolilniceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje dovolilnice')),
      body: StreamBuilder<List<Dovolilnica>>(
        // Firestore hrani zadnje naložene podatke na napravi, zato se seznam
        // in QR kode prikažejo tudi brez povezave (US-06, scenarij brez povezave).
        stream: DovolilnicaService().mojeDovolilnice(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Dovolilnic ni bilo mogoče naložiti.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final vse = snapshot.data!;
          if (vse.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Še nimate dovolilnic.\nKupite jo pri izbranem revirju.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Aktivne (veljavne in prihodnje) zgoraj, najprej tiste, ki začnejo prej.
          final aktivne = vse
              .where((d) => d.stanje != StanjeDovolilnice.potekla)
              .toList()
            ..sort((a, b) => a.veljaOd.compareTo(b.veljaOd));
          // Zgodovina: najnovejša potekla na vrhu.
          final zgodovina = vse
              .where((d) => d.stanje == StanjeDovolilnice.potekla)
              .toList()
            ..sort((a, b) => b.veljaDo.compareTo(a.veljaDo));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (aktivne.isNotEmpty) ...[
                const _Naslov('Aktivne'),
                for (final d in aktivne) _DovolilnicaKartica(d),
              ],
              if (zgodovina.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _Naslov('Zgodovina'),
                for (final d in zgodovina) _DovolilnicaKartica(d),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Naslov extends StatelessWidget {
  final String besedilo;
  const _Naslov(this.besedilo);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(besedilo, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _DovolilnicaKartica extends StatelessWidget {
  final Dovolilnica d;
  const _DovolilnicaKartica(this.d);

  @override
  Widget build(BuildContext context) {
    final obdobje = d.vrsta == VrstaDovolilnice.dnevna
        ? formatDatum(d.veljaOd)
        : '${formatDatum(d.veljaOd)} – ${formatDatum(d.veljaDo)}';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.qr_code_2, size: 36),
        title: Text(d.revirIme),
        subtitle: Text('${d.vrsta.naziv} · $obdobje'),
        trailing: OznakaStanja(d.stanje),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DovolilnicaQrScreen(id: d.id)),
        ),
      ),
    );
  }
}
