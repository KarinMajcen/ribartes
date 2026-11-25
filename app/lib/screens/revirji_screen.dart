import 'package:material_ui/material_ui.dart';

import '../models/revir.dart';
import '../services/revir_service.dart';
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
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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

class _RevirKartica extends StatelessWidget {
  final Revir revir;
  const _RevirKartica(this.revir);

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    final prikaz = revir.vrste.take(3).toList();
    final preostale = revir.vrste.length - prikaz.length;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RevirDetailScreen(revir: revir)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barvna glava – ob tapu se razširi v glavo zaslona s podrobnostmi.
            Hero(
              tag: 'revir-${revir.id}',
              child: RekaGlava(
                reka: revir.reka,
                visina: 72,
                otrok: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.water, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          revir.reka.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'od ${formatCena(revir.cenaDnevna)}',
                          style: TextStyle(
                            color: barveReke(revir.reka).last,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(revir.ime, style: besedilo.titleMedium),
                  Text(revir.ribiskaDruzina, style: besedilo.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final v in prikaz) _Oznaka(v),
                      if (preostale > 0) _Oznaka('+$preostale'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Oznaka extends StatelessWidget {
  final String besedilo;
  const _Oznaka(this.besedilo);

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: barve.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(besedilo,
          style: TextStyle(fontSize: 12, color: barve.onSecondaryContainer)),
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
