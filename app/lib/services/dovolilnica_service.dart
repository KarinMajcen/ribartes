import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/dovolilnica.dart';
import '../models/revir.dart';

/// Napaka pri nakupu z že prevedenim sporočilom.
class NakupNapaka implements Exception {
  final String sporocilo;
  NakupNapaka(this.sporocilo);

  @override
  String toString() => sporocilo;
}

/// Repozitorij za dovolilnice.
class DovolilnicaService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _zbirka =>
      _db.collection('dovolilnice');

  static const _niPovezave =
      'Nakup ni uspel, ni povezave. Denar ni bil bremenjen.';

  /// US-05: ustvari dovolilnico in vrne njen ID.
  ///
  /// Zapis gre skozi transakcijo, ker transakcija brez povezave NE uspe.
  /// Navaden zapis bi Firestore brez povezave postavil v čakalno vrsto in ga
  /// poslal kasneje – ribič bi dobil dovolilnico, ne da bi vedel, ali je plačana.
  Future<String> kupi({
    required Revir revir,
    required VrstaDovolilnice vrsta,
    required DateTime datum,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw NakupNapaka('Za nakup se morate prijaviti.');

    final zdaj = DateTime.now();
    final danes = DateTime(zdaj.year, zdaj.month, zdaj.day);
    if (datum.isBefore(danes)) {
      throw NakupNapaka('Datum ne sme biti v preteklosti.');
    }

    final (veljaOd, veljaDo) = vrsta.veljavnost(datum);
    final ref = _zbirka.doc(); // nov dokument z naključnim ID-jem

    try {
      await _db.runTransaction((tx) async {
        tx.set(ref, {
          'uid': user.uid,
          'imeRibica': user.displayName ?? user.email ?? '',
          'revirId': revir.id,
          'revirIme': revir.ime,
          'reka': revir.reka,
          'vrsta': vrsta.name,
          'veljaOd': Timestamp.fromDate(veljaOd),
          'veljaDo': Timestamp.fromDate(veljaDo),
          'cena': vrsta.cena(revir),
          'ustvarjena': FieldValue.serverTimestamp(),
        });
      }).timeout(const Duration(seconds: 15));
      return ref.id;
    } on TimeoutException {
      throw NakupNapaka(_niPovezave);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') throw NakupNapaka(_niPovezave);
      throw NakupNapaka('Nakup ni uspel (${e.code}). Poskusite znova.');
    }
  }

  /// US-06: vse dovolilnice prijavljenega ribiča.
  /// Razvrščanje je na napravi, da Firestore ne potrebuje sestavljenega indeksa.
  Stream<List<Dovolilnica>> mojeDovolilnice() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _zbirka.where('uid', isEqualTo: uid).snapshots().map(
          (snap) => snap.docs.map(Dovolilnica.izFirestore).toList(),
        );
  }

  /// Ena dovolilnica po ID-ju (za zaslon s QR kodo).
  Stream<Dovolilnica?> dovolilnica(String id) {
    return _zbirka.doc(id).snapshots().map(
          (doc) => doc.exists ? Dovolilnica.izFirestore(doc) : null,
        );
  }
}
