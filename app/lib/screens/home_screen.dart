import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../models/dovolilnica.dart';
import '../models/ulov.dart';
import '../models/vrsta_ribe.dart';
import '../services/auth_service.dart';
import '../services/dovolilnica_service.dart';
import '../services/ulov_service.dart';
import '../tema/tema.dart';
import '../utils/format.dart';
import '../widgets/valovi_glava.dart';
import 'app_shell.dart';
import 'dovolilnica_qr_screen.dart';
import 'gostilne_screen.dart';
import 'lestvica_screen.dart';
import 'nov_ulov_screen.dart';
import 'preveri_dovolilnico_screen.dart';

/// Domači zaslon.
///
/// Zgradba (od zgoraj navzdol, po pomembnosti):
///   1. glava z valovi – pozdrav in nasvet dneva (edini velik barvni element)
///   2. pas s statistiko – točke, ulovi, kartice
///   3. "Danes ob vodi" – veljavne dovolilnice v eni kartici; opozorilo o
///      poteku je kar v vrstici, ne v ločenem bloku
///   4. hitri dostop
class HomeScreen extends StatefulWidget {
  /// Preklop na drug zavihek spodnje vrstice (npr. Revirji).
  final void Function(int zavihek)? onPojdiNa;

  const HomeScreen({super.key, this.onPojdiNa});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _ulovService = UlovService();

  // Toke ustvarimo enkrat (ne ob vsakem izrisu), da zaslon ne utripa.
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _profilTok =
      FirebaseFirestore.instance
          .collection('uporabniki')
          .doc(_auth.trenutniUporabnik!.uid)
          .snapshots();
  late final Stream<List<Dovolilnica>> _dovolilniceTok =
      DovolilnicaService().mojeDovolilnice();
  late final Stream<List<Ulov>> _uloviTok = _ulovService.mojiUlovi();
  late final Stream<List<VrstaRibe>> _vrsteTok = _ulovService.vrsteRib();

