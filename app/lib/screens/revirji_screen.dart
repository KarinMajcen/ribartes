import 'package:material_ui/material_ui.dart';

import '../models/revir.dart';
import '../services/revir_service.dart';
import '../utils/format.dart';
import 'revir_detail_screen.dart';

/// Zaslon "Revirji" – pokriva US-03.
class RevirjiScreen extends StatefulWidget {
  const RevirjiScreen({super.key});

  @override
  State<RevirjiScreen> createState() => _RevirjiScreenState();
}

class _RevirjiScreenState extends State<RevirjiScreen> {
  final _service = RevirService();
  late final Stream<List<Revir>> _tok = _service.vsiRevirji();
  String _iskanje = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revirji')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Išči po reki ali vrsti ribe',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _iskanje = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Revir>>(
              stream: _tok,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _Sporocilo(
                    'Revirjev ni bilo mogoče naložiti. Poskusite znova.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final revirji =
                    snapshot.data!.where((r) => r.ustreza(_iskanje)).toList();

                if (revirji.isEmpty) {
                  // Scenarij "ni zadetkov" iz US-03.
                  return const _Sporocilo(
                    'Ni revirjev, ki ustrezajo iskanju.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: revirji.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _RevirKartica(revirji[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RevirKartica extends StatelessWidget {
  final Revir revir;
  const _RevirKartica(this.revir);

  @override
  Widget build(BuildContext context) {
    final besedilo = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(child: Icon(Icons.water)),
        title: Text(revir.ime, style: besedilo.titleMedium),
        subtitle: Text(
          '${revir.reka} · ${revir.vrste.join(', ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatCena(revir.cenaDnevna), style: besedilo.titleSmall),
            Text('dnevna', style: besedilo.bodySmall),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RevirDetailScreen(revir: revir)),
        ),
      ),
    );
  }
}

class _Sporocilo extends StatelessWidget {
  final String besedilo;
  const _Sporocilo(this.besedilo);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(besedilo, textAlign: TextAlign.center),
      ),
    );
  }
}
