import 'package:material_ui/material_ui.dart';

import '../models/gostilna.dart';
import '../models/ulov.dart';
import '../services/gostilna_service.dart';
import '../services/ulov_service.dart';
import '../utils/format.dart';

/// Zaslon "Rezervacija" v izbrani gostilni – pokriva US-13.
class RezervacijaScreen extends StatefulWidget {
  final Gostilna gostilna;
  const RezervacijaScreen({super.key, required this.gostilna});

  @override
  State<RezervacijaScreen> createState() => _RezervacijaScreenState();
}

class _RezervacijaScreenState extends State<RezervacijaScreen> {
  final _service = GostilnaService();
  final _opombaCtrl = TextEditingController();
  late final Stream<List<Ulov>> _uloviTok = UlovService().mojiUlovi();

  late DateTime _dan = _danes;
  DateTime? _termin;
  int _osebe = 1;
  String? _ulovId;
  Map<String, Ulov> _ulovi = {};
  bool _nalaganje = false;
  String? _napaka;

  DateTime get _danes {
    final z = DateTime.now();
    return DateTime(z.year, z.month, z.day);
  }

  @override
  void dispose() {
    _opombaCtrl.dispose();
    super.dispose();
  }

  Future<void> _izberiDan() async {
    final izbran = await showDatePicker(
      context: context,
      initialDate: _dan,
      firstDate: _danes,
      lastDate: _danes.add(const Duration(days: 30)),
      helpText: 'Dan rezervacije',
    );
    if (izbran != null) {
      setState(() {
        _dan = izbran;
        _termin = null; // termini so odvisni od dneva
      });
    }
  }

  Future<void> _rezerviraj() async {
    final termin = _termin;
    if (termin == null) return;
    setState(() {
      _nalaganje = true;
      _napaka = null;
    });
    try {
      await _service.rezerviraj(
        gostilna: widget.gostilna,
        termin: termin,
        steviloOseb: _osebe,
        ulov: _ulovId == null ? null : _ulovi[_ulovId],
        opomba: _opombaCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rezervacija potrjena za ${formatUra(termin)}.'),
        ),
      );
      Navigator.of(context).pop();
    } on RezervacijaNapaka catch (e) {
      if (mounted) setState(() => _napaka = e.sporocilo);
    } finally {
      if (mounted) setState(() => _nalaganje = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gostilna;
    final besedilo = Theme.of(context).textTheme;
    final barve = Theme.of(context).colorScheme;
    final termini = g.prostiTermini(_dan);
    // Če je izbrani termin medtem minil, ga ne štejemo več (scenarij "ura v preteklosti").
    final termin = (_termin != null && termini.contains(_termin)) ? _termin : null;

    return Scaffold(
      appBar: AppBar(title: Text(g.ime)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${g.kraj} · ${g.reka}', style: besedilo.titleMedium),
          const SizedBox(height: 4),
          Text(g.opis),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.set_meal),
              title: Text(g.ponudba),
              subtitle: Text('Priprava tvojega ulova · '
                  'odprto ${g.odpreOb}:00–${g.zapreOb}:00'),
              trailing: Text('${formatCena(g.cenaPriprave)}\nna osebo',
                  textAlign: TextAlign.end),
            ),
          ),
          const SizedBox(height: 24),

          // --- Dan ---
          Text('Dan', style: besedilo.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(_dan == _danes
                  ? 'Danes, ${formatDatum(_dan)}'
                  : formatDatum(_dan)),
              trailing: const Icon(Icons.edit),
              onTap: _nalaganje ? null : _izberiDan,
            ),
          ),
          const SizedBox(height: 16),

          // --- Ura ---
          Text('Ura', style: besedilo.titleMedium),
          const SizedBox(height: 8),
          if (termini.isEmpty)
            Text('Za ta dan ni več prostih terminov. Izberi drug dan.',
                style: TextStyle(color: barve.error))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in termini)
                  ChoiceChip(
                    label: Text(formatUra(t)),
                    selected: t == termin,
                    onSelected: _nalaganje
                        ? null
                        : (_) => setState(() => _termin = t),
                  ),
              ],
            ),
          const SizedBox(height: 16),

          // --- Število oseb ---
          Row(
            children: [
              Expanded(child: Text('Število oseb', style: besedilo.titleMedium)),
              IconButton.outlined(
                tooltip: 'Manj oseb',
                icon: const Icon(Icons.remove),
                onPressed: _osebe > 1 ? () => setState(() => _osebe--) : null,
              ),
              SizedBox(
                width: 40,
                child: Text('$_osebe',
                    textAlign: TextAlign.center, style: besedilo.titleLarge),
              ),
              IconButton.outlined(
                tooltip: 'Več oseb',
                icon: const Icon(Icons.add),
                onPressed: _osebe < 8 ? () => setState(() => _osebe++) : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Kateri ulov naj pripravijo (neobvezno) ---
          StreamBuilder<List<Ulov>>(
            stream: _uloviTok,
            builder: (context, snap) {
              // Ponudimo neizpuščene ulove zadnjih 7 dni.
              final meja = DateTime.now().subtract(const Duration(days: 7));
              final primerni = (snap.data ?? [])
                  .where((u) => !u.spuscena && u.datum.isAfter(meja))
                  .toList();
              _ulovi = {for (final u in primerni) u.id: u};
              return DropdownButtonFormField<String?>(
                initialValue: _ulovId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kateri ulov naj pripravimo?',
                  prefixIcon: Icon(Icons.phishing),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('Povem ob prihodu')),
                  for (final u in primerni)
                    DropdownMenuItem<String?>(
                      value: u.id,
                      child: Text('${u.vrstaIme}, '
                          '${u.dolzinaCm.toStringAsFixed(0)} cm · '
                          '${formatDatum(u.datum)}'),
                    ),
                ],
                onChanged: (id) => setState(() => _ulovId = id),
              );
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _opombaCtrl,
            maxLines: 2,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Opomba (neobvezno)',
              hintText: 'npr. brez glutena, otroški stolček',
            ),
          ),

          if (_napaka != null) ...[
            const SizedBox(height: 8),
            Text(_napaka!,
                style: TextStyle(color: barve.error),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: _nalaganje
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.event_available),
            label: Text(termin == null
                ? 'Izberi uro'
                : 'Rezerviraj ob ${formatUra(termin)} · '
                    '${formatCena(g.cenaPriprave * _osebe)}'),
            // Brez izbrane (prihodnje) ure je gumb onemogočen.
            onPressed: (termin == null || _nalaganje) ? null : _rezerviraj,
          ),
        ),
      ),
    );
  }
}
