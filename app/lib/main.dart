import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'data/testni_podatki.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

void main() async {
  // Pripravi Flutter, preden zaženemo karkoli asinhronega.
  WidgetsFlutterBinding.ensureInitialized();

  // Poveže aplikacijo s Firebase projektom (nastavitve iz flutterfire configure).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Samo med razvojem: če baza nima revirjev, vnese testne podatke.
  if (kDebugMode) {
    try {
      await TestniPodatki.vnesiCeJePrazno();
    } catch (e) {
      debugPrint('Testnih podatkov ni bilo mogoče vnesti: $e');
    }
  }

  runApp(const RibartesApp());
}

class RibartesApp extends StatelessWidget {
  const RibartesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIBARTes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Celotna barvna shema aplikacije izhaja iz ene barve (rečno modra).
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6E8C)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      // AuthGate odloči: prijavljen → Domači zaslon, sicer → Prijava.
      home: const AuthGate(),
    );
  }
}
