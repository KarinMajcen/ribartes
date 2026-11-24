import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'gostilne_screen.dart';
import 'lestvica_screen.dart';
import 'moje_dovolilnice_screen.dart';
import 'preveri_dovolilnico_screen.dart';
import 'revirji_screen.dart';
import 'ribji_album_screen.dart';

/// Domači zaslon – pozdrav, točke, odjava (US-02) in
/// vstop v glavne funkcije aplikacije.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final uid = auth.trenutniUporabnik!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RIBARTes'),
        actions: [
          IconButton(
            tooltip: 'Odjava',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.odjava(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // Posluša profil ribiča; ob spremembi (npr. nove točke) se zaslon osveži sam.
        stream: FirebaseFirestore.instance
            .collection('uporabniki')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          final podatki = snapshot.data?.data();
          final ime = (podatki?['ime'] as String?) ?? '';
          final prvoIme = ime.split(' ').first;
          final tocke = (podatki?['tocke'] as num?)?.toInt() ?? 0;
          // Vlogo "cuvaj" nastavi upravljavec v bazi; ribič si je ne more sam.
          final jeCuvaj = podatki?['vloga'] == 'cuvaj';

          return ListView(
            padding: const EdgeInsets.all(16),
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
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PreveriDovolilnicoScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Card(
                child: ListTile(
                  leading: const Icon(Icons.stars),
                  title: const Text('Točke ujemi in spusti'),
                  trailing: Text(
                    '$tocke',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Gumb(
                ikona: Icons.water,
                besedilo: 'Revirji',
                zaslon: const RevirjiScreen(),
              ),
              _Gumb(
                ikona: Icons.qr_code,
                besedilo: 'Moje dovolilnice',
                zaslon: const MojeDovolilniceScreen(),
              ),
              _Gumb(
                ikona: Icons.photo_album,
                besedilo: 'Ribji album in ulovi',
                zaslon: const RibjiAlbumScreen(),
              ),
              _Gumb(
                ikona: Icons.leaderboard,
                besedilo: 'Tedenska lestvica',
                zaslon: const LestvicaScreen(),
              ),
              _Gumb(
                ikona: Icons.restaurant,
                besedilo: 'Ti ujameš, mi spečemo',
                zaslon: const GostilneScreen(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Gumb extends StatelessWidget {
  final IconData ikona;
  final String besedilo;

  /// Zaslon, ki se odpre ob tapu. Če ga še ni, se pokaže "kmalu".
  final Widget? zaslon;

  const _Gumb({required this.ikona, required this.besedilo, this.zaslon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(ikona),
        title: Text(besedilo),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (zaslon != null) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => zaslon!));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$besedilo – kmalu')),
            );
          }
        },
      ),
    );
  }
}
