import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../widgets/uvodni_zaslon.dart';
import 'app_shell.dart';
import 'login_screen.dart';

/// "Vratar": ob zagonu pokaže uvodni zaslon, nato posluša stanje prijave
/// in prikaže pravi zaslon. Ker Firebase prijavo zapomni, je ribič ob
/// ponovnem zagonu takoj v aplikaciji (US-02, scenarij "ostane prijavljen").
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _uvodKoncan = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) setState(() => _uvodKoncan = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().spremembePrijave,
      builder: (context, snapshot) {
        final Widget zaslon;
        if (!_uvodKoncan ||
            snapshot.connectionState == ConnectionState.waiting) {
          zaslon = const UvodniZaslon(key: ValueKey('uvod'));
        } else if (snapshot.hasData) {
          zaslon = const AppShell(key: ValueKey('aplikacija'));
        } else {
          zaslon = const LoginScreen(key: ValueKey('prijava'));
        }
        // Mehak prehod med uvodom, prijavo in aplikacijo.
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: zaslon,
        );
      },
    );
  }
}
