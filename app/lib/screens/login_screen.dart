import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import 'register_screen.dart';

/// Zaslon "Prijava" – pokriva US-02.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _gesloCtrl = TextEditingController();
  final _auth = AuthService();

  bool _nalaganje = false;
  bool _skrijGeslo = true;
  String? _napaka;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _gesloCtrl.dispose();
    super.dispose();
  }

  Future<void> _prijava() async {
    // Najprej preveri polja v obrazcu (validatorji spodaj).
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _nalaganje = true;
      _napaka = null;
    });

    try {
      await _auth.prijava(
        email: _emailCtrl.text,
        geslo: _gesloCtrl.text,
      );
      // Ob uspehu ni treba ničesar: AuthGate sam preklopi na Domači zaslon.
    } on AuthNapaka catch (e) {
      setState(() => _napaka = e.sporocilo);
    } finally {
      if (mounted) setState(() => _nalaganje = false);
    }
  }

  Future<void> _pozabljenoGeslo() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _napaka =
          'Vpišite e-pošto zgoraj, nato tapnite »Pozabljeno geslo?«.');
      return;
    }
    setState(() {
      _nalaganje = true;
      _napaka = null;
    });
    try {
      await _auth.ponastaviGeslo(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Povezavo za novo geslo smo poslali na $email.'),
      ));
    } on AuthNapaka catch (e) {
      setState(() => _napaka = e.sporocilo);
    } finally {
      if (mounted) setState(() => _nalaganje = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final barve = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: barve.primary,
                      child: Icon(Icons.phishing,
                          size: 56, color: barve.onPrimary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  Text(
                    'RIBARTes',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Lovim, torej sem',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: barve.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'E-pošta',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Vnesite veljaven e-poštni naslov.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gesloCtrl,
                    obscureText: _skrijGeslo,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Geslo',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _skrijGeslo ? 'Pokaži geslo' : 'Skrij geslo',
                        icon: Icon(_skrijGeslo
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            setState(() => _skrijGeslo = !_skrijGeslo),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Vnesite geslo.' : null,
                    onFieldSubmitted: (_) => _prijava(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _nalaganje ? null : _pozabljenoGeslo,
                      child: const Text('Pozabljeno geslo?'),
                    ),
                  ),
                  if (_napaka != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _napaka!,
                      style: TextStyle(color: barve.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _nalaganje ? null : _prijava,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _nalaganje
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Prijava'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _nalaganje
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                    child: const Text('Nimaš računa? Registriraj se'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
