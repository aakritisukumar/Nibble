import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;
  static String? get currentEmail => _auth.currentUser?.email;
  static String? get currentDisplayName => _auth.currentUser?.displayName;

  static Future<void> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user?.sendEmailVerification();
    // Note: caller is responsible for signing out after saving any initial data
  }

  static Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Returns null if user cancelled, otherwise the UserCredential.
  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
