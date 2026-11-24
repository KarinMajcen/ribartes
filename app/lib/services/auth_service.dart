import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Napaka z že prevedenim sporočilom, ki ga zaslon prikaže uporabniku.
class AuthNapaka implements Exception {
  final String sporocilo;
  AuthNapaka(this.sporocilo);

  @override
  String toString() => sporocilo;
}

/// Plast "repozitorij" za prijavo: zasloni ne kličejo Firebase neposredno,
/// ampak samo te metode. Tako je UI ločen od vira podatkov (glej 5.3 v specifikaciji).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Tok, ki sporoči vsako spremembo prijave (prijava, odjava, zagon aplikacije).
  Stream<User?> get spremembePrijave => _auth.authStateChanges();

  User? get trenutniUporabnik => _auth.currentUser;

  /// US-01: ustvari račun in profil ribiča v zbirki "uporabniki".
  Future<void> registracija({
    required String ime,
    required String email,
    required String geslo,
  }) async {
    try {
      final rezultat = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: geslo,
      );
      final user = rezultat.user!;
      await user.updateDisplayName(ime.trim());

      await _db.collection('uporabniki').doc(user.uid).set({
        'ime': ime.trim(),
        'email': email.trim(),
        'tocke': 0,
        'vloga': 'ribic',
        'ustvarjen': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthNapaka(_prevediNapako(e.code));
    }
  }

  /// US-02: prijava z e-pošto in geslom.
  Future<void> prijava({required String email, required String geslo}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: geslo,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthNapaka(_prevediNapako(e.code));
    }
  }

  /// US-02: odjava.
  Future<void> odjava() => _auth.signOut();

  /// Kode napak Firebase prevede v sporočila iz scenarijev v specifikaciji.
  String _prevediNapako(String koda) {
    switch (koda) {
      case 'email-already-in-use':
        return 'Račun s to e-pošto že obstaja.';
      case 'invalid-email':
        return 'E-poštni naslov ni veljaven.';
      case 'weak-password':
        return 'Geslo mora imeti vsaj 6 znakov.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Napačna e-pošta ali geslo.';
      case 'network-request-failed':
        return 'Ni povezave. Preverite internet in poskusite znova.';
      case 'too-many-requests':
        return 'Preveč poskusov. Poskusite znova čez nekaj minut.';
      case 'user-disabled':
        return 'Ta račun je onemogočen.';
      default:
        return 'Prišlo je do napake ($koda). Poskusite znova.';
    }
  }
}
