import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/dovolilnica.dart';
import '../services/dovolilnica_service.dart';
import '../utils/format.dart';
import '../tema/tema.dart';

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

/// "Živa" dovolilnica: pri veljavni dovolilnici se rob QR kode vrti v
/// barvah, oznaka utripa in ura teče v živo. Tako čuvaj na prvi pogled
/// loči pravo dovolilnico od posnetka zaslona (kot pri vozovnicah).
class _Vsebina extends StatefulWidget {
  final Dovolilnica d;
  const _Vsebina(this.d);

  @override
  State<_Vsebina> createState() => _VsebinaState();
}

class _VsebinaState extends State<_Vsebina>
    with SingleTickerProviderStateMixin {
  late final AnimationController _vrtenje = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))
    ..repeat();
  late final Timer _ura;
  DateTime _zdaj = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ura = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _zdaj = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ura.cancel();
    _vrtenje.dispose();
    super.dispose();
  }

  String _dvomestno(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final besedilo = Theme.of(context).textTheme;
    final veljavna = d.stanje == StanjeDovolilnice.veljavna;

    final qr = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // QR koda potrebuje svetlo ozadje za skeniranje
        borderRadius: BorderRadius.circular(16),
      ),
      child: QrImageView(
        data: d.qrVsebina,
        version: QrVersions.auto,
        size: 240,
        semanticsLabel: 'QR koda dovolilnice',
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: veljavna
              ? ScaleTransition(
                  // rahlo "dihanje" oznake Veljavna
                  scale: Tween(begin: 0.95, end: 1.06).animate(CurvedAnimation(
                    parent: _vrtenje,
                    curve: const _NazajNaprej(),
                  )),
                  child: OznakaStanja(d.stanje),
                )
              : OznakaStanja(d.stanje),
        ),
        const SizedBox(height: 16),
        Center(
          child: veljavna
              ? AnimatedBuilder(
                  animation: _vrtenje,
                  builder: (context, otrok) => Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      gradient: SweepGradient(
                        colors: const [
                          Paleta.socaSvetla,
                          Paleta.soca,
                          Color(0xFF5FA8D3),
                          Paleta.muha,
                          Paleta.socaSvetla,
                        ],
                        transform:
                            GradientRotation(_vrtenje.value * 2 * math.pi),
                      ),
                      boxShadow: const [
                        BoxShadow(blurRadius: 12, color: Colors.black26)
                      ],
                    ),
                    child: otrok,
                  ),
                  child: qr,
                )
              : Opacity(opacity: 0.5, child: qr),
        ),
        const SizedBox(height: 12),
        if (veljavna)
          Column(
            children: [
              Text(
                '${_dvomestno(_zdaj.hour)}:${_dvomestno(_zdaj.minute)}:'
                '${_dvomestno(_zdaj.second)}',
                textAlign: TextAlign.center,
                style: besedilo.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Živa dovolilnica · posnetek zaslona ne velja',
                textAlign: TextAlign.center,
                style: besedilo.bodySmall,
              ),
            ],
          ),
        const SizedBox(height: 16),
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
              if (d.popust > 0)
                ListTile(
                  leading: const Icon(Icons.stars),
                  title: const Text('Popust s točkami'),
                  subtitle: Text('Porabljenih ${d.porabljeneTocke} točk'),
                  trailing: Text('−${formatCena(d.popust)}'),
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
        // SelectableText: številko je mogoče kopirati (ročni vnos pri čuvaju).
        SelectableText(
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
      StanjeDovolilnice.veljavna => (context.ribartes.uspeh, Icons.check_circle),
      StanjeDovolilnice.seNeVelja => (context.ribartes.opozorilo, Icons.schedule),
      StanjeDovolilnice.potekla => (context.ribartes.nevtralno, Icons.cancel),
    };
    return Chip(
      avatar: Icon(ikona, color: Colors.white, size: 18),
      label: Text(stanje.naziv, style: const TextStyle(color: Colors.white)),
      backgroundColor: barva,
      side: BorderSide.none,
    );
  }
}

/// Krivulja, ki gre 0 → 1 → 0 (za utripanje ob ponavljajoči se animaciji).
class _NazajNaprej extends Curve {
  const _NazajNaprej();

  @override
  double transformInternal(double t) =>
      Curves.easeInOut.transform(t < 0.5 ? t * 2 : (1 - t) * 2);
}
