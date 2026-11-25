import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Sistem oblikovanja RIBARTes – "Bistra voda"
///
/// Barve izhajajo iz alpske reke: smaragdna Soča, globok tolmun, svetel
/// rečni prod, mah na kamnih in pisana muharska muha. Jantarna "muha" je
/// rezervirana za nagrade (točke, redke kartice, zlata ura, zmagovalni oder),
/// zato ima v vmesniku vedno isti pomen.
/// ─────────────────────────────────────────────────────────────────────────
class Paleta {
  static const soca = Color(0xFF0E7C6B); // glavna barva
  static const socaSvetla = Color(0xFF2BB5A0);
  static const tolmun = Color(0xFF0D3B36); // naslovi, temne površine
  static const prod = Color(0xFFEFF3F1); // ozadje (svetla tema)
  static const kamen = Color(0xFFFFFFFF); // kartice
  static const kamenRob = Color(0xFFD9E2DE); // tanki robovi
  static const mah = Color(0xFF5C7A3A); // narava, ujemi in spusti
  static const muha = Color(0xFFE8A33D); // nagrade
  static const muhaOzadje = Color(0xFFFFF3DC);
  static const muhaTemna = Color(0xFF8A5A00);

  // Statusi – povsod enaki (dovolilnica, čuvaj, opozorila).
  static const uspeh = Color(0xFF1E8E5A);
  static const opozorilo = Color(0xFFC98200);
  static const napaka = Color(0xFFC8432B);
  static const nevtralno = Color(0xFF6B7A76);

  // Temna tema
  static const nocOzadje = Color(0xFF0B1F1C);
  static const nocPovrsina = Color(0xFF12302B);
  static const nocRob = Color(0xFF24443E);
}

/// Razmiki (večkratniki 4) – uporabljaj te namesto poljubnih številk.
class Razmik {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Zaobljenosti – večji element, večji polmer (kot rečni kamni).
class Zaobljenost {
  static const glava = 28.0;
  static const kartica = 20.0;
  static const gumb = 14.0;
  static const majhna = 10.0;
}

/// Pomenske barve, ki jih Material nima (dostop: `context.ribartes`).
@immutable
class RibartesBarve extends ThemeExtension<RibartesBarve> {
  final Color uspeh;
  final Color opozorilo;
  final Color napaka;
  final Color nevtralno;
  final Color nagrada; // muha
  final Color nagradaOzadje;
  final Color nagradaBesedilo;
  final Color narava; // mah
  final Color rob;

  const RibartesBarve({
    required this.uspeh,
    required this.opozorilo,
    required this.napaka,
    required this.nevtralno,
    required this.nagrada,
    required this.nagradaOzadje,
    required this.nagradaBesedilo,
    required this.narava,
    required this.rob,
  });

  static const svetla = RibartesBarve(
    uspeh: Paleta.uspeh,
    opozorilo: Paleta.opozorilo,
    napaka: Paleta.napaka,
    nevtralno: Paleta.nevtralno,
    nagrada: Paleta.muha,
    nagradaOzadje: Paleta.muhaOzadje,
    nagradaBesedilo: Paleta.muhaTemna,
    narava: Paleta.mah,
    rob: Paleta.kamenRob,
  );

  static const temna = RibartesBarve(
    uspeh: Color(0xFF3DBF82),
    opozorilo: Color(0xFFE8B13D),
    napaka: Color(0xFFE76F55),
    nevtralno: Color(0xFF9AAAA5),
    nagrada: Paleta.muha,
    nagradaOzadje: Color(0xFF3A2C12),
    nagradaBesedilo: Color(0xFFFFD48A),
    narava: Color(0xFF9CC26A),
    rob: Paleta.nocRob,
  );

  @override
  RibartesBarve copyWith() => this;

