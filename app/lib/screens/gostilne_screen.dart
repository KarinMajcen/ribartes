import 'package:material_ui/material_ui.dart';

import '../models/gostilna.dart';
import '../services/gostilna_service.dart';
import '../utils/format.dart';
import 'rezervacija_screen.dart';

/// Zaslon "Ti ujameš, mi spečemo" – moje rezervacije in partnerske gostilne (US-13).
class GostilneScreen extends StatefulWidget {
  const GostilneScreen({super.key});

  @override
  State<GostilneScreen> createState() => _GostilneScreenState();
}

class _GostilneScreenState extends State<GostilneScreen> {
  final _service = GostilnaService();
  late final Stream<List<Gostilna>> _gostilneTok = _service.gostilne();
  late final Stream<List<Rezervacija>> _rezervacijeTok =
      _service.mojeRezervacije();

  Future<void> _preklici(Rezervacija r) async {
    final potrdi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prekliči rezervacijo?'),
        content: Text('${r.gostilnaIme}, ${formatDatum(r.termin)} ob '
            '${formatUra(r.termin)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ne')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Prekliči rezervacijo')),
        ],
      ),
    );
    if (potrdi != true || !mounted) return;
    try {
      await _service.preklici(r.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervacija je preklicana.')),
      );
    } on RezervacijaNapaka catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.sporocilo)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ti ujameš, mi spečemo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Moje rezervacije (samo prihodnje) ---
          StreamBuilder<List<Rezervacija>>(
            stream: _rezervacijeTok,
            builder: (context, snap) {
              final prihodnje = (snap.data ?? [])
                  .where((r) => r.termin.isAfter(DateTime.now()))
                  .toList();
              if (prihodnje.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Moje rezervacije', style: besedilo.titleLarge),
                  const SizedBox(height: 8),
                  for (final r in prihodnje)
                    _RezervacijaKartica(
                      r,
                      onPreklici: r.aktivna ? () => _preklici(r) : null,
                    ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // --- Gostilne ---
          Text('Partnerske gostilne', style: besedilo.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Prinesi svoj ulov – pripravijo ga s prilogo. Plačilo ob prihodu.',
            style: besedilo.bodySmall,
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Gostilna>>(
            stream: _gostilneTok,
            builder: (context, snap) {
              if (snap.hasError) {
                return const Text('Gostiln ni bilo mogoče naložiti.');
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                children: [
                  for (final g in snap.data!) _GostilnaKartica(g),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GostilnaKartica extends StatelessWidget {
  final Gostilna g;
  const _GostilnaKartica(this.g);

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RezervacijaScreen(gostilna: g)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(radius: 24, child: Icon(Icons.restaurant)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.ime, style: besedilo.titleMedium),
                    Text('${g.kraj} · ${g.reka} · '
                        '${g.odpreOb}:00–${g.zapreOb}:00'),
                    const SizedBox(height: 4),
                    Text(g.ponudba, style: besedilo.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatCena(g.cenaPriprave), style: besedilo.titleSmall),
                  Text('na osebo', style: besedilo.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RezervacijaKartica extends StatelessWidget {
  final Rezervacija r;
  final VoidCallback? onPreklici;
  const _RezervacijaKartica(this.r, {this.onPreklici});

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;
    final preklicana = r.stanje == StanjeRezervacije.preklicana;

    return Card(
      color: preklicana ? null : barve.secondaryContainer,
      child: ListTile(
        leading: Icon(preklicana ? Icons.event_busy : Icons.event_available),
        title: Text(
          '${r.gostilnaIme} · ${formatDatum(r.termin)} ob ${formatUra(r.termin)}',
          style: preklicana
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          '${r.steviloOseb} ${r.steviloOseb == 1 ? 'oseba' : 'osebe'} · '
          '${formatCena(r.cena)}'
          '${r.ulovOpis == null ? '' : '\nUlov: ${r.ulovOpis}'}'
          '${preklicana ? '\nPreklicana' : ''}',
        ),
        isThreeLine: r.ulovOpis != null || preklicana,
        trailing: onPreklici == null
            ? null
            : IconButton(
                tooltip: 'Prekliči rezervacijo',
                icon: const Icon(Icons.close),
                onPressed: onPreklici,
              ),
      ),
    );
  }
}
