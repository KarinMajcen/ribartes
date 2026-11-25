import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/koordinate.dart';

/// Model revirja – en dokument v zbirki "revirji".
class Revir {
  final String id;
  final String ime;
  final String reka;
  final String ribiskaDruzina;
  final String opis;
  final List<String> vrste;
  final List<String> pravila;
  final double cenaDnevna;
  final double cenaTedenska;
  final double cenaLetna;

  /// Lokacija revirja (za zemljevid in vreme). Null, če ni znana.
  final double? lat;
  final double? lng;

  const Revir({
    required this.id,
    required this.ime,
    required this.reka,
    required this.ribiskaDruzina,
    required this.opis,
    required this.vrste,
    required this.pravila,
    required this.cenaDnevna,
    required this.cenaTedenska,
    required this.cenaLetna,
    this.lat,
    this.lng,
  });

  /// Pretvori dokument iz Firestore v objekt Revir.
  factory Revir.izFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final cene = (d['cene'] as Map<String, dynamic>?) ?? {};
    return Revir(
      id: doc.id,
      ime: d['ime'] as String? ?? '',
      reka: d['reka'] as String? ?? '',
      ribiskaDruzina: d['ribiskaDruzina'] as String? ?? '',
      opis: d['opis'] as String? ?? '',
      vrste: List<String>.from(d['vrste'] as List? ?? const []),
      pravila: List<String>.from(d['pravila'] as List? ?? const []),
      cenaDnevna: (cene['dnevna'] as num?)?.toDouble() ?? 0,
      cenaTedenska: (cene['tedenska'] as num?)?.toDouble() ?? 0,
      cenaLetna: (cene['letna'] as num?)?.toDouble() ?? 0,
      // Koordinate iz baze; če jih ni, iz testnih podatkov v kodi.
      lat: (d['lat'] as num?)?.toDouble() ?? koordinateRevirjev[doc.id]?.$1,
      lng: (d['lng'] as num?)?.toDouble() ?? koordinateRevirjev[doc.id]?.$2,
    );
  }

  /// US-03: ali revir ustreza iskalnemu nizu (ime, reka ali vrsta ribe).
  bool ustreza(String iskanje) {
    final q = iskanje.trim().toLowerCase();
    if (q.isEmpty) return true;
    return ime.toLowerCase().contains(q) ||
        reka.toLowerCase().contains(q) ||
        vrste.any((v) => v.toLowerCase().contains(q));
  }
}
