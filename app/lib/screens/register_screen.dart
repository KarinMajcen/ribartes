import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';

/// Zaslon "Registracija" – pokriva US-01.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _gesloCtrl = TextEditingController();
  final _auth = AuthService();

  bool _nalaganje = false;
  bool _skrijGeslo = true;
  String? _napaka;

  @override
  void dispose() {
    _imeCtrl.dispose();
    _emailCtrl.dispose();
    _gesloCtrl.dispose();
    super.dispose();
  }

  Future<void> _registracija() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _nalaganje = true;
      _napaka = null;
    });

    try {
      await _auth.registracija(
        ime: _imeCtrl.text,
        email: _emailCtrl.text,
        geslo: _gesloCtrl.text,
      );
      if (!mounted) return;
      // Zapri ta zaslon; pod njim AuthGate že kaže Domači zaslon.
      Navigator.of(context).popUntil((route) => route.isFirst);
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
      appBar: AppBar(title: const Text('Registracija')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _imeCtrl,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Ime in priimek',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vnesite ime.'
                      : null,
                ),
                const SizedBox(height: 16),
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
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Geslo',
                    helperText: 'Vsaj 6 znakov',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _skrijGeslo ? 'Pokaži geslo' : 'Skrij geslo',
                      icon: Icon(
                          _skrijGeslo ? Icons.visibility : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _skrijGeslo = !_skrijGeslo),
                    ),
                  ),
                  // Scenarij "prekratko geslo" iz US-01.
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Geslo mora imeti vsaj 6 znakov.'
                      : null,
                  onFieldSubmitted: (_) => _registracija(),
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
                  onPressed: _nalaganje ? null : _registracija,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _nalaganje
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ustvari račun'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
