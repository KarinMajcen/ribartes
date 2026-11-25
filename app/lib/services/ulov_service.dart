import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/revir.dart';
import '../models/ulov.dart';
import '../models/vrsta_ribe.dart';

/// Kaj se je zgodilo ob shranjevanju ulova – zaslon na podlagi tega
/// prikaže sporočila iz scenarijev US-07, US-08 in US-09.
class RezultatShranjevanja {
  final bool novaKartica;
  final int prejeteTocke;

  /// false = ni povezave; ulov je shranjen na napravi in se pošlje kasneje.
  final bool poslano;

  const RezultatShranjevanja({
    required this.novaKartica,
    required this.prejeteTocke,
    required this.poslano,
  });
}

/// Repozitorij za ulove in vrste rib.
class UlovService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _ulovi => _db.collection('ulovi');

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// Vse vrste rib (kartice albuma), po abecedi.
  Stream<List<VrstaRibe>> vrsteRib() {
    return _db.collection('vrste_rib').orderBy('ime').snapshots().map(
          (s) => s.docs.map(VrstaRibe.izFirestore).toList(),
        );
  }

  /// Ulovi prijavljenega ribiča, najnovejši najprej.
  Stream<List<Ulov>> mojiUlovi() {
    return _ulovi.where('uid', isEqualTo: _uid).snapshots().map((s) {
      final seznam = s.docs.map(Ulov.izFirestore).toList();
      seznam.sort((a, b) => b.datum.compareTo(a.datum));
      return seznam;
    });
  }

  /// US-12: začetek tega tedna (ponedeljek ob 00:00, lokalni čas).
  static DateTime zacetekTedna([DateTime? zdaj]) {
    final z = zdaj ?? DateTime.now();
    return DateTime(z.year, z.month, z.day - (z.weekday - 1));
  }

  /// US-12: vsi ulovi vseh ribičev od začetka tedna.
  /// Poizvedba je samo po datumu (en sam indeks); filtriranje po reki in
  /// razvrščanje po dolžini sta na napravi, zato ni potreben sestavljen indeks.
  Stream<List<Ulov>> uloviTegaTedna() {
    return _ulovi
        .where('datum',
            isGreaterThanOrEqualTo: Timestamp.fromDate(zacetekTedna()))
        .snapshots()
        .map((s) => s.docs.map(Ulov.izFirestore).toList());
  }

  /// Izbriše ulov. Če je bila riba vrnjena v reko, se odštejejo tudi točke,
  /// ki jih je ribič zanjo prejel (sicer bi lahko točke "nabiral" z brisanjem).
  Future<void> izbrisi(Ulov ulov) async {
    final batch = _db.batch();
    batch.delete(_ulovi.doc(ulov.id));
    if (ulov.spuscena) {
      batch.set(
        _db.collection('uporabniki').doc(ulov.uid),
        {'tocke': FieldValue.increment(-Tocke.zaSpuscenoRibo)},
        SetOptions(merge: true),
      );
    }
    // Brez povezave se izbris izvede lokalno in pošlje kasneje.
    try {
      await batch.commit().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // ostane v čakalni vrsti Firestore
    }
    // Fotografijo pobrišemo z naprave.
    final pot = ulov.fotoPot;
    if (pot != null) {
      final datoteka = File(pot);
      if (await datoteka.exists()) await datoteka.delete();
    }
  }

  /// Fotografijo kopira v zasebno mapo aplikacije in vrne pot do nje.
  Future<String> shraniFotografijo(XFile foto) async {
    final mapa = await getApplicationDocumentsDirectory();
    final ulovi = Directory('${mapa.path}/ulovi');
    if (!await ulovi.exists()) await ulovi.create(recursive: true);
    final pot = '${ulovi.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(foto.path).copy(pot);
    return pot;
  }

  /// US-07 (+ US-08, US-09): shrani ulov in po potrebi doda točke.
  Future<RezultatShranjevanja> shrani({
    required VrstaRibe vrsta,
    Revir? revir,
    required double dolzinaCm,
    double? tezaKg,
    String? fotoPot,
    required bool spuscena,
  }) async {
    final uid = _uid;
    final user = FirebaseAuth.instance.currentUser!;

    // US-08: je to prvi ulov te vrste? Preverimo PRED zapisom.
    var novaKartica = false;
    try {
      final obstojeci = await _ulovi
          .where('uid', isEqualTo: uid)
          .where('vrstaId', isEqualTo: vrsta.id)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      novaKartica = obstojeci.docs.isEmpty;
    } catch (_) {
      // Brez povezave in brez podatkov v predpomnilniku – kartice ne oznanimo.
    }

    // Ulov in točke zapišemo v enem paketu (batch): uspe oboje ali nič.
    final batch = _db.batch();
    batch.set(_ulovi.doc(), {
      'uid': uid,
      'imeRibica': user.displayName ?? '',
      'vrstaId': vrsta.id,
      'vrstaIme': vrsta.ime,
      'revirId': revir?.id,
      'revirIme': revir?.ime,
      'reka': revir?.reka,
      'dolzinaCm': dolzinaCm,
      'tezaKg': tezaKg,
      'fotoPot': fotoPot,
      'spuscena': spuscena,
      // Čas naprave (ne strežnika), da ima ulov datum tudi brez povezave.
      'datum': Timestamp.now(),
    });
    if (spuscena) {
      batch.set(
        _db.collection('uporabniki').doc(uid),
        {'tocke': FieldValue.increment(Tocke.zaSpuscenoRibo)},
        SetOptions(merge: true),
      );
    }

    // Za razliko od nakupa je ulov dovoljeno shraniti brez povezave:
    // Firestore ga takoj zapiše na napravo in ga pošlje, ko je povezava.
    var poslano = true;
    try {
      await batch.commit().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      poslano = false;
    }

    return RezultatShranjevanja(
      novaKartica: novaKartica,
      prejeteTocke: spuscena ? Tocke.zaSpuscenoRibo : 0,
      poslano: poslano,
    );
  }
}
