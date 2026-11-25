import 'package:material_ui/material_ui.dart';

import '../models/dovolilnica.dart';
import '../services/dovolilnica_service.dart';
import '../utils/format.dart';
import '../widgets/stric_ribic.dart';
import 'dovolilnica_qr_screen.dart';
import '../widgets/prazno_stanje.dart';

/// Zaslon "Moje dovolilnice" – pokriva US-06.
class MojeDovolilniceScreen extends StatefulWidget {
  /// Ali je zavihek trenutno viden (takrat pride stric).
  final bool aktiven;

  /// Kaj naredi gumb "Kupi dovolilnico" v stričkovem oblačku.
  final VoidCallback? onKupi;

  const MojeDovolilniceScreen({super.key, this.aktiven = true, this.onKupi});

  @override
  State<MojeDovolilniceScreen> createState() => _MojeDovolilniceScreenState();
}

class _MojeDovolilniceScreenState extends State<MojeDovolilniceScreen> {
  late final Stream<List<Dovolilnica>> _tok =
      DovolilnicaService().mojeDovolilnice();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moje dovolilnice')),
      body: StreamBuilder<List<Dovolilnica>>(
        // Firestore hrani zadnje naložene podatke na napravi, zato se seznam
        // in QR kode prikažejo tudi brez povezave (US-06, scenarij brez povezave).
        stream: _tok,
        builder: (context, snapshot) {
          final imaVeljavno = (snapshot.data ?? [])
              .any((d) => d.stanje == StanjeDovolilnice.veljavna);
          return Stack(
            children: [
              Positioned.fill(child: _seznam(context, snapshot)),
              // Stric ribič – hecen element; pride, ko je zavihek viden.
              if (snapshot.hasData)
                Positioned(
                  right: 12,
                  bottom: 8,
                  child: StricRibic(
                    imaVeljavno: imaVeljavno,
                    aktiven: widget.aktiven,
                    onKupi: widget.onKupi,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _seznam(
      BuildContext context, AsyncSnapshot<List<Dovolilnica>> snapshot) {
    if (snapshot.hasError) {
      return const Center(
          child: Text('Dovolilnic ni bilo mogoče naložiti.'));
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final vse = snapshot.data!;
    if (vse.isEmpty) {
      return PraznoStanje(
          ikona: Icons.qr_code_2,
          naslov: 'Še nimaš dovolilnice',
          razlaga: 'Izberi revir in kupi dovolilnico. Tukaj se nato '
              'pojavi njena QR koda za čuvaja.',
          gumb: 'Poišči revir',
          onGumb: widget.onKupi,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 260),
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
