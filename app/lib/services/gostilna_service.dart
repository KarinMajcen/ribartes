import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/gostilna.dart';
import '../models/ulov.dart';

/// Napaka pri rezervaciji z že prevedenim sporočilom.
class RezervacijaNapaka implements Exception {
  final String sporocilo;
  RezervacijaNapaka(this.sporocilo);

  @override
  String toString() => sporocilo;
}

/// Repozitorij za gostilne in rezervacije (US-13).
class GostilnaService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _rezervacije =>
      _db.collection('rezervacije');

  static const _niPovezave =
      'Rezervacija ni uspela, ni povezave. Poskusi znova.';

  Stream<List<Gostilna>> gostilne() {
    return _db.collection('gostilne').orderBy('ime').snapshots().map(
          (s) => s.docs.map(Gostilna.izFirestore).toList(),
        );
  }

  /// Rezervacije prijavljenega ribiča, najbližji termin najprej.
  Stream<List<Rezervacija>> mojeRezervacije() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _rezervacije.where('uid', isEqualTo: uid).snapshots().map((s) {
      final seznam = s.docs.map(Rezervacija.izFirestore).toList();
      seznam.sort((a, b) => a.termin.compareTo(b.termin));
      return seznam;
    });
  }

  /// Ustvari rezervacijo. Kot pri nakupu gre skozi transakcijo, ki brez
  /// povezave ne uspe – ribič mora vedeti, ali ga gostilna res pričakuje.
  Future<void> rezerviraj({
    required Gostilna gostilna,
    required DateTime termin,
    required int steviloOseb,
    Ulov? ulov,
    String opomba = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw RezervacijaNapaka('Za rezervacijo se prijavi.');
    if (!termin.isAfter(DateTime.now())) {
      throw RezervacijaNapaka('Termin je že minil. Izberi drugo uro.');
    }

    final ref = _rezervacije.doc();
    try {
      await _db.runTransaction((tx) async {
        tx.set(ref, {
          'uid': user.uid,
          'imeRibica': user.displayName ?? '',
          'gostilnaId': gostilna.id,
          'gostilnaIme': gostilna.ime,
          'kraj': gostilna.kraj,
          'termin': Timestamp.fromDate(termin),
          'steviloOseb': steviloOseb,
          'ulovId': ulov?.id,
          'ulovOpis': ulov == null
              ? null
              : '${ulov.vrstaIme}, ${ulov.dolzinaCm.toStringAsFixed(0)} cm',
          'opomba': opomba.trim(),
          'cena': gostilna.cenaPriprave * steviloOseb,
          'stanje': StanjeRezervacije.potrjena.name,
          'ustvarjena': FieldValue.serverTimestamp(),
        });
      }).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw RezervacijaNapaka(_niPovezave);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') throw RezervacijaNapaka(_niPovezave);
      throw RezervacijaNapaka('Rezervacija ni uspela (${e.code}).');
    }
  }

  /// Preklic: rezervacija ostane v zgodovini s stanjem "preklicana".
  Future<void> preklici(String id) async {
    try {
      await _db.runTransaction((tx) async {
        tx.update(_rezervacije.doc(id),
            {'stanje': StanjeRezervacije.preklicana.name});
      }).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw RezervacijaNapaka('Preklic ni uspel, ni povezave.');
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        throw RezervacijaNapaka('Preklic ni uspel, ni povezave.');
      }
      throw RezervacijaNapaka('Preklic ni uspel (${e.code}).');
    }
  }
}
