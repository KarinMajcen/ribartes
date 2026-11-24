import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/dovolilnica.dart';
import '../services/dovolilnica_service.dart';
import '../utils/format.dart';

/// Zaslon z QR kodo dovolilnice, ki jo ribič pokaže čuvaju – US-06.
class DovolilnicaQrScreen extends StatelessWidget {
  final String id;
  const DovolilnicaQrScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dovolilnica')),
      body: StreamBuilder<Dovolilnica?>(
        stream: DovolilnicaService().dovolilnica(id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Dovolilnice ni bilo mogoče naložiti.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snapshot.data;
          if (d == null) {
            return const Center(child: Text('Dovolilnica ne obstaja.'));
          }
          return _Vsebina(d);
        },
      ),
    );
  }
}

class _Vsebina extends StatelessWidget {
  final Dovolilnica d;
  const _Vsebina(this.d);

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(child: OznakaStanja(d.stanje)),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, // QR koda potrebuje svetlo ozadje za skeniranje
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
            ),
            child: QrImageView(
              data: d.qrVsebina,
              version: QrVersions.auto,
              size: 240,
              semanticsLabel: 'QR koda dovolilnice',
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(d.revirIme,
            style: besedilo.headlineSmall, textAlign: TextAlign.center),
        Text('${d.vrsta.naziv} dovolilnica',
            style: besedilo.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Ribič'),
                trailing: Text(d.imeRibica),
              ),
              ListTile(
                leading: const Icon(Icons.event_available),
                title: const Text('Velja od'),
                trailing: Text('${formatDatum(d.veljaOd)}, 00:00'),
              ),
              ListTile(
                leading: const Icon(Icons.event_busy),
                title: const Text('Velja do'),
                trailing: Text('${formatDatum(d.veljaDo)}, 23:59'),
              ),
              ListTile(
                leading: const Icon(Icons.euro),
                title: const Text('Plačano'),
                trailing: Text(formatCena(d.cena)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Številka: ${d.id}',
          textAlign: TextAlign.center,
          style: besedilo.bodySmall,
        ),
      ],
    );
  }
}

/// Barvna oznaka stanja: zelena = veljavna, modra = še ne velja, siva = potekla.
class OznakaStanja extends StatelessWidget {
  final StanjeDovolilnice stanje;
  const OznakaStanja(this.stanje, {super.key});

  @override
  Widget build(BuildContext context) {
    final (barva, ikona) = switch (stanje) {
      StanjeDovolilnice.veljavna => (Colors.green.shade700, Icons.check_circle),
      StanjeDovolilnice.seNeVelja => (Colors.blue.shade700, Icons.schedule),
      StanjeDovolilnice.potekla => (Colors.grey.shade600, Icons.cancel),
    };
    return Chip(
      avatar: Icon(ikona, color: Colors.white, size: 18),
      label: Text(stanje.naziv, style: const TextStyle(color: Colors.white)),
      backgroundColor: barva,
      side: BorderSide.none,
    );
  }
}
