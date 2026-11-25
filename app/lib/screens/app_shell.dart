import 'package:material_ui/material_ui.dart';

import 'home_screen.dart';
import 'moje_dovolilnice_screen.dart';
import 'profil_screen.dart';
import 'revirji_screen.dart';
import 'ribji_album_screen.dart';

/// Ogrodje aplikacije po prijavi: spodnja navigacijska vrstica s petimi zavihki.
/// IndexedStack ohrani stanje vsakega zavihka (npr. iskanje v revirjih),
/// ko preklopiš drugam in nazaj.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _zavihek = 0;

  void _pojdiNa(int zavihek) => setState(() => _zavihek = zavihek);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _zavihek,
        children: [
          HomeScreen(onPojdiNa: _pojdiNa),
          const RevirjiScreen(),
          MojeDovolilniceScreen(aktiven: _zavihek == Zavihek.dovolilnice),
          const RibjiAlbumScreen(),
          const ProfilScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _zavihek,
        onDestinationSelected: _pojdiNa,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Domov',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_outlined),
            selectedIcon: Icon(Icons.water),
            label: 'Revirji',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'Dovolilnice',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_album_outlined),
            selectedIcon: Icon(Icons.photo_album),
            label: 'Album',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Indeksi zavihkov, da v kodi ne pišemo golih številk.
class Zavihek {
  static const domov = 0;
  static const revirji = 1;
  static const dovolilnice = 2;
  static const album = 3;
  static const profil = 4;
}
