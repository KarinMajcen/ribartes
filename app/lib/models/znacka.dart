import 'package:material_ui/material_ui.dart';

import 'ulov.dart';

/// Značka (dosežek) v profilu ribiča. Izračuna se iz ulovov, ne shranjuje se.
class Znacka {
  final String ime;
  final String opis;
  final IconData ikona;
  final bool odklenjena;

  const Znacka({
    required this.ime,
    required this.opis,
    required this.ikona,
    required this.odklenjena,
  });

  /// Pravila za vse značke (specifikacija, algoritem "značke").
  static List<Znacka> izracunaj(List<Ulov> ulovi, {required int vsehVrst}) {
    final vrste = ulovi.map((u) => u.vrstaId).toSet().length;
    final revirji =
        ulovi.where((u) => u.revirId != null).map((u) => u.revirId).toSet().length;
    final spuscenih = ulovi.where((u) => u.spuscena).length;
    final najdaljsi = ulovi.isEmpty
        ? 0.0
        : ulovi.map((u) => u.dolzinaCm).reduce((a, b) => a > b ? a : b);
    final zgodnji = ulovi.any((u) => u.datum.hour < 7);

    return [
      Znacka(
        ime: 'Prvi ulov',
        opis: 'Vpiši svoj prvi ulov.',
        ikona: Icons.phishing,
        odklenjena: ulovi.isNotEmpty,
      ),
      Znacka(
        ime: 'Varuh reke',
        opis: 'Vrni v reko 5 rib.',
        ikona: Icons.eco,
        odklenjena: spuscenih >= 5,
      ),
      Znacka(
        ime: 'Popotnik',
        opis: 'Lovi na 3 različnih revirjih.',
        ikona: Icons.map,
        odklenjena: revirji >= 3,
      ),
      Znacka(
        ime: 'Zbiratelj',
        opis: 'Odkleni 5 kartic v albumu.',
        ikona: Icons.collections_bookmark,
        odklenjena: vrste >= 5,
      ),
      Znacka(
        ime: 'Mojster albuma',
        opis: 'Odkleni vse kartice v albumu.',
        ikona: Icons.workspace_premium,
        odklenjena: vsehVrst > 0 && vrste >= vsehVrst,
      ),
      Znacka(
        ime: 'Velikan',
        opis: 'Ujemi ribo, dolgo vsaj 60 cm.',
        ikona: Icons.straighten,
        odklenjena: najdaljsi >= 60,
      ),
      Znacka(
        ime: 'Zgodnja ptica',
        opis: 'Vpiši ulov pred 7. uro zjutraj.',
        ikona: Icons.wb_twilight,
        odklenjena: zgodnji,
      ),
    ];
  }
}
