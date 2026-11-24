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

  /// Trenutno stanje točk prijavljenega ribiča (v živo).
  Stream<int> mojeTocke() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('uporabniki').doc(uid).snapshots().map(
          (doc) => (doc.data()?['tocke'] as num?)?.toInt() ?? 0,
        );
  }

  /// US-05 (+ US-10): ustvari dovolilnico in vrne njen ID.
  ///
  /// Vse poteka v eni transakciji:
  /// - transakcija brez povezave NE uspe, zato ribič ne dobi neplačane dovolilnice;
  /// - točke se preberejo in odštejejo v isti transakciji, zato jih ni mogoče
  ///   porabiti dvakrat (npr. dva hkratna nakupa na dveh telefonih).
  Future<String> kupi({
    required Revir revir,
    required VrstaDovolilnice vrsta,
    required DateTime datum,
    bool unovciTocke = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw NakupNapaka('Za nakup se morate prijaviti.');

    final zdaj = DateTime.now();
    final danes = DateTime(zdaj.year, zdaj.month, zdaj.day);
    if (datum.isBefore(danes)) {
      throw NakupNapaka('Datum ne sme biti v preteklosti.');
    }

    final (veljaOd, veljaDo) = vrsta.veljavnost(datum);
    final polnaCena = vrsta.cena(revir);
    final ref = _zbirka.doc(); // nov dokument z naključnim ID-jem
    final uporabnikRef = _db.collection('uporabniki').doc(user.uid);

    try {
      await _db.runTransaction((tx) async {
        var popust = 0;

        if (unovciTocke) {
          // Točke preberemo znotraj transakcije – vedno najnovejše stanje.
          final uporabnik = await tx.get(uporabnikRef);
          final tocke = (uporabnik.data()?['tocke'] as num?)?.toInt() ?? 0;
          popust = Popust.izracunaj(tocke: tocke, cena: polnaCena);
          if (popust == 0) {
            throw NakupNapaka('Za popust potrebujete vsaj '
                '${Popust.tockNaEvro} točk.');
          }
          tx.update(uporabnikRef, {
            'tocke': FieldValue.increment(-popust * Popust.tockNaEvro),
          });
        }

        tx.set(ref, {
          'uid': user.uid,
          'imeRibica': user.displayName ?? user.email ?? '',
          'revirId': revir.id,
          'revirIme': revir.ime,
          'reka': revir.reka,
          'vrsta': vrsta.name,
          'veljaOd': Timestamp.fromDate(veljaOd),
          'veljaDo': Timestamp.fromDate(veljaDo),
          'polnaCena': polnaCena,
          'popust': popust,
          'porabljeneTocke': popust * Popust.tockNaEvro,
          'cena': polnaCena - popust,
          'ustvarjena': FieldValue.serverTimestamp(),
        });
      }).timeout(const Duration(seconds: 15));
      return ref.id;
    } on NakupNapaka {
      rethrow;
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

  /// US-11: čuvaj prebere dovolilnico. Bere vedno s strežnika (ne iz
  /// predpomnilnika), da vidi trenutno stanje. Brez povezave vrže napako.
  Future<Dovolilnica?> preberiZaPreverjanje(String id) async {
    final doc = await _zbirka
        .doc(id)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 10));
    return doc.exists ? Dovolilnica.izFirestore(doc) : null;
  }

  /// Ena dovolilnica po ID-ju (za zaslon s QR kodo).
  Stream<Dovolilnica?> dovolilnica(String id) {
    return _zbirka.doc(id).snapshots().map(
          (doc) => doc.exists ? Dovolilnica.izFirestore(doc) : null,
        );
  }
}
