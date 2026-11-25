import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'data/testni_podatki.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'tema/tema.dart';

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
      // Sistem oblikovanja "Bistra voda" – glej lib/tema/tema.dart
      theme: ribartesTema(Brightness.light),
      darkTheme: ribartesTema(Brightness.dark),
      themeMode: ThemeMode.system, // sledi nastavitvi telefona
      home: const AuthGate(),
    );
  }
}
