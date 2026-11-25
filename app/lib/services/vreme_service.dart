import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vreme.dart';

/// Zunanji API Open-Meteo (https://open-meteo.com): trenutno vreme za
/// koordinate. Brezplačen za nekomercialno uporabo, brez API ključa.
class VremeService {
  static final _predpomnilnik = <String, (DateTime, Vreme)>{};
  static const _veljavnost = Duration(minutes: 15);

  /// Vrne vreme ali null, če ga ni mogoče pridobiti (ni povezave, napaka API-ja).
  /// Rezultat hrani 15 minut, da ob vsakem odprtju revirja ne kliče API-ja znova.
  Future<Vreme?> trenutno(double lat, double lng) async {
    final kljuc = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
    final shranjeno = _predpomnilnik[kljuc];
    if (shranjeno != null &&
        DateTime.now().difference(shranjeno.$1) < _veljavnost) {
      return shranjeno.$2;
    }

    final naslov = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lng',
      'current': 'temperature_2m,weather_code,wind_speed_10m',
      'daily': 'sunrise,sunset',
      'forecast_days': '1',
      'timezone': 'Europe/Ljubljana',
    });

    try {
      final odgovor =
          await http.get(naslov).timeout(const Duration(seconds: 8));
      if (odgovor.statusCode != 200) return null;
      final vreme =
          Vreme.izJson(jsonDecode(odgovor.body) as Map<String, dynamic>);
      _predpomnilnik[kljuc] = (DateTime.now(), vreme);
      return vreme;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null; // ni povezave ali nepričakovan odgovor
    }
  }
}
