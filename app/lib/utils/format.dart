import 'package:intl/intl.dart';

final _evri = NumberFormat.currency(locale: 'sl', symbol: '€');

/// 25 → "25,00 €"
String formatCena(num znesek) => _evri.format(znesek);
