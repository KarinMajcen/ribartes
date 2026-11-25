import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// "Vratar": posluša stanje prijave in prikaže pravi zaslon.
/// Ker Firebase prijavo zapomni, je ribič ob ponovnem zagonu takoj
/// na Domačem zaslonu (US-02, scenarij "ostane prijavljen").
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().spremembePrijave,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
