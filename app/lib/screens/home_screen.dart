import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/dovolilnica.dart';
import '../services/auth_service.dart';
import '../services/dovolilnica_service.dart';
import '../utils/format.dart';
import 'dovolilnica_qr_screen.dart';
import 'gostilne_screen.dart';
import 'lestvica_screen.dart';
import 'moje_dovolilnice_screen.dart';
import 'nov_ulov_screen.dart';
import 'preveri_dovolilnico_screen.dart';
import 'revirji_screen.dart';
import 'ribji_album_screen.dart';

/// Domači zaslon: veljavna dovolilnica na vrhu, točke in hitri dostop
/// do glavnih funkcij (zaslon 2 iz prijave ideje).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();

  // Toka ustvarimo enkrat (ne ob vsakem izrisu), da zaslon ne utripa.
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _profilTok =
      FirebaseFirestore.instance
          .collection('uporabniki')
          .doc(_auth.trenutniUporabnik!.uid)
          .snapshots();
  late final Stream<List<Dovolilnica>> _dovolilniceTok =
      DovolilnicaService().mojeDovolilnice();

  void _odpri(Widget zaslon) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => zaslon));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RIBARTes'),
        actions: [
          IconButton(
            tooltip: 'Odjava',
            icon: const Icon(Icons.logout),
            onPressed: () => _auth.odjava(),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                prvoIme.isEmpty ? 'Pozdravljen!' : 'Pozdravljen, $prvoIme',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              if (jeCuvaj) ...[
                Card(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.qr_code_scanner, size: 36),
                    title: const Text('Preveri dovolilnico'),
                    subtitle: const Text('Vloga: ribiški čuvaj'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _odpri(const PreveriDovolilnicoScreen()),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // --- Veljavna dovolilnica (ali poziv k nakupu) ---
              StreamBuilder<List<Dovolilnica>>(
                stream: _dovolilniceTok,
                builder: (context, snap) {
                  final veljavne = (snap.data ?? [])
                      .where((d) => d.stanje == StanjeDovolilnice.veljavna)
                      .toList()
                    ..sort((a, b) => a.veljaDo.compareTo(b.veljaDo));
                  if (!snap.hasData) return const SizedBox(height: 8);
                  if (veljavne.isEmpty) {
                    return _NiDovolilnice(
                        onKupi: () => _odpri(const RevirjiScreen()));
                  }
                  return Column(
                    children: [
                      for (final d in veljavne)
                        _VeljavnaDovolilnica(
                          d,
                          onTap: () => _odpri(DovolilnicaQrScreen(id: d.id)),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.stars),
                  title: const Text('Točke ujemi in spusti'),
                  subtitle: Text(tocke >= Popust.tockNaEvro
                      ? 'Na voljo za popust pri dovolilnici'
                      : 'Še ${Popust.tockNaEvro - tocke} do prvega popusta'),
                  trailing: Text(
                    '$tocke',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _Gumb(Icons.water, 'Revirji in nakup dovolilnice',
                  () => _odpri(const RevirjiScreen())),
              _Gumb(Icons.qr_code, 'Moje dovolilnice',
                  () => _odpri(const MojeDovolilniceScreen())),
              _Gumb(Icons.photo_album, 'Ribji album in ulovi',
                  () => _odpri(const RibjiAlbumScreen())),
              _Gumb(Icons.leaderboard, 'Tedenska lestvica',
                  () => _odpri(const LestvicaScreen())),
              _Gumb(Icons.restaurant, 'Ti ujameš, mi spečemo',
                  () => _odpri(const GostilneScreen())),
            ],
          );
        },
      ),
    );
  }
}

class _VeljavnaDovolilnica extends StatelessWidget {
  final Dovolilnica d;
  final VoidCallback onTap;
  const _VeljavnaDovolilnica(this.d, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final obdobje = d.vrsta == VrstaDovolilnice.dnevna
        ? 'danes do 23:59'
        : 'do ${formatDatum(d.veljaDo)}';
    return Card(
      color: Colors.green.shade700,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.qr_code_2, color: Colors.white, size: 40),
        title: Text(
          d.revirIme,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          'Veljavna ${d.vrsta.naziv.toLowerCase()} dovolilnica · $obdobje\n'
          'Tapni za QR kodo',
          style: const TextStyle(color: Colors.white),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
        onTap: onTap,
      ),
    );
  }
}

class _NiDovolilnice extends StatelessWidget {
  final VoidCallback onKupi;
  const _NiDovolilnice({required this.onKupi});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: const Icon(Icons.info_outline, size: 32),
        title: const Text('Danes nimaš veljavne dovolilnice'),
        trailing: FilledButton(onPressed: onKupi, child: const Text('Kupi')),
      ),
    );
  }
}

class _Gumb extends StatelessWidget {
  final IconData ikona;
  final String besedilo;
  final VoidCallback onTap;
  const _Gumb(this.ikona, this.besedilo, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(ikona),
        title: Text(besedilo),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
