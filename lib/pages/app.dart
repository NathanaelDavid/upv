// lib/app.dart (atau di mana pun file App Anda berada)
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:upv/pages/invoice_page.dart';
import 'package:upv/pages/login_page.dart';
import 'package:upv/pages/marketing_page.dart';
import 'package:upv/pages/prediksi_page.dart';
import 'package:upv/pages/transaksi_page.dart';
import 'package:upv/pages/chat_page.dart';
import 'package:upv/pages/grafik_page.dart';
import 'package:upv/pages/grafik_stok_page.dart';
import 'package:upv/pages/home_page.dart';
import 'package:upv/pages/chart_page.dart';
import 'package:upv/pages/CompanyProfilePage.dart';
import 'package:upv/pages/laporan_page.dart';
import 'package:upv/pages/laporan_jual_page.dart';
import 'package:upv/pages/laporan_beli_page.dart';
import 'package:upv/pages/laporan_bulan_page.dart';
import 'package:upv/widgets/navigation_buttons.dart';
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

  // --- TAMBAHKAN STATE UNTUK VISIBILITAS NAVBAR ---
  bool _isNavbarVisible = true;
  // Atur ke false jika Anda ingin navbar tersembunyi secara default saat login

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
          _isNavbarVisible =
              false; // Navbar tidak relevan jika belum login & di marketing page
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
          _isNavbarVisible = true; // Tampilkan navbar saat pengguna login
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
    // ... (fungsi ini tetap sama)
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

  // --- FUNGSI UNTUK TOGGLE NAVBAR ---
  void _toggleNavbarVisibility() {
    if (!mounted) return;
    setState(() {
      _isNavbarVisible = !_isNavbarVisible;
    });
  }

  Widget _buildLoggedOutActions(BuildContext context) {
    // ... (fungsi ini tetap sama)
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
    // ... (fungsi ini tetap sama)
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.account_circle,
          // warna ikon akan mengikuti actionsIconTheme di AppBar
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
    // ... (fungsi ini tetap sama, pastikan sudah ada InvoicePage & PrediksiPage)
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
          (const GrafikStokPage(), 'Kurs'),
          (const TransaksiPage(), 'Transaksi'),
          (const LaporanPage(), 'Lap. Kurs'),
          (const LaporanJualPage(), 'Lap. Jual'),
          (const LaporanBeliPage(), 'Lap. Beli'),
          (const LaporanBulanPage(), 'Lap. Bulan'),
          (const InvoicePage(), 'Invoice'),
          (const PrediksiPage(), 'Prediksi'),
        ];
      case 'admin':
        return [
          (companyProfilePage, 'Profil'),
          (homePage, 'Home'),
          (ChatPage(userRole: _userRole!), 'Chat'),
          (chartPage, 'Grafik Kurs'),
          (const TransaksiPage(), 'Transaksi'),
          (const LaporanBulanPage(), 'Lap. Bulan'),
          (const InvoicePage(), 'Invoice'),
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
    // ... (fungsi ini tetap sama)
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
      // Untuk MarketingPage, kita tidak menampilkan navbar
      return MarketingPage();
    }

    final widgetOptions = _getWidgetOptions();

    if (widgetOptions.isEmpty) {
      return Center(
          child: Text("Tidak ada halaman tersedia untuk peran Anda."));
    }

    if (_selectedIndex >= widgetOptions.length) {
      _selectedIndex = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- GUNAKAN Visibility UNTUK NAVBAR ---
        Visibility(
          visible: _isNavbarVisible,
          // MaintainSize, maintainAnimation, maintainState bisa diatur jika perlu
          // untuk menjaga state navbar saat disembunyikan, tapi untuk kasus sederhana
          // cukup visible saja.
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .cardColor, // Warna latar yang lebih sesuai tema
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: NavigationButtons(
              onItemTapped: _onItemTapped,
              selectedIndex: _selectedIndex,
              menus: widgetOptions.map((e) => e.$2).toList(),
            ),
          ),
        ),
        // Opsional: Pemisah jika navbar terlihat
        if (_isNavbarVisible) const Divider(height: 1, thickness: 1),

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

    // Warna untuk AppBar Title dan Icons agar kontras dengan background AppBar
    const Color appBarContentColor = Colors.white;

    return Scaffold(
        appBar: AppBar(
            title: const Text(
              'Untung Prima Valasindo',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: appBarContentColor,
                  fontWeight: FontWeight.bold), // Style untuk title
            ),
            backgroundColor: const Color.fromARGB(
                255, 48, 37, 201), // Warna background AppBar
            iconTheme: const IconThemeData(
                color: appBarContentColor), // Untuk leading icon jika ada
            actionsIconTheme: const IconThemeData(
                color: appBarContentColor), // Untuk icons di actions
            actions: [
              // --- TAMBAHKAN TOMBOL TOGGLE NAVBAR JIKA PENGGUNA LOGIN ---
              if (_userRole != null) // Hanya tampilkan jika sudah login
                IconButton(
                  icon: Icon(
                    _isNavbarVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: _isNavbarVisible
                      ? 'Sembunyikan Navigasi'
                      : 'Tampilkan Navigasi',
                  onPressed: _toggleNavbarVisibility,
                ),
              if (_userRole == null)
                _buildLoggedOutActions(context)
              else
                _buildLoggedInActions(),
            ]),
        body: _getBody());
  }
}
