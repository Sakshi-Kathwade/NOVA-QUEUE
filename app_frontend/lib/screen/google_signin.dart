import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        "1092004219946-a10iuqe384o69jpcah5hbe7t56j00s02.apps.googleusercontent.com",
    clientId: kIsWeb ? "1092004219946-a10iuqe384o69jpcah5hbe7t56j00s02.apps.googleusercontent.com" : null,
  );

  Future<User?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;

      // Sign out any existing Google account first to ensure fresh sign-in
      await _googleSignIn.signOut();
      googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Get authentication details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth errors
      debugPrint("Firebase Auth Error: ${e.code} - ${e.message}");
      rethrow; // Re-throw to let caller handle
    } catch (e) {
      // Handle other errors
      debugPrint("Google Sign-In Error: $e");
      rethrow; // Re-throw to let caller handle
    }
  }
}
