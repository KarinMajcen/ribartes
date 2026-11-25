import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/dovolilnica.dart';
import '../models/ulov.dart';
import '../models/vrsta_ribe.dart';
import '../models/znacka.dart';
import '../services/auth_service.dart';
import '../services/dovolilnica_service.dart';
import '../services/ulov_service.dart';
import 'gostilne_screen.dart';
import 'lestvica_screen.dart';

/// Zaslon "Profil": podatki ribiča, statistika, značke, lestvica in odjava.
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _auth = AuthService();
  final _ulovService = UlovService();

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _profilTok =
      FirebaseFirestore.instance
          .collection('uporabniki')
          .doc(_auth.trenutniUporabnik!.uid)
          .snapshots();
  late final Stream<List<Ulov>> _uloviTok = _ulovService.mojiUlovi();
  late final Stream<List<VrstaRibe>> _vrsteTok = _ulovService.vrsteRib();
  late final Stream<List<Dovolilnica>> _dovolilniceTok =
      DovolilnicaService().mojeDovolilnice();

  Future<void> _odjava() async {
    final potrdi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Se res želiš odjaviti?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Prekliči')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Odjava')),
        ],
      ),
    );
    if (potrdi == true) await _auth.odjava();
  }

  void _odpri(Widget zaslon) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => zaslon));

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    final barve = Theme.of(context).colorScheme;
    final email = _auth.trenutniUporabnik?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profilTok,
        builder: (context, profilSnap) {
          final p = profilSnap.data?.data();
          final ime = (p?['ime'] as String?) ?? '';
          final tocke = (p?['tocke'] as num?)?.toInt() ?? 0;
          final jeCuvaj = p?['vloga'] == 'cuvaj';
          final zacetnice = ime
              .split(' ')
              .where((s) => s.isNotEmpty)
              .take(2)
              .map((s) => s[0].toUpperCase())
              .join();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Glava ---
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: barve.primary,
                    child: Text(
                      zacetnice.isEmpty ? '?' : zacetnice,
                      style: TextStyle(
                          fontSize: 26,
                          color: barve.onPrimary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ime.isEmpty ? 'Ribič' : ime,
                            style: besedilo.titleLarge),
                        Text(email, style: besedilo.bodyMedium),
                        const SizedBox(height: 4),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                              jeCuvaj ? Icons.badge : Icons.phishing,
                              size: 16),
                          label: Text(jeCuvaj ? 'Ribiški čuvaj' : 'Ribič'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Statistika in značke (iz ulovov) ---
              StreamBuilder<List<VrstaRibe>>(
                stream: _vrsteTok,
                builder: (context, vrsteSnap) {
                  return StreamBuilder<List<Ulov>>(
                    stream: _uloviTok,
                    builder: (context, uloviSnap) {
                      return StreamBuilder<List<Dovolilnica>>(
                        stream: _dovolilniceTok,
                        builder: (context, dovSnap) {
                          final ulovi = uloviSnap.data ?? [];
                          final vsehVrst = vrsteSnap.data?.length ?? 0;
                          return _StatistikaInZnacke(
                            ulovi: ulovi,
                            vsehVrst: vsehVrst,
                            tocke: tocke,
                            steviloDovolilnic: dovSnap.data?.length ?? 0,
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.leaderboard),
                      title: const Text('Tedenska lestvica'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _odpri(const LestvicaScreen()),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restaurant),
                      title: const Text('Ti ujameš, mi spečemo'),
                      subtitle: const Text('Rezervacije v gostilnah'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _odpri(const GostilneScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Odjava'),
                onPressed: _odjava,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatistikaInZnacke extends StatelessWidget {
  final List<Ulov> ulovi;
  final int vsehVrst;
  final int tocke;
  final int steviloDovolilnic;

  const _StatistikaInZnacke({
    required this.ulovi,
    required this.vsehVrst,
    required this.tocke,
    required this.steviloDovolilnic,
  });

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    final vrst = ulovi.map((u) => u.vrstaId).toSet().length;
    final spuscenih = ulovi.where((u) => u.spuscena).length;
    Ulov? najvecji;
    for (final u in ulovi) {
      if (najvecji == null || u.dolzinaCm > najvecji.dolzinaCm) najvecji = u;
    }
    final znacke = Znacka.izracunaj(ulovi, vsehVrst: vsehVrst);
    final odklenjenih = znacke.where((z) => z.odklenjena).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Statistika', style: besedilo.titleLarge),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            _Stevilka('${ulovi.length}', 'ulovov'),
            _Stevilka('$spuscenih', 'vrnjenih v reko'),
            _Stevilka('$tocke', 'točk'),
            _Stevilka('$vrst / $vsehVrst', 'kartic'),
            _Stevilka('$steviloDovolilnic', 'dovolilnic'),
            _Stevilka(
              najvecji == null
                  ? '–'
                  : '${najvecji.dolzinaCm.toStringAsFixed(0)} cm',
              najvecji == null ? 'največji ulov' : najvecji.vrstaIme,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Značke ($odklenjenih / ${znacke.length})',
            style: besedilo.titleLarge),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.75,
          children: [for (final z in znacke) _ZnackaPloscica(z)],
        ),
      ],
    );
  }
}

class _Stevilka extends StatelessWidget {
  final String vrednost;
  final String oznaka;
  const _Stevilka(this.vrednost, this.oznaka);

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              child: Text(vrednost,
                  style: besedilo.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Text(oznaka,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: besedilo.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ZnackaPloscica extends StatelessWidget {
  final Znacka z;
  const _ZnackaPloscica(this.z);

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;
    return Tooltip(
      message: z.opis,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        label: '${z.ime}, ${z.odklenjena ? 'odklenjena' : 'zaklenjena'}. ${z.opis}',
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: z.odklenjena
                  ? barve.tertiaryContainer
                  : barve.surfaceContainerHighest,
              child: Icon(
                z.odklenjena ? z.ikona : Icons.lock,
                color: z.odklenjena ? barve.onTertiaryContainer : barve.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              z.ime,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                color: z.odklenjena ? null : barve.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
