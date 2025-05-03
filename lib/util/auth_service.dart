import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SIGN UP (Register)
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String? uid = userCredential.user?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'email': email,
          'role': 'user'
        });
      }
      return userCredential.user;
    } catch (e) {
      print("Error during sign-up: $e");
      rethrow;
    }
  }

  // SIGN IN (Login)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error during sign-in: $e");
      rethrow;
    }
  }

  // SIGN OUT (Logout)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // GET CURRENT USER
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