  void _odpri(Widget zaslon) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => zaslon));

  void _zavihek(int z) => widget.onPojdiNa?.call(z);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RIBARTes'),
        actions: [
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _zavihek(Zavihek.profil),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nov ulov'),
        onPressed: () => _odpri(const NovUlovScreen()),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _profilTok,
        builder: (context, snapshot) {
          final podatki = snapshot.data?.data();
          final ime = (podatki?['ime'] as String?) ?? '';
          final prvoIme = ime.split(' ').first;
          final tocke = (podatki?['tocke'] as num?)?.toInt() ?? 0;
          // Vlogo "cuvaj" nastavi upravljavec v bazi; ribič si je ne more sam.
          final jeCuvaj = podatki?['vloga'] == 'cuvaj';

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                Razmik.l, Razmik.xs, Razmik.l, 100),
            children: [
              ValoviGlava(ime: prvoIme),
              const SizedBox(height: Razmik.l),

              if (jeCuvaj) ...[
                _CuvajVrstica(
                    onTap: () => _odpri(const PreveriDovolilnicoScreen())),
                const SizedBox(height: Razmik.l),
              ],

              // --- Statistika ---
              StreamBuilder<List<Ulov>>(
                stream: _uloviTok,
                builder: (context, uloviSnap) => StreamBuilder<List<VrstaRibe>>(
                  stream: _vrsteTok,
                  builder: (context, vrsteSnap) => _StatistikaPas(
                    tocke: tocke,
                    ulovi: uloviSnap.data ?? const [],
                    vsehVrst: vrsteSnap.data?.length ?? 0,
                    onAlbum: () => _zavihek(Zavihek.album),
                  ),
                ),
              ),
              const SizedBox(height: Razmik.xl),

              // --- Danes ob vodi ---
              _Naslov(
                'Danes ob vodi',
                akcija: 'Vse dovolilnice',
                onAkcija: () => _zavihek(Zavihek.dovolilnice),
              ),
              StreamBuilder<List<Dovolilnica>>(
                stream: _dovolilniceTok,
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox(height: 72);
                  final veljavne = snap.data!
                      .where((d) => d.stanje == StanjeDovolilnice.veljavna)
                      .toList()
                    ..sort((a, b) => a.veljaDo.compareTo(b.veljaDo));
                  return _DovolilniceDanes(
                    veljavne: veljavne,
                    onOdpri: (d) => _odpri(DovolilnicaQrScreen(id: d.id)),
                    onKupi: () => _zavihek(Zavihek.revirji),
                  );
                },
              ),
              const SizedBox(height: Razmik.xl),

              // --- Hitri dostop ---
              const _Naslov('Hitri dostop'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Razmik.m,
                crossAxisSpacing: Razmik.m,
                childAspectRatio: 1.55,
                children: [
                  _Ploscica(Icons.water_outlined, 'Revirji',
                      'Kupi dovolilnico', () => _zavihek(Zavihek.revirji)),
                  _Ploscica(Icons.photo_album_outlined, 'Ribji album',
                      'Kartice in ulovi', () => _zavihek(Zavihek.album)),
                  _Ploscica(Icons.leaderboard_outlined, 'Lestvica',
                      'Največji ulovi tedna',
                      () => _odpri(const LestvicaScreen())),
                  _Ploscica(Icons.restaurant_outlined, 'Gostilne',
                      'Ti ujameš, mi spečemo',
                      () => _odpri(const GostilneScreen())),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────── sestavni deli

class _Naslov extends StatelessWidget {
  final String besedilo;
  final String? akcija;
  final VoidCallback? onAkcija;
  const _Naslov(this.besedilo, {this.akcija, this.onAkcija});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Razmik.s),
      child: Row(
        children: [
          Expanded(
            child: Text(besedilo,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          if (akcija != null)
            TextButton(onPressed: onAkcija, child: Text(akcija!)),
        ],
      ),
    );
  }
}

/// Ena kartica s tremi številkami. Točke so v barvi nagrad, pod njimi
/// tanek napredek do prvega popusta.
class _StatistikaPas extends StatelessWidget {
  final int tocke;
  final List<Ulov> ulovi;
  final int vsehVrst;
  final VoidCallback onAlbum;

  const _StatistikaPas({
    required this.tocke,
    required this.ulovi,
    required this.vsehVrst,
    required this.onAlbum,
  });

  @override
  Widget build(BuildContext context) {
    final rb = context.ribartes;
    final vrst = ulovi.map((u) => u.vrstaId).toSet().length;
    final doPopusta = Popust.tockNaEvro - tocke;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: Razmik.l, horizontal: Razmik.s),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _Stevilka(
                  vrednost: '$tocke',
                  oznaka: 'točk',
                  barva: rb.nagradaBesedilo,
                  dodatek: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Razmik.m, Razmik.s, Razmik.m, 0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: doPopusta > 0
                                ? tocke / Popust.tockNaEvro
                                : 1,
                            minHeight: 5,
                            color: rb.nagrada,
                            backgroundColor:
                                rb.nagrada.withValues(alpha: 0.18),
                          ),
                        ),
                        const SizedBox(height: Razmik.xs),
                        Text(
                          doPopusta > 0
                              ? 'še $doPopusta do popusta'
                              : 'popust na voljo',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              VerticalDivider(color: rb.rob, width: 1),
              Expanded(
                child: _Stevilka(vrednost: '${ulovi.length}', oznaka: 'ulovov'),
              ),
              VerticalDivider(color: rb.rob, width: 1),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(Zaobljenost.gumb),
                  onTap: onAlbum,
                  child: _Stevilka(
                      vrednost: '$vrst/$vsehVrst', oznaka: 'kartic v albumu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stevilka extends StatelessWidget {
  final String vrednost;
  final String oznaka;
  final Color? barva;
  final Widget? dodatek;
  const _Stevilka(
      {required this.vrednost, required this.oznaka, this.barva, this.dodatek});

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(vrednost,
            style: besedilo.headlineMedium?.copyWith(color: barva)),
        Text(oznaka, style: besedilo.bodySmall, textAlign: TextAlign.center),
        if (dodatek != null) dodatek!,
      ],
    );
  }
}

