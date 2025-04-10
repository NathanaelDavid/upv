import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final List<String> imagePaths = [
    'gambar/gambar_1.jpeg',
    'gambar/gambar_2.jpeg',
    'gambar/gambar_3.jpeg',
    'gambar/gambar_4.jpeg',
  ];

  final List<Map<String, dynamic>> currencies = [
    {'currency': 'USD', 'buy': 15900, 'sell': 15950},
    {'currency': 'EUR', 'buy': 16500, 'sell': 16550},
    {'currency': 'JPY', 'buy': 100, 'sell': 105},
    {'currency': 'MYR', 'buy': 3350, 'sell': 3500},
  ];

  DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Perusahaan
            Text(
              'Profil Perusahaan',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              // ignore: prefer_const_constructors
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visi:',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Menjadi penyedia layanan penukaran uang terpercaya di Indonesia.',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Misi:',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "- Memberikan layanan yang cepat, aman, dan nyaman.\n- Menyediakan nilai tukar yang kompetitif.\n- Berkomitmen pada kepuasan pelanggan.",
                      style: TextStyle(fontSize: 16.0),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Deskripsi:',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Untung Prima Valasindo adalah perusahaan money changer yang telah berdiri sejak tahun 2013 dan memiliki reputasi unggul dalam melayani kebutuhan valuta asing.',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Lokasi:',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pasar Baru lantai 3 Blok C2 No. 60 Jl. Otto Iskandardinata No. 70, Bandung',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Kurs Mata Uang
            Text(
              'Kurs Mata Uang',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      child: Text(currencies[index]['currency']),
                    ),
                    title: Text(
                      '${currencies[index]['currency']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Beli: ${currencies[index]['buy']} | Jual: ${currencies[index]['sell']}',
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),

            // Galeri Perusahaan
            Text(
              'Galeri Perusahaan',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 16),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.asset(
                      imagePaths[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
