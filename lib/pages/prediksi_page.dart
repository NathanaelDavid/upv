// lib/pages/prediksi_page.dart
import 'package:flutter/material.dart';
import 'package:upv/pages/full_screen_images_page.dart';

class PrediksiPage extends StatelessWidget {
  const PrediksiPage({super.key});

  final List<Map<String, String>> daftarPrediksi = const [
    {'kode': 'AUD', 'nama': 'Dolar Australia'},
    {'kode': 'BND', 'nama': 'Dolar Brunei'},
    {'kode': 'CNY', 'nama': 'Yuan China'},
    {'kode': 'EUR', 'nama': 'Euro'},
    {'kode': 'HKD', 'nama': 'Dolar Hong Kong'},
    {'kode': 'KRW', 'nama': 'Won Korea Selatan'},
    {'kode': 'MYR', 'nama': 'Ringgit Malaysia'},
    {'kode': 'SAR', 'nama': 'Riyal Arab Saudi'},
    {'kode': 'SGD', 'nama': 'Dolar Singapura'},
    {'kode': 'THB', 'nama': 'Baht Thailand'},
    {'kode': 'USD', 'nama': 'Dolar Amerika Serikat'},
  ];

  Widget _buildPrediksiItem(
      BuildContext context, Map<String, String> prediksi) {
    final String kodeMataUang = prediksi['kode']!;
    final String namaMataUang = prediksi['nama']!;
    // Asumsi path gambar masih sama dari diskusi terakhir
    final String imagePath = 'lib/gambar/prediksi_stok_$kodeMataUang.png';
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String heroTag =
        'prediksi-$kodeMataUang'; // Tag unik untuk Hero animation

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Prediksi Stok: $namaMataUang ($kodeMataUang)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10.0),
            Expanded(
              child: GestureDetector(
                // --- TAMBAHKAN GestureDetector ---
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(
                        imagePath: imagePath,
                        heroTag: heroTag, // Kirim tag yang sama
                      ),
                    ),
                  );
                },
                child: Hero(
                  // --- TAMBAHKAN Hero ---
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        print("Error memuat gambar: $imagePath - $error");
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    size: 40, color: Colors.grey[500]),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                    'Gagal memuat gambar untuk $kodeMataUang.\nPastikan path benar dan sudah rebuild aplikasi.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarForegroundColor =
        Theme.of(context).appBarTheme.toolbarTextStyle?.color ??
            Theme.of(context).appBarTheme.titleTextStyle?.color ??
            (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grafik Prediksi Stok"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: appBarForegroundColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(
          color: appBarForegroundColor,
        ),
      ),
      body: daftarPrediksi.isEmpty
          ? Center(/* ... (empty state tetap sama) ... */)
          : LayoutBuilder(
              builder: (context, constraints) {
                bool isWideScreen = constraints.maxWidth > 600;

                if (isWideScreen) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: daftarPrediksi.length,
                    itemBuilder: (context, index) {
                      return _buildPrediksiItem(context, daftarPrediksi[index]);
                    },
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 12.0),
                    itemCount: daftarPrediksi.length,
                    itemBuilder: (context, index) {
                      return SizedBox(
                        height: 350,
                        child:
                            _buildPrediksiItem(context, daftarPrediksi[index]),
                      );
                    },
                  );
                }
              },
            ),
    );
  }
}
