import 'package:material_ui/material_ui.dart';

import '../models/vreme.dart';
import '../services/vreme_service.dart';

/// Kartica s trenutnim vremenom ob revirju in ribolovno napovedjo.
class VremeKartica extends StatefulWidget {
  final double lat;
  final double lng;
  final bool kompaktna;

  const VremeKartica({
    super.key,
    required this.lat,
    required this.lng,
    this.kompaktna = false,
  });

  @override
  State<VremeKartica> createState() => _VremeKarticaState();
}

class _VremeKarticaState extends State<VremeKartica> {
  late Future<Vreme?> _vreme = VremeService().trenutno(widget.lat, widget.lng);

  @override
  void didUpdateWidget(VremeKartica star) {
    super.didUpdateWidget(star);
    if (star.lat != widget.lat || star.lng != widget.lng) {
      _vreme = VremeService().trenutno(widget.lat, widget.lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;

    return FutureBuilder<Vreme?>(
      future: _vreme,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Nalagam vreme …'),
              ]),
            ),
          );
        }
        final v = snap.data;
        if (v == null) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.cloud_off),
              title: Text('Vreme trenutno ni na voljo'),
              subtitle: Text('Preveri internetno povezavo.'),
            ),
          );
        }

        final (ikona, opis) = v.opis;
        final trnki = List.generate(
          5,
          (i) => Opacity(
            opacity: i < v.ribolovniIndeks ? 1 : 0.2,
            child: const Text('🎣', style: TextStyle(fontSize: 18)),
          ),
        );

        if (widget.kompaktna) {
          return Row(
            children: [
              Text(ikona, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Text('${v.temperatura.round()} °C · $opis'),
              const Spacer(),
              ...trnki,
            ],
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ikona, style: const TextStyle(fontSize: 44)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${v.temperatura.round()} °C · $opis',
                              style: besedilo.titleLarge),
                          Text('Veter ${v.veter.round()} km/h',
                              style: besedilo.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Ribolovna napoved', style: besedilo.titleSmall),
                const SizedBox(height: 4),
                Row(children: [
                  ...trnki,
                  const SizedBox(width: 8),
                  Expanded(child: Text(v.opisIndeksa)),
                ]),
                const SizedBox(height: 8),
                Text('Vir: Open-Meteo.com', style: besedilo.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}
