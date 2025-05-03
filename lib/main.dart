import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:upv/firebase_options.dart';
import 'package:upv/pages/login_page.dart';
import 'package:upv/pages/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Untung Prima Valasindo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => App(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}
