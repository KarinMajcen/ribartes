import 'dart:io';

import 'package:flutter/material.dart';

import '../models/ulov.dart';
import '../models/vrsta_ribe.dart';
import '../services/ulov_service.dart';
import '../utils/format.dart';
import 'nov_ulov_screen.dart';

/// Zaslon "Ribji album" – zavihka Album (US-08) in Moji ulovi (US-07).
class RibjiAlbumScreen extends StatefulWidget {
  const RibjiAlbumScreen({super.key});

  @override
  State<RibjiAlbumScreen> createState() => _RibjiAlbumScreenState();
}

class _RibjiAlbumScreenState extends State<RibjiAlbumScreen> {
  final _service = UlovService();
  late final Stream<List<VrstaRibe>> _vrsteTok = _service.vrsteRib();
  late final Stream<List<Ulov>> _uloviTok = _service.mojiUlovi();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ribji album'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.grid_view), text: 'Album'),
              Tab(icon: Icon(Icons.list), text: 'Moji ulovi'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Nov ulov'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NovUlovScreen()),
          ),
        ),
        body: StreamBuilder<List<VrstaRibe>>(
          stream: _vrsteTok,
          builder: (context, vrsteSnap) {
            return StreamBuilder<List<Ulov>>(
              stream: _uloviTok,
              builder: (context, uloviSnap) {
                if (vrsteSnap.hasError || uloviSnap.hasError) {
                  return const Center(
                      child: Text('Podatkov ni bilo mogoče naložiti.'));
                }
                if (!vrsteSnap.hasData || !uloviSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final vrste = vrsteSnap.data!;
                final ulovi = uloviSnap.data!;
                return TabBarView(
                  children: [
                    _Album(vrste: vrste, ulovi: ulovi),
                    _SeznamUlovov(ulovi: ulovi),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Album (US-08)

class _Album extends StatelessWidget {
  final List<VrstaRibe> vrste;
  final List<Ulov> ulovi;
  const _Album({required this.vrste, required this.ulovi});

  @override
  Widget build(BuildContext context) {
    // Za vsako vrsto: koliko ulovov in največja dolžina.
    final steviloPoVrsti = <String, int>{};
    final najdaljsiPoVrsti = <String, double>{};
    for (final u in ulovi) {
      steviloPoVrsti[u.vrstaId] = (steviloPoVrsti[u.vrstaId] ?? 0) + 1;
      final dosedanji = najdaljsiPoVrsti[u.vrstaId] ?? 0;
      if (u.dolzinaCm > dosedanji) najdaljsiPoVrsti[u.vrstaId] = u.dolzinaCm;
    }
    final zbranih = vrste.where((v) => steviloPoVrsti.containsKey(v.id)).length;
    final besedilo = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text('Zbranih $zbranih / ${vrste.length}', style: besedilo.titleLarge),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: vrste.isEmpty ? 0 : zbranih / vrste.length,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.8,
          children: [
            for (final v in vrste)
              _Kartica(
                vrsta: v,
                stevilo: steviloPoVrsti[v.id] ?? 0,
                najdaljsi: najdaljsiPoVrsti[v.id],
                ulovi: ulovi.where((u) => u.vrstaId == v.id).toList(),
              ),
          ],
        ),
      ],
    );
  }
}

class _Kartica extends StatelessWidget {
  final VrstaRibe vrsta;
  final int stevilo;
  final double? najdaljsi;
  final List<Ulov> ulovi;
  const _Kartica({
    required this.vrsta,
    required this.stevilo,
    this.najdaljsi,
    required this.ulovi,
  });

  void _podrobnosti(BuildContext context) {
    if (stevilo == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ujemi ${vrsta.ime}, da odkleneš kartico.'),
      ));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PodrobnostiVrste(vrsta: vrsta, ulovi: ulovi),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;
    final odklenjena = stevilo > 0;

    return GestureDetector(
      onTap: () => _podrobnosti(context),
      child: Semantics(
      button: true,
      label: odklenjena
          ? '${vrsta.ime}, ujetih $stevilo'
          : '${vrsta.ime}, zaklenjena kartica',
      child: Card(
        color: odklenjena
            ? barve.primaryContainer
            : barve.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                odklenjena ? Icons.phishing : Icons.lock,
                size: 40,
                color: odklenjena ? barve.primary : barve.outline,
              ),
              const SizedBox(height: 8),
              Text(
                vrsta.ime,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: odklenjena ? null : barve.outline,
                ),
              ),
              if (odklenjena) ...[
                const SizedBox(height: 4),
                Text(
                  '×$stevilo · ${najdaljsi!.toStringAsFixed(0)} cm',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Spodnji list s podrobnostmi odklenjene vrste.
class _PodrobnostiVrste extends StatelessWidget {
  final VrstaRibe vrsta;
  final List<Ulov> ulovi;
  const _PodrobnostiVrste({required this.vrsta, required this.ulovi});

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    final barve = Theme.of(context).colorScheme;
    final razvrsceni = [...ulovi]
      ..sort((a, b) => b.dolzinaCm.compareTo(a.dolzinaCm));
    final spuscenih = ulovi.where((u) => u.spuscena).length;
    final prvi = ulovi.map((u) => u.datum).reduce((a, b) => a.isBefore(b) ? a : b);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: barve.primaryContainer,
                  child: Icon(Icons.phishing, color: barve.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vrsta.ime[0].toUpperCase()}${vrsta.ime.substring(1)}',
                        style: besedilo.headlineSmall,
                      ),
                      Text(vrsta.latinsko,
                          style: besedilo.bodyMedium
                              ?.copyWith(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Kartica odklenjena ${formatDatum(prvi)} · '
                'ulovov: ${ulovi.length} · vrnjenih v reko: $spuscenih'),
            const SizedBox(height: 16),
            Text('Moji ulovi te vrste', style: besedilo.titleMedium),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < razvrsceni.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text(i == 0 ? '🏆' : '${i + 1}.',
                          style: const TextStyle(fontSize: 18)),
                      title: Text(
                          '${razvrsceni[i].dolzinaCm.toStringAsFixed(0)} cm'
                          '${razvrsceni[i].tezaKg == null ? '' : ' · ${razvrsceni[i].tezaKg!.toStringAsFixed(1)} kg'}'),
                      subtitle: Text('${formatDatum(razvrsceni[i].datum)}'
                          '${razvrsceni[i].revirIme == null ? '' : ' · ${razvrsceni[i].revirIme}'}'),
                      trailing: razvrsceni[i].spuscena
                          ? const Icon(Icons.eco, color: Colors.green)
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------- Moji ulovi (US-07)

class _SeznamUlovov extends StatelessWidget {
  final List<Ulov> ulovi;
  const _SeznamUlovov({required this.ulovi});

  @override
  Widget build(BuildContext context) {
    if (ulovi.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Še nimate ulovov.\nTapnite »Nov ulov«.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: ulovi.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Za brisanje ulov povleci v levo.',
                style: Theme.of(context).textTheme.bodySmall),
          );
        }
        final u = ulovi[i - 1];
        return Dismissible(
          key: ValueKey(u.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.delete,
                color: Theme.of(context).colorScheme.onError),
          ),
          confirmDismiss: (_) => showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Izbriši ulov?'),
              content: Text(
                '${u.vrstaIme}, ${u.dolzinaCm.toStringAsFixed(0)} cm, '
                '${formatDatum(u.datum)}'
                '${u.spuscena ? '\nOdšteli bomo tudi ${Tocke.zaSpuscenoRibo} točk.' : ''}',
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Prekliči')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Izbriši')),
              ],
            ),
          ),
          onDismissed: (_) async {
            await UlovService().izbrisi(u);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ulov je izbrisan.')),
              );
            }
          },
          child: _UlovKartica(u),
        );
      },
    );
  }
}

class _UlovKartica extends StatelessWidget {
  final Ulov u;
  const _UlovKartica(this.u);

  @override
  Widget build(BuildContext context) {
    final imaFoto = u.fotoPot != null && File(u.fotoPot!).existsSync();
    final teza = u.tezaKg == null ? '' : ' · ${u.tezaKg!.toStringAsFixed(1)} kg';
    final kraj = u.revirIme == null ? '' : ' · ${u.revirIme}';

    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imaFoto
              ? Image.file(File(u.fotoPot!),
                  width: 56, height: 56, fit: BoxFit.cover)
              : Container(
                  width: 56,
                  height: 56,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.phishing),
                ),
        ),
        title: Text('${u.vrstaIme} · ${u.dolzinaCm.toStringAsFixed(0)} cm$teza'),
        subtitle: Text('${formatDatum(u.datum)}$kraj'),
        trailing: u.spuscena
            ? const Tooltip(
                message: 'Vrnjena v reko',
                child: Icon(Icons.eco, color: Colors.green),
              )
            : null,
      ),
    );
  }
}
