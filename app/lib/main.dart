import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
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

/// Rečno modra – iz nje Material 3 izpelje celotno barvno shemo.
const _osnovnaBarva = Color(0xFF1B6E8C);

ThemeData _tema(Brightness svetlost) {
  final barve = ColorScheme.fromSeed(
    seedColor: _osnovnaBarva,
    brightness: svetlost,
  );
  final zaobljeno12 = BorderRadius.circular(12);

  return ThemeData(
    colorScheme: barve,
    scaffoldBackgroundColor: barve.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: barve.surface,
      foregroundColor: barve.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 2,
      titleTextStyle: TextStyle(
        color: barve.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: barve.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: barve.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: barve.surfaceContainerHighest.withValues(alpha: 0.4),
      border: OutlineInputBorder(borderRadius: zaobljeno12),
      enabledBorder: OutlineInputBorder(
        borderRadius: zaobljeno12,
        borderSide: BorderSide(color: barve.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: zaobljeno12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: zaobljeno12),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: barve.surfaceContainer,
      indicatorColor: barve.primaryContainer,
    ),
  );
}

class RibartesApp extends StatelessWidget {
  const RibartesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIBARTes',
      debugShowCheckedModeBanner: false,
      theme: _tema(Brightness.light),
      darkTheme: _tema(Brightness.dark),
      themeMode: ThemeMode.system, // sledi nastavitvi telefona (svetlo/temno)

      // Slovenščina za sistemske elemente (koledar, "V redu", "Prekliči" …).
      

      // AuthGate odloči: prijavljen → aplikacija, sicer → Prijava.
      home: const AuthGate(),
    );
  }
}
