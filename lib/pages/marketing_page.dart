import 'package:flutter/material.dart';

import 'login_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Untung Prima Valasindo',
      initialRoute: '/',
      routes: {
        '/': (context) => MarketingPage(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}

class MarketingPage extends StatelessWidget {
  final List<String> imagePaths = [
    'lib/gambar/gambar_1.jpeg',
    'lib/gambar/gambar_2.jpeg',
    'lib/gambar/gambar_3.jpeg',
    'lib/gambar/gambar_4.jpeg',
  ];

  final List<Map<String, dynamic>> currencies = [
    {'currency': 'USD', 'buy': 15900, 'sell': 15950},
    {'currency': 'EUR', 'buy': 16500, 'sell': 16550},
    {'currency': 'JPY', 'buy': 100, 'sell': 105},
  ];

  MarketingPage({super.key});

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
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
            },
            child: Text(
              'Login',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profil Perusahaan
          Text(
            'Profil Perusahaan',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Visi: Menjadi penyedia layanan penukaran uang terpercaya di Indonesia.',
            style: TextStyle(fontSize: 16.0),
          ),
          SizedBox(height: 10),
          Text(
            'Misi:\n- Memberikan layanan yang cepat, aman, dan nyaman.\n- Menyediakan nilai tukar yang kompetitif.\n- Berkomitmen pada kepuasan pelanggan.',
            style: TextStyle(fontSize: 16.0),
          ),
          SizedBox(height: 10),
          Text(
            'Deskripsi: Untung Prima Valasindo adalah perusahaan money changer yang telah berdiri sejak tahun 2013 dan memiliki reputasi unggul dalam melayani kebutuhan valuta asing.',
            style: TextStyle(fontSize: 16.0),
          ),
          SizedBox(height: 10),
          Text(
            'Lokasi: Pasar Baru lantai 3 Blok C2 No. 60 Jl. Otto Iskandardinata No. 70, Bandung.',
            style: TextStyle(fontSize: 16.0),
          ),
          SizedBox(height: 20),

          // Kurs Mata Uang
          Text(
            'Kurs Mata Uang',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencies[index]['currency'],
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      Text('Beli: ${currencies[index]['buy']}'),
                      Text('Jual: ${currencies[index]['sell']}'),
                    ],
                  ),
                ),
              );
            },
          ),
          // Galeri Perusahaan
          Text(
            'Galeri Perusahaan',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 4,
                child: Image.asset(
                  imagePaths[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
