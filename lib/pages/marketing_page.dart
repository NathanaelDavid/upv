import 'package:flutter/material.dart';
import 'login_page.dart';
import '../widgets/currency_widget.dart'; // pastikan file ini ada

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Untung Prima Valasindo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
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

  MarketingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          sectionTitle('Profil Perusahaan'),
          sectionText(
              'Visi: Menjadi penyedia layanan penukaran uang terpercaya di Indonesia.'),
          sectionText(
              'Misi:\n- Memberikan layanan yang cepat, aman, dan nyaman.\n- Menyediakan nilai tukar yang kompetitif.\n- Berkomitmen pada kepuasan pelanggan.'),
          sectionText(
              'Deskripsi: Untung Prima Valasindo adalah perusahaan money changer yang telah berdiri sejak tahun 2013 dan memiliki reputasi unggul dalam melayani kebutuhan valuta asing.'),
          sectionText(
              'Lokasi: Pasar Baru lantai 3 Blok C2 No. 60 Jl. Otto Iskandardinata No. 70, Bandung.'),
          const Divider(height: 32),
          sectionTitle('Kurs Mata Uang'),
          const SizedBox(height: 8),
          CurrencyWidget(),
          const Divider(height: 32),
          sectionTitle('Galeri Perusahaan'),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 1,
            ),
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  imagePaths[index],
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
    );
  }

  Widget sectionText(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Text(
        content,
        style: const TextStyle(fontSize: 14.5, color: Colors.black87),
      ),
    );
  }
}