  @override
  RibartesBarve lerp(RibartesBarve? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return RibartesBarve(
      uspeh: l(uspeh, other.uspeh),
      opozorilo: l(opozorilo, other.opozorilo),
      napaka: l(napaka, other.napaka),
      nevtralno: l(nevtralno, other.nevtralno),
      nagrada: l(nagrada, other.nagrada),
      nagradaOzadje: l(nagradaOzadje, other.nagradaOzadje),
      nagradaBesedilo: l(nagradaBesedilo, other.nagradaBesedilo),
      narava: l(narava, other.narava),
      rob: l(rob, other.rob),
    );
  }
}

extension RibartesTemaKontekst on BuildContext {
  RibartesBarve get ribartes =>
      Theme.of(this).extension<RibartesBarve>() ?? RibartesBarve.svetla;
}

/// Pisava iz Google Fonts; če je ni mogoče naložiti, ostane privzeta.
String? _pisava(String ime) {
  try {
    return GoogleFonts.getFont(ime).fontFamily;
  } catch (_) {
    return null;
  }
}

TextTheme _besedila(Color glavna, Color blaga) {
  final naslovi = _pisava('Bricolage Grotesque');
  final besedilo = _pisava('Figtree');
  TextStyle s(String? pisava, double velikost, FontWeight debelina,
          {double visina = 1.3, double razmik = 0, Color? barva}) =>
      TextStyle(
        fontFamily: pisava,
        fontSize: velikost,
        fontWeight: debelina,
        height: visina,
        letterSpacing: razmik,
        color: barva ?? glavna,
      );

  // Lestvica velikosti ~1,2 (34 · 28 · 24 · 20 · 16 · 14 · 12)
  return TextTheme(
    displaySmall: s(naslovi, 34, FontWeight.w800, visina: 1.1, razmik: -0.6),
    headlineMedium: s(naslovi, 28, FontWeight.w800, visina: 1.15, razmik: -0.4),
    headlineSmall: s(naslovi, 24, FontWeight.w700, visina: 1.2, razmik: -0.2),
    titleLarge: s(naslovi, 20, FontWeight.w700, visina: 1.25),
    titleMedium: s(besedilo, 16, FontWeight.w700),
    titleSmall: s(besedilo, 14, FontWeight.w700),
    bodyLarge: s(besedilo, 16, FontWeight.w400, visina: 1.5),
    bodyMedium: s(besedilo, 14.5, FontWeight.w400, visina: 1.45),
    bodySmall: s(besedilo, 12.5, FontWeight.w500, visina: 1.4, barva: blaga),
    labelLarge: s(besedilo, 15, FontWeight.w700),
    labelMedium: s(besedilo, 13, FontWeight.w600),
    labelSmall: s(besedilo, 11.5, FontWeight.w600, barva: blaga),
  );
}

/// Celotna tema aplikacije za svetel ali temen način.
ThemeData ribartesTema(Brightness svetlost) {
  final temna = svetlost == Brightness.dark;

  final barve = ColorScheme.fromSeed(
    seedColor: Paleta.soca,
    brightness: svetlost,
  ).copyWith(
    primary: temna ? Paleta.socaSvetla : Paleta.soca,
    onPrimary: temna ? Paleta.tolmun : Colors.white,
    secondary: temna ? const Color(0xFF9CC26A) : Paleta.mah,
    tertiary: Paleta.muha,
    surface: temna ? Paleta.nocOzadje : Paleta.prod,
    onSurface: temna ? const Color(0xFFE4EEEA) : Paleta.tolmun,
    surfaceContainerLowest: temna ? Paleta.nocOzadje : Paleta.kamen,
    surfaceContainerLow: temna ? Paleta.nocPovrsina : Paleta.kamen,
    outlineVariant: temna ? Paleta.nocRob : Paleta.kamenRob,
    error: temna ? const Color(0xFFE76F55) : Paleta.napaka,
  );

  final besedila = _besedila(
    barve.onSurface,
    temna ? const Color(0xFF9AAAA5) : Paleta.nevtralno,
  );
  final gumbOblika = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Zaobljenost.gumb));
  final rob = BorderSide(color: barve.outlineVariant);

  return ThemeData(
    useMaterial3: true,
    colorScheme: barve,
    textTheme: besedila,
    fontFamily: besedila.bodyMedium?.fontFamily,
    scaffoldBackgroundColor: barve.surface,
    extensions: [temna ? RibartesBarve.temna : RibartesBarve.svetla],
    visualDensity: VisualDensity.standard,

    appBarTheme: AppBarTheme(
      backgroundColor: barve.surface,
      foregroundColor: barve.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: besedila.headlineSmall,
    ),

    // Kartice: ploščate, brez senc, s tankim robom – kot kamen v produ.
    cardTheme: CardThemeData(
      elevation: 0,
      color: barve.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: Razmik.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Zaobljenost.kartica),
        side: rob,
      ),
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: Razmik.l),
      iconColor: barve.primary,
      titleTextStyle: besedila.titleMedium,
      subtitleTextStyle: besedila.bodySmall,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Zaobljenost.kartica)),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: gumbOblika,
        textStyle: besedila.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: gumbOblika,
        side: BorderSide(color: barve.primary, width: 1.5),
        textStyle: besedila.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: besedila.labelLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: barve.primary,
      foregroundColor: barve.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Zaobljenost.kartica)),
      extendedTextStyle: besedila.labelLarge,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: barve.surfaceContainerLow,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Razmik.l, vertical: Razmik.l),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Zaobljenost.gumb),
        borderSide: rob,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Zaobljenost.gumb),
        borderSide: rob,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Zaobljenost.gumb),
        borderSide: BorderSide(color: barve.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Zaobljenost.gumb),
        borderSide: BorderSide(color: barve.error),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: barve.primary.withValues(alpha: 0.08),
      selectedColor: barve.primary,
      labelStyle: besedila.labelMedium,
      secondaryLabelStyle:
          besedila.labelMedium?.copyWith(color: barve.onPrimary),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: Razmik.s),
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(0, 48),
        selectedBackgroundColor: barve.primary,
        selectedForegroundColor: barve.onPrimary,
        side: rob,
        textStyle: besedila.labelMedium,
      ),
    ),

    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? barve.primary : null),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: barve.primary,
      thumbColor: barve.primary,
      inactiveTrackColor: barve.primary.withValues(alpha: 0.18),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: barve.primary,
      linearTrackColor: barve.primary.withValues(alpha: 0.15),
    ),

    dividerTheme: DividerThemeData(
        color: barve.outlineVariant, thickness: 1, space: Razmik.xl),

    dialogTheme: DialogThemeData(
      backgroundColor: temna ? Paleta.nocPovrsina : Paleta.kamen,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Zaobljenost.glava)),
      titleTextStyle: besedila.titleLarge,
      contentTextStyle: besedila.bodyMedium,
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: temna ? Paleta.nocPovrsina : Paleta.kamen,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(Zaobljenost.glava)),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: temna ? const Color(0xFFE4EEEA) : Paleta.tolmun,
      contentTextStyle: besedila.bodyMedium?.copyWith(
          color: temna ? Paleta.tolmun : Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Zaobljenost.gumb)),
    ),

    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: temna ? Paleta.nocPovrsina : Paleta.kamen,
      surfaceTintColor: Colors.transparent,
      indicatorColor: barve.primary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((s) =>
          (s.contains(WidgetState.selected)
                  ? besedila.labelMedium?.copyWith(color: barve.primary)
                  : besedila.labelMedium)
              ?.copyWith(fontSize: 12)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? barve.primary
                : barve.onSurface.withValues(alpha: 0.65),
          )),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: barve.primary,
      unselectedLabelColor: barve.onSurface.withValues(alpha: 0.6),
      indicatorColor: barve.primary,
      labelStyle: besedila.labelLarge,
      dividerColor: barve.outlineVariant,
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Paleta.tolmun,
        borderRadius: BorderRadius.circular(Zaobljenost.majhna),
      ),
      textStyle: besedila.bodySmall?.copyWith(color: Colors.white),
    ),
  );
}
