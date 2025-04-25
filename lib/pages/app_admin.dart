// Flutter imports:
import 'package:flutter/material.dart';
import 'package:upv/pages/chart_page.dart';
import 'package:upv/pages/transaksi_page.dart';
import '../pages/chat_page.dart';
import '../pages/grafik_page.dart';
import '../pages/home_page.dart';
import '../pages/dashboard_page.dart';
import '../widgets/navigation_buttons_admin.dart';

class App_admin extends StatefulWidget {
  const App_admin({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App_admin> {
  // Set the initial selected index to 6 for DashboardPage
  int _selectedIndex = 3; // DashboardPage is now the first page shown

  static final List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    ChatPage(),
    // GrafikPage(),
    ChartPage(),
    TransaksiPage(),
    DashboardPage() // DashboardPage is the last in the list
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Untung Prima Valasindo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 48, 37, 201),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              // Aksi untuk profil pengguna
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Gunakan widget navigasi
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
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
