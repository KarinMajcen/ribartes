import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Domači zaslon – za zdaj pozdrav, točke, odjava (US-02) in
/// gumbi za funkcije, ki jih dodamo v naslednjih korakih.
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
              _Gumb(ikona: Icons.water, besedilo: 'Revirji'),
              _Gumb(ikona: Icons.qr_code, besedilo: 'Moje dovolilnice'),
              _Gumb(ikona: Icons.photo_album, besedilo: 'Ribji album'),
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

  const _Gumb({required this.ikona, required this.besedilo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(ikona),
        title: Text(besedilo),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$besedilo – kmalu')),
        ),
      ),
    );
  }
}
