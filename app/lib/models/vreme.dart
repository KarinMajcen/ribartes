/// Trenutno vreme ob revirju (iz API-ja Open-Meteo) in ribolovna napoved.
class Vreme {
  final double temperatura; // °C
  final int koda; // WMO koda vremena
  final double veter; // km/h
  final DateTime cas;

  const Vreme({
    required this.temperatura,
    required this.koda,
    required this.veter,
    required this.cas,
  });

  /// Iz JSON odgovora: {"current": {"time": ..., "temperature_2m": ..., ...}}
  factory Vreme.izJson(Map<String, dynamic> json) {
    final c = json['current'] as Map<String, dynamic>;
    return Vreme(
      temperatura: (c['temperature_2m'] as num).toDouble(),
      koda: (c['weather_code'] as num).toInt(),
      veter: (c['wind_speed_10m'] as num).toDouble(),
      cas: DateTime.tryParse(c['time'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// WMO koda → ikona in opis v slovenščini.
  (String, String) get opis {
    if (koda == 0) return ('☀️', 'Jasno');
    if (koda <= 2) return ('⛅', 'Delno oblačno');
    if (koda == 3) return ('☁️', 'Oblačno');
    if (koda == 45 || koda == 48) return ('🌫️', 'Megla');
    if (koda >= 51 && koda <= 57) return ('🌦️', 'Pršenje');
    if (koda >= 61 && koda <= 67) return ('🌧️', 'Dež');
    if (koda >= 71 && koda <= 77) return ('🌨️', 'Sneg');
    if (koda >= 80 && koda <= 82) return ('🌦️', 'Plohe');
    if (koda == 85 || koda == 86) return ('🌨️', 'Snežne plohe');
    if (koda >= 95) return ('⛈️', 'Nevihta');
    return ('🌡️', 'Neznano');
  }

  /// Ribolovna napoved 1–5 (specifikacija, algoritem "ribolovni indeks").
  /// Ribiška modrost: ribe bolje prijemajo ob oblačnem vremenu in rahlem
  /// dežju, slabše ob močnem soncu, mrazu, močnem vetru in nevihti.
  int get ribolovniIndeks {
    var ocena = 3;
    if (koda == 2 || koda == 3) ocena += 1; // oblačno
    if ((koda >= 51 && koda <= 61) || koda == 80) ocena += 1; // rahel dež
    if ((koda >= 63 && koda <= 67) || koda == 81 || koda == 82) ocena -= 1;
    if (koda >= 95) ocena -= 2; // nevihta – nevarno ob vodi
    if (koda <= 1 && temperatura > 25) ocena -= 1; // vroče sonce
    if (temperatura < 2) ocena -= 1; // mraz
    if (veter > 30) ocena -= 1; // močan veter
    return ocena.clamp(1, 5);
  }

  String get opisIndeksa => const [
        'Slabo – ostani doma',
        'Bolj tako',
        'Solidno',
        'Dobro',
        'Odlično – hitro k vodi!',
      ][ribolovniIndeks - 1];
}
