import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/revir.dart';
import '../models/ulov.dart';
import '../services/revir_service.dart';
import '../services/ulov_service.dart';
import '../utils/format.dart';

/// Zaslon "Tedenska lestvica" – pokriva US-12.
class LestvicaScreen extends StatefulWidget {
  const LestvicaScreen({super.key});

  @override
  State<LestvicaScreen> createState() => _LestvicaScreenState();
}

class _LestvicaScreenState extends State<LestvicaScreen> {
  static const _najvec = 10; // prikaz prvih 10 mest

  late final Stream<List<Revir>> _revirjiTok = RevirService().vsiRevirji();
  late final Stream<List<Ulov>> _uloviTok = UlovService().uloviTegaTedna();
  final _mojUid = FirebaseAuth.instance.currentUser?.uid;

  String? _reka;

  @override
  Widget build(BuildContext context) {
    final zacetek = UlovService.zacetekTedna();
    final konec = DateTime(zacetek.year, zacetek.month, zacetek.day + 6);

    return Scaffold(
      appBar: AppBar(title: const Text('Tedenska lestvica')),
      body: StreamBuilder<List<Revir>>(
        stream: _revirjiTok,
        builder: (context, revirjiSnap) {
          // Seznam rek brez ponovitev, po abecedi.
          final reke = {for (final r in revirjiSnap.data ?? <Revir>[]) r.reka}
              .toList()
            ..sort();
          if (reke.isNotEmpty && (_reka == null || !reke.contains(_reka))) {
            _reka = reke.first;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Teden ${formatDatum(zacetek)} – ${formatDatum(konec)} · '
                  'največji ulovi po dolžini',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              // Izbira reke
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    for (final reka in reke)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(reka),
                          selected: reka == _reka,
                          onSelected: (_) => setState(() => _reka = reka),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Ulov>>(
                  stream: _uloviTok,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const _Sporocilo(
                          'Lestvice ni bilo mogoče naložiti.');
                    }
                    if (!snap.hasData || _reka == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final lestvica = snap.data!
                        .where((u) => u.reka == _reka)
                        .toList()
                      ..sort((a, b) => b.dolzinaCm.compareTo(a.dolzinaCm));

                    if (lestvica.isEmpty) {
                      // Scenarij "ni ulovov" iz US-12.
                      return const _Sporocilo(
                          'Ta teden še ni ulovov. Bodi prvi!');
                    }

                    final prikaz = lestvica.take(_najvec).toList();
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        for (var i = 0; i < prikaz.length; i++)
                          _Vrstica(
                            mesto: i + 1,
                            ulov: prikaz[i],
                            moj: prikaz[i].uid == _mojUid,
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Zmagovalec tedna prejme nagrado sponzorja.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Vrstica extends StatelessWidget {
  final int mesto;
  final Ulov ulov;
  final bool moj;
  const _Vrstica({required this.mesto, required this.ulov, required this.moj});

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;
    const medalje = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Card(
      color: moj ? barve.primaryContainer : null,
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text(
              medalje[mesto] ?? '$mesto.',
              style: TextStyle(fontSize: mesto <= 3 ? 28 : 18),
            ),
          ),
        ),
        title: Text('${ulov.vrstaIme} · ${ulov.dolzinaCm.toStringAsFixed(0)} cm'),
        subtitle: Text(
          '${moj ? 'Ti' : ulov.javnoIme} · ${formatDatum(ulov.datum)}'
          '${ulov.revirIme == null ? '' : ' · ${ulov.revirIme}'}',
        ),
        trailing: ulov.spuscena
            ? const Tooltip(
                message: 'Vrnjena v reko',
                child: Icon(Icons.eco, color: Colors.green),
              )
            : null,
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
