import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:upv/pages/grafik_api_page.dart';
import 'package:upv/pages/login_page.dart';
import 'package:upv/pages/marketing_page.dart';
import 'package:upv/pages/transaksi_page.dart';
import '../pages/chat_page.dart';
import '../pages/currency_analysis_page.dart';
import '../pages/grafik_page.dart';
import '../pages/grafik_stok_page.dart';
import '../pages/home_page.dart';
import '../pages/dashboard_page.dart';
import '../widgets/navigation_buttons.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  // Set the initial selected index to 5 for DashboardPage
  int _selectedIndex = 5; // Sesuaikan dengan jumlah halaman yang tersedia

  static final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    ChatPage(),
    // GrafikPage(),
    ForexScreen(),
    GrafikStokPage(),
    TransaksiPage(),
    CurrencyAnalysisPage(onNavigate: (p0) => 0, selectedIndex: 0),
    DashboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Untung Prima Valasindo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 48, 37, 201),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Aksi untuk profil pengguna
            },
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Jika pengguna sudah login, tampilkan navigasi utama
            return Column(
              children: [
                NavigationButtons(
                  onItemTapped: _onItemTapped,
                  selectedIndex: _selectedIndex,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: _widgetOptions[_selectedIndex],
                  ),
                ),
              ],
            );
          } else {
            // Jika belum login, arahkan ke halaman login
            return const LoginPage();
          }
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
