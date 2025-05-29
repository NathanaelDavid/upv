import 'package:flutter/material.dart';
import 'login_page.dart'; // Pastikan LoginPage ada dan path-nya benar
import '../widgets/currency_widget.dart'; // pastikan file ini ada

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Untung Prima Valasindo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal[700], // Warna primer lebih gelap
          secondary: Colors.blueGrey[600], // Warna sekunder
          surface: Colors.white,
          background: const Color.fromARGB(
              255, 240, 245, 245), // Latar belakang sedikit kebiruan/teal muda
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
          onBackground: Colors.black87,
          error: Colors.redAccent[700],
          onError: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor:
            const Color.fromARGB(255, 240, 245, 245), // Latar belakang scaffold
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
          elevation: 2.0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800]),
          titleLarge: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
              color: Colors.teal[700]),
          titleMedium: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
              color: Colors.black87.withOpacity(0.9)),
          bodyLarge: TextStyle(
              fontSize: 16.0,
              color: Colors.black87.withOpacity(0.8),
              height: 1.5),
          bodyMedium:
              TextStyle(fontSize: 14.0, color: Colors.black54, height: 1.4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MarketingPage(),
        '/login': (context) => const LoginPage(), // Pastikan LoginPage ada
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

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 10),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoText(String text, BuildContext context,
      {bool isListItem = false}) {
    return Padding(
      padding: EdgeInsets.only(
          left: isListItem ? 8.0 : 0,
          top: isListItem ? 2.0 : 6.0,
          bottom: isListItem ? 2.0 : 6.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        // ListView utama untuk scroll seluruh halaman
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Perusahaan
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            alignment: Alignment.center,
            child: Column(
              children: [
                // Anda bisa menambahkan logo di sini jika ada
                // Image.asset('path/to/your/logo.png', height: 80),
                // const SizedBox(height: 16),
                Text(
                  'Selamat Datang di Untung Prima Valasindo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solusi Terpercaya untuk Kebutuhan Valuta Asing Anda',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7)),
                ),
              ],
            ),
          ),

          _buildSectionCard(
            context: context,
            title: 'Profil Perusahaan',
            icon: Icons.business_outlined,
            children: [
              _buildInfoText(
                  'Visi: Menjadi penyedia layanan penukaran uang terpercaya di Indonesia.',
                  context),
              _buildInfoText('Misi:', context),
              _buildInfoText(
                  '- Memberikan layanan yang cepat, aman, dan nyaman.', context,
                  isListItem: true),
              _buildInfoText(
                  '- Menyediakan nilai tukar yang kompetitif.', context,
                  isListItem: true),
              _buildInfoText('- Berkomitmen pada kepuasan pelanggan.', context,
                  isListItem: true),
              const SizedBox(height: 8),
              _buildInfoText(
                  'Deskripsi: Untung Prima Valasindo adalah perusahaan money changer yang telah berdiri sejak tahun 2013 dan memiliki reputasi unggul dalam melayani kebutuhan valuta asing.',
                  context),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.8),
                      size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildInfoText(
                          'Lokasi: Pasar Baru lantai 3 Blok C2 No. 60 Jl. Otto Iskandardinata No. 70, Bandung.',
                          context)),
                ],
              ),
            ],
          ),

          _buildSectionCard(
            context: context,
            title: 'Kurs Mata Uang Terkini',
            icon: Icons.trending_up_outlined,
            children: [
              const CurrencyWidget(), // Widget kurs mata uang
            ],
          ),

          _buildSectionCard(
            context: context,
            title: 'Galeri Perusahaan',
            icon: Icons.photo_library_outlined,
            children: [
              LayoutBuilder(// LayoutBuilder untuk galeri agar adaptif
                  builder: (context, constraints) {
                int crossAxisCount = 2;
                double childAspectRatio = 1.0; // Persegi
                double mainAxisSpacing = 12.0;
                double crossAxisSpacing = 12.0;

                if (constraints.maxWidth > 900) {
                  crossAxisCount = 4; // 4 kolom untuk layar sangat lebar
                  childAspectRatio = 4 / 3;
                } else if (constraints.maxWidth > 600) {
                  crossAxisCount = 3; // 3 kolom untuk layar lebar
                  childAspectRatio = 3 / 2;
                }
                // Untuk layar kecil, tetap 2 kolom agar tidak terlalu sempit

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: mainAxisSpacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: imagePaths.length,
                  itemBuilder: (context, index) {
                    return Card(
                      // Setiap gambar dibungkus Card
                      clipBehavior:
                          Clip.antiAlias, // Untuk memastikan ClipRRect bekerja
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Image.asset(
                        imagePaths[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }),
            ],
          ),
          const SizedBox(height: 24), // Padding di akhir
        ],
      ),
    );
  }
}
