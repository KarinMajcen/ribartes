import 'package:intl/intl.dart';

final _evri = NumberFormat.currency(locale: 'sl', symbol: '€');

/// 25 → "25,00 €"
String formatCena(num znesek) => _evri.format(znesek);

/// DateTime(2026, 11, 28) → "28. 11. 2026"
String formatDatum(DateTime d) => '${d.day}. ${d.month}. ${d.year}';
