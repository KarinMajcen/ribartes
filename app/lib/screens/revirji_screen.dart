import 'package:material_ui/material_ui.dart';

import '../models/revir.dart';
import '../services/revir_service.dart';
import '../tema/tema.dart';
import '../utils/format.dart';
import '../widgets/reka_glava.dart';
import 'revir_detail_screen.dart';
import 'zemljevid_screen.dart';
import '../widgets/prazno_stanje.dart';

/// Zaslon "Revirji" – pokriva US-03.
class RevirjiScreen extends StatefulWidget {
  const RevirjiScreen({super.key});

  @override
  State<RevirjiScreen> createState() => _RevirjiScreenState();
}

class _RevirjiScreenState extends State<RevirjiScreen> {
  final _service = RevirService();
  late final Stream<List<Revir>> _tok = _service.vsiRevirji();
  String _iskanje = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revirji'),
        actions: [
          IconButton(
            tooltip: 'Zemljevid',
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ZemljevidScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Išči po reki ali vrsti ribe',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _iskanje = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Revir>>(
              stream: _tok,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _Sporocilo(
                    'Revirjev ni bilo mogoče naložiti. Poskusi znova.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final revirji =
                    snapshot.data!.where((r) => r.ustreza(_iskanje)).toList();

                if (revirji.isEmpty) {
                  // Scenarij "ni zadetkov" iz US-03.
                  return const PraznoStanje(
                    ikona: Icons.search_off,
                    naslov: 'Ni revirjev, ki ustrezajo iskanju',
                    razlaga: 'Poskusi z imenom reke ali vrste ribe, '
                        'npr. »Soča« ali »lipan«.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: revirji.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Razmik.s),
                  itemBuilder: (context, i) => _RevirKartica(revirji[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Vrstica revirja: barvni "kamenček" reke, ime, kraj in vrste rib, cena desno.
/// Barva je le majhen poudarek, ki loči reke; ostalo je mirno in berljivo.
class _RevirKartica extends StatelessWidget {
  final Revir revir;
  const _RevirKartica(this.revir);

  String get _vrste {
    final prve = revir.vrste.take(3).join(', ');
    final ostale = revir.vrste.length - 3;
    return ostale > 0 ? '$prve in še $ostale' : prve;
  }

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    final barve = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RevirDetailScreen(revir: revir)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Razmik.m),
          child: Row(
            children: [
              // Kamenček v barvi reke – ob tapu se razširi v glavo podrobnosti.
              SizedBox(
                width: 60,
                height: 60,
                child: Hero(
                  tag: 'revir-${revir.id}',
                  child: RekaGlava(
                    reka: revir.reka,
                    visina: 60,
                    zaobljenost: BorderRadius.circular(Zaobljenost.gumb),
                    otrok: const Center(
                      child: Icon(Icons.phishing,
                          color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Razmik.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(revir.ime, style: besedilo.titleMedium),
                    const SizedBox(height: 2),
                    Text(revir.ribiskaDruzina, style: besedilo.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      _vrste,
                      style: besedilo.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Razmik.s),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCena(revir.cenaDnevna),
                    style: besedilo.titleMedium
                        ?.copyWith(color: barve.primary),
                  ),
                  Text('na dan', style: besedilo.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sporocilo extends StatelessWidget {
  final String besedilo;
  const _Sporocilo(this.besedilo);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(besedilo, textAlign: TextAlign.center),
      ),
    );
  }
}
