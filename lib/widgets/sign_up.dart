import 'package:flutter/material.dart';
import '../util/auth_service.dart';

class SignUpDialog extends StatelessWidget {
  final AuthService authService; // Instance dari AuthService

  const SignUpDialog({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      title: const Text(
        'Sign Up',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 15.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 15.0),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            String email = emailController.text.trim();
            String password = passwordController.text.trim();
            String confirmPassword = confirmPasswordController.text.trim();

            if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
              _showMessage(context, 'Semua field harus diisi!');
              return;
            }

            if (password.length < 6) {
              _showMessage(context, 'Password minimal 6 karakter!');
              return;
            }

            if (password != confirmPassword) {
              _showMessage(context, 'Password tidak cocok!');
              return;
            }

            try {
              await authService.signUp(email, password);
              _showMessage(context, 'Pendaftaran berhasil!');
              Navigator.pop(context);
            } catch (e) {
              _showMessage(context, 'Gagal mendaftar: ${e.toString()}');
            }
          },
          child: const Text('Register'),
        ),
      ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
