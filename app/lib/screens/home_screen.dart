import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'revirji_screen.dart';

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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                prvoIme.isEmpty ? 'Pozdravljen!' : 'Pozdravljen, $prvoIme',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
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
              const _Gumb(ikona: Icons.qr_code, besedilo: 'Moje dovolilnice'),
              const _Gumb(ikona: Icons.photo_album, besedilo: 'Ribji album'),
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
