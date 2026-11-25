import 'package:cloud_firestore/cloud_firestore.dart';

/// Vrsta ribe – en dokument v zbirki "vrste_rib" (ena kartica v ribjem albumu).
class VrstaRibe {
  final String id;
  final String ime;
  final String latinsko;

  const VrstaRibe({required this.id, required this.ime, required this.latinsko});

  /// Redke (zaščitene ali težko ulovljive) vrste – v albumu zlate kartice.
  static const redkeVrste = {
    'soska-postrv',
    'sulec',
    'jezerska-zlatovcica',
    'som',
  };

  bool get redka => redkeVrste.contains(id);

  factory VrstaRibe.izFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return VrstaRibe(
      id: doc.id,
      ime: d['ime'] as String? ?? '',
      latinsko: d['latinsko'] as String? ?? '',
    );
  }
}
