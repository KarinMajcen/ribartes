import 'package:flutter/material.dart';

import '../models/revir.dart';
import '../utils/format.dart';

/// Zaslon "Podrobnosti revirja" – pokriva US-04.
class RevirDetailScreen extends StatelessWidget {
  final Revir revir;
  const RevirDetailScreen({super.key, required this.revir});

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(revir.ime)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${revir.reka} · ${revir.ribiskaDruzina}',
              style: besedilo.titleMedium),
          const SizedBox(height: 8),
          Text(revir.opis),
          const SizedBox(height: 24),

          Text('Vrste rib', style: besedilo.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in revir.vrste)
                Chip(avatar: const Icon(Icons.phishing, size: 18), label: Text(v)),
            ],
          ),
          const SizedBox(height: 24),

          Text('Pravila revirja', style: besedilo.titleLarge),
          const SizedBox(height: 8),
          for (final p in revir.pravila)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(p)),
                ],
              ),
            ),
          const SizedBox(height: 24),

          Text('Cene dovolilnic', style: besedilo.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _VrsticaCene('Dnevna', revir.cenaDnevna),
                const Divider(height: 1),
                _VrsticaCene('Tedenska', revir.cenaTedenska),
                const Divider(height: 1),
                _VrsticaCene('Letna', revir.cenaLetna),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Kupi dovolilnico'),
            // US-05 (nakup) dodamo v naslednjem koraku.
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nakup dovolilnice – kmalu')),
            ),
          ),
        ),
      ),
    );
  }
}

class _VrsticaCene extends StatelessWidget {
  final String vrsta;
  final double cena;
  const _VrsticaCene(this.vrsta, this.cena);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(vrsta),
      trailing: Text(
        formatCena(cena),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
