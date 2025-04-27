import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:upv/pages/grafik_api_page.dart';
import 'package:upv/pages/marketing_page.dart';
import 'package:upv/pages/transaksi_page.dart';
import '../pages/chat_page.dart';
import '../pages/currency_analysis_page.dart';
import '../pages/grafik_page.dart';
import '../pages/grafik_stok_page.dart';
import '../pages/home_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/chart_page.dart';
import '../widgets/navigation_buttons.dart';
import '../widgets/custom_app_bar.dart';
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
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
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
    }
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel(); // Clean up the stream subscription
    super.dispose();
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

    if (_userRole == null) {
      return Scaffold(
        appBar: const CustomAppBar(),
        body: MarketingPage(),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
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
        ],
      ),
    );
  }

  Future<String> _getUserRole(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc = await firestore.collection('users').doc(userId).get();

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
          (HomePage(), 'Home'),
          (ChatPage(), 'Chat'),
          (ForexScreen(), 'Forex'),
          (GrafikStokPage(), 'Stok'),
          (TransaksiPage(), 'Transaksi'),
          (CurrencyAnalysisPage(
            onNavigate: (index) => _onItemTapped(index),
            selectedIndex: _selectedIndex,
          ), 'Analisis'),
          (DashboardPage(), 'Dashboard'),
        ];
      case 'admin':
        return [
          (HomePage(), 'Home'),
          (ChatPage(), 'Chat'),
          (ChartPage(), 'Chart'),
          (TransaksiPage(), 'Transaksi'),
          (DashboardPage(), 'Dashboard'),
        ];
      case 'user':
        return [
          (HomePage(), 'Home'),
          (ChatPage(), 'Chat'),
          (GrafikPage(), 'Grafik'),
          (DashboardPage(), 'Dashboard'),
        ];
      case null:
        return [];
      default:
        return [
          (HomePage(), 'Home'),
          (ChatPage(), 'Chat'),
          (GrafikPage(), 'Grafik'),
          (DashboardPage(), 'Dashboard'),
        ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
