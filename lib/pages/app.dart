import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:upv/pages/grafik_api_page.dart'; // Uncomment jika digunakan
import 'package:upv/pages/login_page.dart';
import 'package:upv/pages/marketing_page.dart';
import 'package:upv/pages/transaksi_page.dart';
import 'package:upv/pages/chat_page.dart';
// import 'package:upv/pages/currency_analysis_page.dart'; // Uncomment jika digunakan
import 'package:upv/pages/grafik_page.dart'; // Pastikan digunakan atau hapus jika tidak
import 'package:upv/pages/grafik_stok_page.dart';
import 'package:upv/pages/home_page.dart';
import 'package:upv/pages/chart_page.dart';
import 'package:upv/pages/CompanyProfilePage.dart'; // Pastikan nama file konsisten (CompanyProfilePage.dart)
import 'package:upv/pages/laporan_page.dart';
import 'package:upv/pages/laporan_jual_page.dart';
import 'package:upv/pages/laporan_beli_page.dart';
import 'package:upv/pages/laporan_bulan_page.dart';
import 'package:upv/widgets/navigation_buttons.dart'; // Widget navigasi Anda
import 'package:cloud_firestore/cloud_firestore.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = true;
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;

      if (user == null) {
        setState(() {
          _userRole = null;
          _isLoading = false;
          _selectedIndex = 0;
        });
      } else {
        setState(() {
          _isLoading = true;
        });
        final role = await _getUserRole(user.uid);
        if (!mounted) return;
        setState(() {
          _selectedIndex = 0;
          _userRole = role;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<String> _getUserRole(String userId) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('role') && data['role'] != null) {
          return data['role'] as String;
        }
      }
    } catch (e) {
      print("Error saat mengambil peran pengguna: $e");
    }
    return 'user';
  }

  Widget _buildLoggedOutActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
        ),
        child: const Text(
          'Login',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLoggedInActions() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.account_circle,
          color: Colors.white,
          size: 28,
        ),
        position: PopupMenuPosition.under,
        onSelected: (value) async {
          if (value == 'logout') {
            await FirebaseAuth.instance.signOut();
          }
        },
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout,
                    size: 20,
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black87),
                const SizedBox(width: 8),
                const Text('Logout'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(Widget, String)> _getWidgetOptions() {
    final companyProfilePage = CompanyProfilePage();
    const homePage = HomePage();
    const chartPage = ChartPage();

    switch (_userRole) {
      case 'owner':
        return [
          (companyProfilePage, 'Profil'),
          (homePage, 'Home'),
          (ChatPage(userRole: _userRole!), 'Chat'),
          (chartPage, 'Grafik Kurs'),
          (const GrafikStokPage(), 'Stok Kurs'),
          (const TransaksiPage(), 'Transaksi'),
          (const LaporanPage(), 'Lap. Kurs'),
          (const LaporanJualPage(), 'Lap. Jual'),
          (const LaporanBeliPage(), 'Lap. Beli'),
          (const LaporanBulanPage(), 'Lap. Bulan'),
        ];
      case 'admin':
        return [
          (companyProfilePage, 'Profil'),
          (homePage, 'Home'),
          (ChatPage(userRole: _userRole!), 'Chat'),
          (chartPage, 'Grafik Kurs'),
          (const TransaksiPage(), 'Transaksi'),
        ];
      case 'user':
        return [
          (companyProfilePage, 'Profil'),
          (homePage, 'Home'),
          (ChatPage(userRole: _userRole!), 'Chat'),
          (chartPage, 'Grafik Kurs'),
        ];
      case null:
        return [];
      default:
        print(
            "Peran pengguna tidak dikenal: $_userRole, menampilkan halaman default.");
        return [
          (homePage, 'Home'),
          (const GrafikPage(), 'Grafik'),
        ];
    }
  }

  void _onItemTapped(int index) {
    final options = _getWidgetOptions();
    if (index >= 0 && index < options.length) {
      setState(() {
        _selectedIndex = index;
      });
    } else {
      print("Index $index di luar batas untuk opsi sebanyak ${options.length}");
    }
  }

  Widget _getBody() {
    if (_userRole == null) {
      return MarketingPage();
    }

    final widgetOptions = _getWidgetOptions();

    if (widgetOptions.isEmpty) {
      print(
          "Peringatan: Pengguna login tapi tidak ada opsi widget untuk peran: $_userRole");
      return const Center(
          child: Text("Tidak ada halaman tersedia untuk peran Anda."));
    }

    if (_selectedIndex >= widgetOptions.length) {
      print(
          "Peringatan: _selectedIndex ${_selectedIndex} di luar batas (${widgetOptions.length}). Reset ke 0.");
      _selectedIndex = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Container untuk area navigasi
        Container(
          padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 8.0), // Padding di sekitar NavigationButtons
          decoration: BoxDecoration(
            color: Colors.white, // Latar belakang untuk bar navigasi
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset:
                    const Offset(0, 2), // Bayangan lembut di bawah bar navigasi
              ),
            ],
          ),
          // Langsung gunakan NavigationButtons.
          // Karena NavigationButtons sekarang menggunakan Wrap, ia akan mengatur tingginya sendiri.
          // SingleChildScrollView(scrollDirection: Axis.horizontal) tidak lagi diperlukan di sini.
          child: NavigationButtons(
            onItemTapped: _onItemTapped,
            selectedIndex: _selectedIndex,
            menus: widgetOptions.map((e) => e.$2).toList(),
          ),
        ),
        // const Divider(height: 1, thickness: 1), // Opsional: pemisah visual
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: widgetOptions.isNotEmpty
                ? widgetOptions[_selectedIndex].$1
                : const Center(child: Text("Halaman tidak ditemukan.")),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
            title: const Text('Untung Prima Valasindo',
                overflow: TextOverflow.ellipsis),
            backgroundColor: const Color.fromARGB(230, 48, 37, 201),
            actions: [
              if (_userRole == null)
                _buildLoggedOutActions(context)
              else
                _buildLoggedInActions(),
            ]),
        body: _getBody());
  }
}
