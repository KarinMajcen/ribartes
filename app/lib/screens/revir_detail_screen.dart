import 'package:material_ui/material_ui.dart';

import '../models/revir.dart';
import '../utils/format.dart';
import '../widgets/reka_glava.dart';
import '../widgets/vreme_kartica.dart';
import 'nakup_screen.dart';

/// Zaslon "Podrobnosti revirja" – pokriva US-04.
class RevirDetailScreen extends StatelessWidget {
  final Revir revir;
  const RevirDetailScreen({super.key, required this.revir});

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Velika barvna glava, ki se ob drsenju skrči v običajno vrstico.
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            foregroundColor: Colors.white,
            backgroundColor: barveReke(revir.reka).last,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                  start: 56, bottom: 14, end: 16),
              title: Text(
                revir.ime,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              background: Hero(
                tag: 'revir-${revir.id}',
                child: RekaGlava(
                  reka: revir.reka,
                  visina: 260,
                  otrok: Align(
                    alignment: const Alignment(0.85, -0.1),
                    child: Icon(Icons.phishing,
                        size: 72,
                        color: Colors.white.withValues(alpha: 0.35)),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                Text('${revir.reka} · ${revir.ribiskaDruzina}',
                    style: besedilo.titleMedium),
                const SizedBox(height: 8),
                Text(revir.opis),
                const SizedBox(height: 24),

                if (revir.lat != null && revir.lng != null) ...[
                  Text('Vreme ob revirju', style: besedilo.titleLarge),
                  const SizedBox(height: 8),
                  VremeKartica(lat: revir.lat!, lng: revir.lng!),
                  const SizedBox(height: 24),
                ],

                Text('Vrste rib', style: besedilo.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final v in revir.vrste)
                      Chip(
                          avatar: const Icon(Icons.phishing, size: 18),
                          label: Text(v)),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Pravila revirja', style: besedilo.titleLarge),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (final p in revir.pravila)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.rule,
                                    size: 18,
                                    color: barveReke(revir.reka).last),
                                const SizedBox(width: 8),
                                Expanded(child: Text(p)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Cene dovolilnic', style: besedilo.titleLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _Cena('Dnevna', revir.cenaDnevna)),
                    const SizedBox(width: 8),
                    Expanded(child: _Cena('Tedenska', revir.cenaTedenska)),
                    const SizedBox(width: 8),
                    Expanded(child: _Cena('Letna', revir.cenaLetna)),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: barveReke(revir.reka).last,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Kupi dovolilnico'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NakupScreen(revir: revir)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cena extends StatelessWidget {
  final String vrsta;
  final double cena;
  const _Cena(this.vrsta, this.cena);

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(vrsta, style: besedilo.bodySmall),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(formatCena(cena),
                  style: besedilo.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
