// lib/pages/full_screen_image_page.dart (Buat file baru ini)
import 'package:flutter/material.dart';

class FullScreenImagePage extends StatelessWidget {
  final String imagePath;
  final String heroTag; // Untuk animasi Hero

  const FullScreenImagePage({
    super.key,
    required this.imagePath,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar semi-transparan untuk tombol kembali
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Colors.white), // Tombol kembali putih
      ),
      // Set extendBodyBehindAppBar ke true agar gambar memenuhi area di belakang AppBar
      extendBodyBehindAppBar: true,
      backgroundColor:
          Colors.black, // Latar belakang hitam untuk mode full screen
      body: GestureDetector(
        onTap: () {
          Navigator.of(context).pop(); // Tap di mana saja untuk kembali
        },
        child: Center(
          child: Hero(
            tag: heroTag, // Tag yang sama dengan di halaman sebelumnya
            child: InteractiveViewer(
              // Memungkinkan zoom dan pan
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain, // Pastikan seluruh gambar terlihat
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Gagal memuat gambar',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
