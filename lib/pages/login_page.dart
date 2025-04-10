import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/app.dart'; // Halaman Owner
import '../pages/app_admin.dart'; // Halaman Admin
import '../pages/app_pelanggan.dart'; // Halaman Pelanggan
import '../widgets/sign_up.dart'; // Widget Sign Up Dialog
import '../util/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  void _login(BuildContext context) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password harus diisi!');
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Format email tidak valid!');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password harus minimal 6 karakter!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim());

      String role = await _getUserRole(userCredential.user!.uid, email);
      _showMessage('Login berhasil!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _getHomePageForRole(role)),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Password salah. Coba lagi.';
      } else {
        errorMessage = 'Login gagal: ${e.message}';
      }
      _showMessage(errorMessage);
    } catch (e) {
      _showMessage('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getUserRole(String userId, String email) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      var data = userDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('role')) {
        return data['role'];
      }
    }

    // String role = 'user';
    // if (email == "upv@gmail.com") {
    //   role = 'owner';
    // } else if (email == "admin@gmail.com") {
    //   role = 'admin';
    // }

    // await firestore.collection('users').doc(userId).set({
    //   'email': email,
    // });

    return "";
  }

  Widget _getHomePageForRole(String role) {
    switch (role) {
      case 'admin':
        return App_admin();
      case 'owner':
        return App();
      default:
        return App_pelanggan();
    }
  }

  void _showSignUpDialog() {
    showDialog(
      context: context,
      builder: (context) => SignUpDialog(
        authService: authService,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 244, 255),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.account_balance,
                    size: 50,
                    color: Color.fromARGB(255, 48, 37, 201),
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Untung Prima Valasindo',
                  style: TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'Solusi Terbaik untuk mencari mata uang asing',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 30.0),
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 6.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                          const SizedBox(height: 30.0),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : () => _login(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 255, 227, 45),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Color.fromARGB(255, 39, 39, 39),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          TextButton(
                            onPressed: _showSignUpDialog,
                            child: const Text(
                              'Belum punya akun? Daftar di sini',
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
