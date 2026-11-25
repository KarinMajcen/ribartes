import 'package:material_ui/material_ui.dart';

import '../tema/tema.dart';

/// Enotno prazno stanje: ikona, naslov, kratka razlaga in (po želji) dejanje.
/// Prazen zaslon je povabilo k dejanju, ne le sporočilo, da ni ničesar.
class PraznoStanje extends StatelessWidget {
  final IconData ikona;
  final String naslov;
  final String? razlaga;
  final String? gumb;
  final VoidCallback? onGumb;

  const PraznoStanje({
    super.key,
    required this.ikona,
    required this.naslov,
    this.razlaga,
    this.gumb,
    this.onGumb,
  });

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;
    final besedilo = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Razmik.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: barve.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(ikona, size: 40, color: barve.primary),
            ),
            const SizedBox(height: Razmik.l),
            Text(naslov,
                textAlign: TextAlign.center, style: besedilo.titleLarge),
            if (razlaga != null) ...[
              const SizedBox(height: Razmik.s),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  razlaga!,
                  textAlign: TextAlign.center,
                  style: besedilo.bodyMedium
                      ?.copyWith(color: context.ribartes.nevtralno),
                ),
              ),
            ],
            if (gumb != null && onGumb != null) ...[
              const SizedBox(height: Razmik.xl),
              FilledButton(onPressed: onGumb, child: Text(gumb!)),
            ],
          ],
        ),
      ),
    );
  }
}
