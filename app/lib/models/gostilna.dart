import 'package:cloud_firestore/cloud_firestore.dart';

/// Partnerska gostilna – en dokument v zbirki "gostilne".
class Gostilna {
  final String id;
  final String ime;
  final String kraj;
  final String reka;
  final String? revirId;
  final String opis;
  final String ponudba;

  /// Cena priprave ulova s prilogo, na osebo, v evrih.
  final double cenaPriprave;

  /// Delovni čas v celih urah (npr. 11 in 21 = od 11:00 do 21:00).
  final int odpreOb;
  final int zapreOb;

  const Gostilna({
    required this.id,
    required this.ime,
    required this.kraj,
    required this.reka,
    this.revirId,
    required this.opis,
    required this.ponudba,
    required this.cenaPriprave,
    required this.odpreOb,
    required this.zapreOb,
  });

  factory Gostilna.izFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Gostilna(
      id: doc.id,
      ime: d['ime'] as String? ?? '',
      kraj: d['kraj'] as String? ?? '',
      reka: d['reka'] as String? ?? '',
      revirId: d['revirId'] as String?,
      opis: d['opis'] as String? ?? '',
      ponudba: d['ponudba'] as String? ?? '',
      cenaPriprave: (d['cenaPriprave'] as num?)?.toDouble() ?? 0,
      odpreOb: (d['odpreOb'] as num?)?.toInt() ?? 11,
      zapreOb: (d['zapreOb'] as num?)?.toInt() ?? 21,
    );
  }

  /// Termini za izbrani dan: na pol ure, od odprtja do ene ure pred zaprtjem
  /// (npr. 11:00, 11:30 … 20:00 pri delovnem času 11–21).
  /// Termini, ki so manj kot 30 minut od zdaj, so izpuščeni.
  List<DateTime> prostiTermini(DateTime dan, {DateTime? zdaj}) {
    final najprej = (zdaj ?? DateTime.now()).add(const Duration(minutes: 30));
    final zadnji = DateTime(dan.year, dan.month, dan.day, zapreOb - 1);
    final termini = <DateTime>[];
    var t = DateTime(dan.year, dan.month, dan.day, odpreOb);
    while (!t.isAfter(zadnji)) {
      if (t.isAfter(najprej)) termini.add(t);
      t = DateTime(t.year, t.month, t.day, t.hour, t.minute + 30);
    }
    return termini;
  }
}

/// Stanje rezervacije.
enum StanjeRezervacije {
  potrjena('Potrjena'),
  preklicana('Preklicana');

  const StanjeRezervacije(this.naziv);
  final String naziv;
}

/// Rezervacija priprave ulova – en dokument v zbirki "rezervacije".
class Rezervacija {
  final String id;
  final String uid;
  final String gostilnaId;
  final String gostilnaIme;
  final String kraj;
  final DateTime termin;
  final int steviloOseb;
  final String? ulovOpis;
  final String opomba;
  final double cena;
  final StanjeRezervacije stanje;

  const Rezervacija({
    required this.id,
    required this.uid,
    required this.gostilnaId,
    required this.gostilnaIme,
    required this.kraj,
    required this.termin,
    required this.steviloOseb,
    this.ulovOpis,
    required this.opomba,
    required this.cena,
    required this.stanje,
  });

  factory Rezervacija.izFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Rezervacija(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      gostilnaId: d['gostilnaId'] as String? ?? '',
      gostilnaIme: d['gostilnaIme'] as String? ?? '',
      kraj: d['kraj'] as String? ?? '',
      termin: (d['termin'] as Timestamp?)?.toDate() ?? DateTime(2000),
      steviloOseb: (d['steviloOseb'] as num?)?.toInt() ?? 1,
      ulovOpis: d['ulovOpis'] as String?,
      opomba: d['opomba'] as String? ?? '',
      cena: (d['cena'] as num?)?.toDouble() ?? 0,
      stanje: d['stanje'] == 'preklicana'
          ? StanjeRezervacije.preklicana
          : StanjeRezervacije.potrjena,
    );
  }

  /// Prihodnja, nepreklicana rezervacija – samo tako je mogoče preklicati.
  bool get aktivna =>
      stanje == StanjeRezervacije.potrjena && termin.isAfter(DateTime.now());
}
