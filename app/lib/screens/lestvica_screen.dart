import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../models/revir.dart';
import '../models/ulov.dart';
import '../services/revir_service.dart';
import '../services/ulov_service.dart';
import '../utils/format.dart';
import '../tema/tema.dart';
import '../widgets/prazno_stanje.dart';

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
                      return const PraznoStanje(
                        ikona: Icons.leaderboard,
                        naslov: 'Ta teden še ni ulovov',
                        razlaga: 'Vpiši ulov s te reke in bodi prvi na lestvici.',
                      );
                    }

                    final prikaz = lestvica.take(_najvec).toList();
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        // Prva tri mesta na zmagovalnem odru, ostali pod njim.
                        _Oder(
                          // ključ = reka, da se stopničke ob menjavi reke znova dvignejo
                          key: ValueKey(_reka),
                          prvi: prikaz.take(3).toList(),
                          mojUid: _mojUid,
                        ),
                        const SizedBox(height: 16),
                        for (var i = 3; i < prikaz.length; i++)
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

/// Zmagovalni oder: 2. mesto levo, 1. na sredini (najvišje), 3. desno.
/// Stopničke ob prikazu zrastejo iz tal.
class _Oder extends StatelessWidget {
  final List<Ulov> prvi;
  final String? mojUid;
  const _Oder({super.key, required this.prvi, required this.mojUid});

  @override
  Widget build(BuildContext context) {
    // vrstni red na odru: 2., 1., 3.
    final razpored = <(int, double, Color)>[
      (2, 90, const Color(0xFFB8C4C0)), // srebro
      (1, 125, Paleta.muha), // zlato = barva nagrad
      (3, 70, const Color(0xFFC98A5A)), // bron
    ];

    return SizedBox(
      height: 270,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (mesto, visina, barva) in razpored)
            Expanded(
              child: mesto <= prvi.length
                  ? _Stopnicka(
                      mesto: mesto,
                      visina: visina,
                      barva: barva,
                      ulov: prvi[mesto - 1],
                      moj: prvi[mesto - 1].uid == mojUid,
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _Stopnicka extends StatelessWidget {
  final int mesto;
  final double visina;
  final Color barva;
  final Ulov ulov;
  final bool moj;

  const _Stopnicka({
    required this.mesto,
    required this.visina,
    required this.barva,
    required this.ulov,
    required this.moj,
  });

  @override
  Widget build(BuildContext context) {
    const medalje = {1: '🥇', 2: '🥈', 3: '🥉'};
    final besedilo = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(medalje[mesto]!, style: TextStyle(fontSize: mesto == 1 ? 40 : 30)),
          Text(
            '${ulov.dolzinaCm.toStringAsFixed(0)} cm',
            style: besedilo.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(ulov.vrstaIme,
              style: besedilo.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(
            moj ? 'Ti' : ulov.javnoIme,
            style: besedilo.bodySmall?.copyWith(
              fontWeight: moj ? FontWeight.bold : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: visina),
            duration: Duration(milliseconds: 600 + mesto * 150),
            curve: Curves.easeOutBack,
            builder: (context, h, _) => Container(
              height: h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [barva, Color.lerp(barva, Colors.black, 0.25)!],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                border: moj
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 3)
                    : null,
              ),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 8),
              child: h > 30
                  ? Text(
                      '$mesto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
          ),
        ],
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
            ? Tooltip(
                message: 'Vrnjena v reko',
                child: Icon(Icons.eco, color: context.ribartes.narava),
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