/// Veljavne dovolilnice kot vrstice v eni kartici. Zelena je le majhna
/// ikona, opozorilo o poteku je jantarno besedilo v sami vrstici.
class _DovolilniceDanes extends StatelessWidget {
  final List<Dovolilnica> veljavne;
  final ValueChanged<Dovolilnica> onOdpri;
  final VoidCallback onKupi;

  const _DovolilniceDanes({
    required this.veljavne,
    required this.onOdpri,
    required this.onKupi,
  });

  @override
  Widget build(BuildContext context) {
    final rb = context.ribartes;
    final besedilo = Theme.of(context).textTheme;

    if (veljavne.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(Razmik.l),
          child: Row(
            children: [
              _IkonaVKrogu(Icons.qr_code_2, rb.nevtralno),
              const SizedBox(width: Razmik.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danes nimaš veljavne dovolilnice',
                        style: besedilo.titleMedium),
                    Text('Izberi revir in jo kupi v nekaj korakih.',
                        style: besedilo.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: Razmik.s),
              FilledButton.tonal(onPressed: onKupi, child: const Text('Kupi')),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < veljavne.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 72, color: rb.rob),
            _VrsticaDovolilnice(veljavne[i], onTap: () => onOdpri(veljavne[i])),
          ],
        ],
      ),
    );
  }
}

class _VrsticaDovolilnice extends StatelessWidget {
  final Dovolilnica d;
  final VoidCallback onTap;
  const _VrsticaDovolilnice(this.d, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rb = context.ribartes;
    final besedilo = Theme.of(context).textTheme;
    final ostane = d.veljaDo.difference(DateTime.now());
    final kmalu = ostane.inHours < 24;
    final cez = ostane.inHours >= 1
        ? 'poteče čez ${ostane.inHours} h'
        : 'poteče čez ${ostane.inMinutes.clamp(1, 59)} min';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Razmik.l, vertical: Razmik.m),
        child: Row(
          children: [
            _IkonaVKrogu(Icons.qr_code_2, rb.uspeh),
            const SizedBox(width: Razmik.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.revirIme, style: besedilo.titleMedium),
                  Text.rich(
                    TextSpan(
                      style: besedilo.bodySmall,
                      children: [
                        TextSpan(text: '${d.vrsta.naziv} · '),
                        TextSpan(
                          text: kmalu ? cez : 'do ${formatDatum(d.veljaDo)}',
                          style: kmalu
                              ? TextStyle(
                                  color: rb.opozorilo,
                                  fontWeight: FontWeight.w700)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text('QR',
                style: besedilo.labelMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _IkonaVKrogu extends StatelessWidget {
  final IconData ikona;
  final Color barva;
  const _IkonaVKrogu(this.ikona, this.barva);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: barva.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Zaobljenost.gumb),
      ),
      child: Icon(ikona, color: barva),
    );
  }
}

class _CuvajVrstica extends StatelessWidget {
  final VoidCallback onTap;
  const _CuvajVrstica({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Razmik.l, vertical: Razmik.xs),
        leading: _IkonaVKrogu(Icons.qr_code_scanner, barve.primary),
        title: const Text('Preveri dovolilnico'),
        subtitle: const Text('Vloga: ribiški čuvaj'),
        trailing: Icon(Icons.chevron_right, color: barve.primary),
        onTap: onTap,
      ),
    );
  }
}

class _Ploscica extends StatelessWidget {
  final IconData ikona;
  final String naslov;
  final String podnaslov;
  final VoidCallback onTap;
  const _Ploscica(this.ikona, this.naslov, this.podnaslov, this.onTap);

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;
    final besedilo = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Razmik.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IkonaVKrogu(ikona, barve.primary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(naslov, style: besedilo.titleMedium),
                  Text(podnaslov,
                      style: besedilo.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
