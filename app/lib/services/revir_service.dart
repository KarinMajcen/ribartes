import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/revir.dart';

/// Repozitorij za revirje: zasloni dobijo seznam objektov Revir,
/// ne da bi vedeli, da so podatki v Firestore.
class RevirService {
  final _zbirka = FirebaseFirestore.instance.collection('revirji');

  /// Tok vseh revirjev, urejenih po imenu. Firestore podatke shrani v
  /// predpomnilnik, zato se brez povezave prikažejo zadnji naloženi.
  Stream<List<Revir>> vsiRevirji() {
    return _zbirka.orderBy('ime').snapshots().map(
          (snap) => snap.docs.map(Revir.izFirestore).toList(),
        );
  }
}
