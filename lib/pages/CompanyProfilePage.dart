import 'package:flutter/material.dart';
import '../widgets/currency_widget.dart'; // Pastikan path ini benar

class CompanyProfilePage extends StatelessWidget {
  final List<String> imagePaths = [
    'lib/gambar/gambar_1.jpeg', // Pastikan gambar ada di path ini
    'lib/gambar/gambar_2.jpeg', // dan terdaftar di pubspec.yaml
    'lib/gambar/gambar_3.jpeg',
    'lib/gambar/gambar_4.jpeg',
  ];

  CompanyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 244, 255),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                // LayoutBuilder utama untuk info perusahaan dan currency widget
                builder: (context, constraints) {
                  bool useRowLayout = constraints.maxWidth > 700;
                  return useRowLayout
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 3, child: _buildCompanyInfo(context)),
                            const SizedBox(width: 24.0),
                            const Expanded(flex: 2, child: CurrencyWidget()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCompanyInfo(context),
                            const SizedBox(height: 20.0),
                            const CurrencyWidget(),
                          ],
                        );
                },
              ),
              const SizedBox(height: 32.0),
              _buildImageGallery(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        Text(
          'Untung Prima Valasindo',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 39, 39, 39),
              ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Solusi terbaik untuk transaksi mata uang asing Anda.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color.fromARGB(255, 60, 60, 60),
              ),
        ),
        const SizedBox(height: 24.0),
        Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tentang Kami',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Kami adalah perusahaan yang bergerak di bidang valuta asing, menyediakan layanan terbaik untuk kebutuhan transaksi mata uang Anda dengan rate yang kompetitif dan pelayanan yang profesional.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color.fromARGB(255, 39, 39, 39),
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Visi:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Menjadi penyedia layanan valuta asing terpercaya dan terkemuka di Indonesia.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color.fromARGB(255, 39, 39, 39),
                      ),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Misi:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 4.0),
                const Text(
                  '1. Memberikan layanan terbaik dan solusi finansial yang inovatif kepada pelanggan.\n'
                  '2. Menyediakan informasi kurs mata uang yang akurat dan terkini.\n'
                  '3. Membangun kepercayaan serta hubungan jangka panjang yang saling menguntungkan dengan semua pelanggan dan mitra.',
                  style: TextStyle(
                    fontSize: 15.0,
                    color: Color.fromARGB(255, 39, 39, 39),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    if (imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Galeri Perusahaan',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorDark,
              ),
        ),
        const SizedBox(height: 16.0),
        LayoutBuilder(
          builder: (context, constraints) {
            // Tentukan breakpoint untuk layout mobile vs desktop/tablet
            bool isMobileLayout = constraints.maxWidth < 600;

            if (isMobileLayout) {
              // Mobile: ListView vertikal
              return ListView.builder(
                shrinkWrap:
                    true, // Penting karena berada di dalam Column yang di-scroll oleh SingleChildScrollView
                physics:
                    const NeverScrollableScrollPhysics(), // Scroll utama ditangani oleh SingleChildScrollView
                itemCount: imagePaths.length,
                itemBuilder: (context, index) {
                  return _buildGalleryImageItem(
                    imagePath: imagePaths[index],
                    isHorizontalList: false, // Tidak ada padding kanan khusus
                    itemWidth: constraints
                        .maxWidth, // Gambar mengambil lebar penuh di mobile
                    itemHeight: constraints.maxWidth *
                        (9 / 16), // Rasio 16:9 untuk tinggi
                  );
                },
              );
            } else {
              // Desktop/Tablet: ListView horizontal
              return SizedBox(
                height:
                    280, // Tinggi tetap untuk galeri horizontal, bisa disesuaikan
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagePaths.length,
                  itemBuilder: (context, index) {
                    return _buildGalleryImageItem(
                      imagePath: imagePaths[index],
                      isHorizontalList: true, // Akan ada padding kanan
                      itemWidth:
                          350, // Lebar tetap untuk item di list horizontal, bisa disesuaikan
                      itemHeight:
                          260, // Tinggi tetap, bisa disesuaikan agar proporsional
                    );
                  },
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildGalleryImageItem({
    required String imagePath,
    bool isHorizontalList = false,
    double? itemWidth, // Lebar bisa opsional
    double? itemHeight, // Tinggi bisa opsional
  }) {
    return Container(
      // Menggunakan Container untuk mengatur margin/padding dan ukuran
      width: itemWidth,
      height: itemHeight,
      padding: EdgeInsets.only(
        right: isHorizontalList
            ? 12.0
            : 0.0, // Padding kanan hanya untuk list horizontal
        bottom: !isHorizontalList
            ? 12.0
            : 0.0, // Padding bawah hanya untuk list vertikal
      ),
      child: Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          // Container di dalam Card untuk warna placeholder
          color: Colors.grey[200],
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover, // Memastikan gambar mengisi area Card
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 50,
                  color: Colors.grey[400],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
