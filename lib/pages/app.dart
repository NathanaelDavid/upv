import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:upv/pages/grafik_api_page.dart';
import 'package:upv/pages/login_page.dart';
import 'package:upv/pages/marketing_page.dart';
import 'package:upv/pages/transaksi_page.dart';
import 'package:upv/pages/chat_page.dart';
import 'package:upv/pages/currency_analysis_page.dart';
import 'package:upv/pages/grafik_page.dart';
import 'package:upv/pages/grafik_stok_page.dart';
import 'package:upv/pages/home_page.dart';
import 'package:upv/pages/chart_page.dart';
import 'package:upv/pages/CompanyProfilePage.dart';
import 'package:upv/pages/laporan_page.dart';
import 'package:upv/pages/laporan_jual_page.dart';
import 'package:upv/pages/laporan_beli_page.dart';
import 'package:upv/widgets/navigation_buttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0;
  String? _userRole;
  bool _isLoading = false;
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        setState(() {
          _userRole = null;
        });
      } else {
        setState(() {
          _isLoading = true;
        });
        final role = await _getUserRole(user.uid);
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

  Widget _buildLoggedOutActions(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      },
      child: const Text(
        'Login',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildLoggedInActions() {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.account_circle,
        color: Colors.white,
      ),
      position: PopupMenuPosition.under,
      onSelected: (value) async {
        if (value == 'logout') {
          await FirebaseAuth.instance.signOut();
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 8),
              Text('Logout'),
            ],
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
            title: const Text(
              'Untung Prima Valasindo',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color.fromARGB(255, 48, 37, 201),
            actions: [
              if (_userRole == null)
                _buildLoggedOutActions(context)
              else
                _buildLoggedInActions(),
              const SizedBox(width: 8)
            ]),
        body: _getBody());
  }

  Future<String> _getUserRole(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      var data = userDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('role')) {
        return data['role'];
      }
    }
    return 'user';
  }

  List<(Widget, String)> _getWidgetOptions() {
    switch (_userRole) {
      case 'owner':
        return [
          (CompanyProfilePage(), 'Company Profile'),
          (HomePage(), 'Home'),
          (ChatPage(userRole: _userRole), 'Chat'),
          (ChartPage(), 'Grafik'),
          (GrafikStokPage(), 'Kurs'),
          (TransaksiPage(), 'Transaksi'),
          (LaporanPage(), 'Laporan Kurs'),
          (LaporanJualPage(), 'Laporan Jual'),
          (LaporanBeliPage(), 'Laporan Beli'),
          // (
          //   CurrencyAnalysisPage(onNavigate: (p0) => 0, selectedIndex: 0),
          //   'Analisis'
          // )
        ];
      case 'admin':
        return [
          (HomePage(), 'Home'),
          (ChatPage(userRole: _userRole), 'Chat'),
          (ChartPage(), 'Chart'),
          (TransaksiPage(), 'Transaksi'),
        ];
      case 'user':
        return [
          (HomePage(), 'Home'),
          (ChatPage(userRole: _userRole), 'Chat'),
          (ChartPage(), 'Grafik'),
        ];
      case null:
        return [];
      default:
        return [
          (HomePage(), 'Home'),
          (ChatPage(userRole: _userRole), 'Chat'),
          (GrafikPage(), 'Grafik'),
        ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getBody() {
    if (_userRole == null) {
      return MarketingPage();
    } else {
      return Column(children: [
        NavigationButtons(
          onItemTapped: _onItemTapped,
          selectedIndex: _selectedIndex,
          menus: _getWidgetOptions().map((e) => e.$2).toList(),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: _getWidgetOptions()[_selectedIndex].$1,
          ),
        ),
      ]);
    }
  }
}
