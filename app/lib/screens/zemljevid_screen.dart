import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../data/koordinate.dart';
import '../models/gostilna.dart';
import '../models/revir.dart';
import '../services/gostilna_service.dart';
import '../services/revir_service.dart';
import '../utils/format.dart';
import '../widgets/reka_glava.dart';
import '../widgets/vreme_kartica.dart';
import 'revir_detail_screen.dart';
import 'rezervacija_screen.dart';
import '../tema/tema.dart';

/// Zemljevid revirjev in partnerskih gostiln (OpenStreetMap).
class ZemljevidScreen extends StatefulWidget {
  const ZemljevidScreen({super.key});

  @override
  State<ZemljevidScreen> createState() => _ZemljevidScreenState();
}

class _ZemljevidScreenState extends State<ZemljevidScreen> {
  late final Stream<List<Revir>> _revirjiTok = RevirService().vsiRevirji();
  late final Stream<List<Gostilna>> _gostilneTok = GostilnaService().gostilne();

  Revir? _izbranRevir;
  Gostilna? _izbranaGostilna;

  void _izberiRevir(Revir r) => setState(() {
        _izbranRevir = r;
        _izbranaGostilna = null;
      });

  void _izberiGostilno(Gostilna g) => setState(() {
        _izbranaGostilna = g;
        _izbranRevir = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zemljevid')),
      body: StreamBuilder<List<Revir>>(
        stream: _revirjiTok,
        builder: (context, revirjiSnap) {
          return StreamBuilder<List<Gostilna>>(
            stream: _gostilneTok,
            builder: (context, gostilneSnap) {
              final revirji = (revirjiSnap.data ?? [])
                  .where((r) => r.lat != null && r.lng != null)
                  .toList();
              final gostilne = (gostilneSnap.data ?? [])
                  .where((g) => koordinateGostiln.containsKey(g.id))
                  .toList();

              return Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(46.05, 14.6), // Slovenija
                      initialZoom: 7.8,
                      minZoom: 6,
                      maxZoom: 17,
                      onTap: (_, __) => setState(() {
                        _izbranRevir = null;
                        _izbranaGostilna = null;
                      }),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'si.ribartes.ribartes',
                      ),
                      MarkerLayer(
                        markers: [
                          for (final g in gostilne)
                            Marker(
                              point: LatLng(koordinateGostiln[g.id]!.$1,
                                  koordinateGostiln[g.id]!.$2),
                              width: 40,
                              height: 40,
                              child: _Oznaka(
                                barva: Paleta.tolmun,
                                ikona: Icons.restaurant,
                                izbrana: _izbranaGostilna?.id == g.id,
                                onTap: () => _izberiGostilno(g),
                                opis: g.ime,
                              ),
                            ),
                          for (final r in revirji)
                            Marker(
                              point: LatLng(r.lat!, r.lng!),
                              width: 48,
                              height: 48,
                              child: _Oznaka(
                                barva: barveReke(r.reka).last,
                                ikona: Icons.phishing,
                                izbrana: _izbranRevir?.id == r.id,
                                onTap: () => _izberiRevir(r),
                                opis: r.ime,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Navedba vira – zahtevana pri uporabi OpenStreetMap.
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: Colors.white.withValues(alpha: 0.8),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ),

                  // Legenda
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(children: [
                              Icon(Icons.phishing, size: 18),
                              SizedBox(width: 6),
                              Text('Revir'),
                            ]),
                            SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.restaurant,
                                  size: 18, color: Paleta.tolmun),
                              SizedBox(width: 6),
                              Text('Gostilna'),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Kartica izbranega revirja ali gostilne
                  if (_izbranRevir != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 28,
                      child: _KarticaRevirja(_izbranRevir!),
                    ),
                  if (_izbranaGostilna != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 28,
                      child: _KarticaGostilne(_izbranaGostilna!),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Okrogla oznaka na zemljevidu; izbrana je večja in ima belo obrobo.
class _Oznaka extends StatelessWidget {
  final Color barva;
  final IconData ikona;
  final bool izbrana;
  final VoidCallback onTap;
  final String opis;

  const _Oznaka({
    required this.barva,
    required this.ikona,
    required this.izbrana,
    required this.onTap,
    required this.opis,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: opis,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: izbrana ? 1.25 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              color: barva,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: izbrana ? 4 : 2),
              boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
            ),
            child: Icon(ikona, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _KarticaRevirja extends StatelessWidget {
  final Revir r;
  const _KarticaRevirja(this.r);

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RekaGlava(reka: r.reka, visina: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.ime, style: besedilo.titleMedium),
                Text('${r.ribiskaDruzina} · dnevna od ${formatCena(r.cenaDnevna)}',
                    style: besedilo.bodySmall),
                const SizedBox(height: 8),
                VremeKartica(lat: r.lat!, lng: r.lng!, kompaktna: true),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => RevirDetailScreen(revir: r)),
                  ),
                  child: const Text('Podrobnosti in nakup'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KarticaGostilne extends StatelessWidget {
  final Gostilna g;
  const _KarticaGostilne(this.g);

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.ime, style: besedilo.titleMedium),
            Text('${g.kraj} · ${g.odpreOb}:00–${g.zapreOb}:00',
                style: besedilo.bodySmall),
            const SizedBox(height: 4),
            Text('${g.ponudba} · ${formatCena(g.cenaPriprave)} na osebo'),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.event_available),
              label: const Text('Rezerviraj'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => RezervacijaScreen(gostilna: g)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
