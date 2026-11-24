import 'package:cloud_firestore/cloud_firestore.dart';

import 'revir.dart';

/// Vrsta dovolilnice in pravilo, kako dolgo velja.
enum VrstaDovolilnice {
  dnevna('Dnevna'),
  tedenska('Tedenska'),
  letna('Letna');

  const VrstaDovolilnice(this.naziv);
  final String naziv;

  /// Cena te vrste dovolilnice za izbrani revir.
  double cena(Revir revir) {
    switch (this) {
      case VrstaDovolilnice.dnevna:
        return revir.cenaDnevna;
      case VrstaDovolilnice.tedenska:
        return revir.cenaTedenska;
      case VrstaDovolilnice.letna:
        return revir.cenaLetna;
    }
  }

  /// Pravilo veljavnosti (glej specifikacijo, 8.4):
  /// - dnevna:   izbrani dan od 00:00:00 do 23:59:59
  /// - tedenska: 7 dni, od izbranega dne 00:00:00 do 6. dne pozneje 23:59:59
  /// - letna:    od izbranega dne do 31. 12. istega leta 23:59:59
  (DateTime, DateTime) veljavnost(DateTime datum) {
    final od = DateTime(datum.year, datum.month, datum.day);
    switch (this) {
      case VrstaDovolilnice.dnevna:
        return (od, DateTime(od.year, od.month, od.day, 23, 59, 59));
      case VrstaDovolilnice.tedenska:
        // DateTime sam pretvori npr. 34. november v 4. december.
        return (od, DateTime(od.year, od.month, od.day + 6, 23, 59, 59));
      case VrstaDovolilnice.letna:
        return (od, DateTime(od.year, 12, 31, 23, 59, 59));
    }
  }

  static VrstaDovolilnice izNiza(String? niz) => VrstaDovolilnice.values
      .firstWhere((v) => v.name == niz, orElse: () => VrstaDovolilnice.dnevna);
}

/// Stanje dovolilnice glede na trenutni čas (diagram stanj v 8.3).
enum StanjeDovolilnice {
  seNeVelja('Še ne velja'),
  veljavna('Veljavna'),
  potekla('Potekla');

  const StanjeDovolilnice(this.naziv);
  final String naziv;
}

/// Pravilo popusta s točkami (US-10, specifikacija 8.6):
/// popust P = min(⌊T / 100⌋, ⌊C / 2⌋) evrov, porabljene točke = P × 100.
class Popust {
  static const int tockNaEvro = 100;

  /// Vrne popust v celih evrih (0, če popusta ni).
  static int izracunaj({required int tocke, required double cena}) {
    final poTockah = tocke ~/ tockNaEvro;
    final najvec = (cena / 2).floor(); // popust ne preseže polovice cene
    return poTockah < najvec ? poTockah : najvec;
  }
}

/// Model dovolilnice – en dokument v zbirki "dovolilnice".
class Dovolilnica {
  final String id;
  final String uid;
  final String imeRibica;
  final String revirId;
  final String revirIme;
  final String reka;
  final VrstaDovolilnice vrsta;
  final DateTime veljaOd;
  final DateTime veljaDo;
  /// Plačani znesek (po popustu).
  final double cena;

  /// Popust v evrih in porabljene točke (0, če točke niso bile unovčene).
  final int popust;
  final int porabljeneTocke;

  const Dovolilnica({
    required this.id,
    required this.uid,
    required this.imeRibica,
    required this.revirId,
    required this.revirIme,
    required this.reka,
    required this.vrsta,
    required this.veljaOd,
    required this.veljaDo,
    required this.cena,
    this.popust = 0,
    this.porabljeneTocke = 0,
  });

  factory Dovolilnica.izFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Dovolilnica(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      imeRibica: d['imeRibica'] as String? ?? '',
      revirId: d['revirId'] as String? ?? '',
      revirIme: d['revirIme'] as String? ?? '',
      reka: d['reka'] as String? ?? '',
      vrsta: VrstaDovolilnice.izNiza(d['vrsta'] as String?),
      veljaOd: (d['veljaOd'] as Timestamp?)?.toDate() ?? DateTime(2000),
      veljaDo: (d['veljaDo'] as Timestamp?)?.toDate() ?? DateTime(2000),
      cena: (d['cena'] as num?)?.toDouble() ?? 0,
      popust: (d['popust'] as num?)?.toInt() ?? 0,
      porabljeneTocke: (d['porabljeneTocke'] as num?)?.toInt() ?? 0,
    );
  }

  /// Besedilo v QR kodi. Predpona omogoči čuvaju (US-11), da prepozna
  /// kodo RIBARTes in zavrne druge QR kode.
  String get qrVsebina => '$qrPredpona$id';

  static const qrPredpona = 'RIBARTES:';

  /// US-11: iz vsebine QR kode (ali ročno vpisane številke) vrne ID dovolilnice.
  /// Vrne null, če koda ni dovolilnica RIBARTes ("Neznana koda").
  static String? idIzQr(String vsebina) {
    var v = vsebina.trim();
    if (v.toUpperCase().startsWith(qrPredpona)) {
      v = v.substring(qrPredpona.length);
    }
    // ID-ji Firestore so iz črk in številk; vse drugo zavrnemo
    // (npr. spletni naslov ali poševnica, ki bi pokvarila poizvedbo).
    return RegExp(r'^[A-Za-z0-9]{10,40}$').hasMatch(v) ? v : null;
  }

  StanjeDovolilnice stanjeOb(DateTime cas) {
    if (cas.isBefore(veljaOd)) return StanjeDovolilnice.seNeVelja;
    if (cas.isAfter(veljaDo)) return StanjeDovolilnice.potekla;
    return StanjeDovolilnice.veljavna;
  }

  StanjeDovolilnice get stanje => stanjeOb(DateTime.now());
}
