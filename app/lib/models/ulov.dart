import 'package:cloud_firestore/cloud_firestore.dart';

/// Točkovanje programa ujemi in spusti (US-09, specifikacija 8.4).
class Tocke {
  static const int zaSpuscenoRibo = 10;
}

/// Ulov – en dokument v zbirki "ulovi".
class Ulov {
  final String id;
  final String uid;
  final String vrstaId;
  final String vrstaIme;
  final String? revirId;
  final String? revirIme;
  final String? reka;
  final double dolzinaCm;
  final double? tezaKg;

  /// Pot do fotografije na napravi (fotografija se ne pošilja v oblak).
  final String? fotoPot;
  final bool spuscena;
  final DateTime datum;

  const Ulov({
    required this.id,
    required this.uid,
    required this.vrstaId,
    required this.vrstaIme,
    this.revirId,
    this.revirIme,
    this.reka,
    required this.dolzinaCm,
    this.tezaKg,
    this.fotoPot,
    required this.spuscena,
    required this.datum,
  });

  factory Ulov.izFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Ulov(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      vrstaId: d['vrstaId'] as String? ?? '',
      vrstaIme: d['vrstaIme'] as String? ?? '',
      revirId: d['revirId'] as String?,
      revirIme: d['revirIme'] as String?,
      reka: d['reka'] as String?,
      dolzinaCm: (d['dolzinaCm'] as num?)?.toDouble() ?? 0,
      tezaKg: (d['tezaKg'] as num?)?.toDouble(),
      fotoPot: d['fotoPot'] as String?,
      spuscena: d['spuscena'] as bool? ?? false,
      datum: (d['datum'] as Timestamp?)?.toDate() ?? DateTime(2000),
    );
  }
}
