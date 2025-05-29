import 'package:flutter/material.dart';
import '../widgets/kurs_stok_widget.dart'; // Pastikan path import ini benar
import '../widgets/input_stok_widget.dart'; // Pastikan path import ini benar

class GrafikStokPage extends StatefulWidget {
  const GrafikStokPage({super.key});

  @override
  State<GrafikStokPage> createState() => _GrafikStokPageState();
}

class _GrafikStokPageState extends State<GrafikStokPage> {
  Key _kursWidgetKey = UniqueKey();

  void _refreshKursWidget() {
    setState(() {
      _kursWidgetKey =
          UniqueKey(); // Ganti key untuk memaksa rebuild KursStockWidget
    });
  }

  @override
  Widget build(BuildContext context) {
    // Breakpoint untuk mengubah layout dari 1 kolom ke 2 kolom
    const double twoColumnBreakpoint = 768.0;
    // Lebar maksimum untuk konten utama di layar sangat lebar (web)
    const double maxContentWidth = 1200.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Stok & Kurs'),
        centerTitle: true,
        // Warna AppBar akan mengikuti tema global aplikasi Anda
      ),
      body: SingleChildScrollView(
        // Membuat seluruh body bisa di-scroll secara vertikal
        child: Center(
          // Memusatkan konten di tengah jika layar lebih lebar dari maxContentWidth
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Padding umum untuk konten, baik lebar maupun sempit
                const EdgeInsetsGeometry pagePadding = EdgeInsets.all(16.0);

                if (constraints.maxWidth > twoColumnBreakpoint) {
                  // Layout untuk layar lebar (misalnya tablet landscape, desktop)
                  // KursStockWidget di kiri, InputStokWidget di kanan
                  return Padding(
                    padding: pagePadding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: KursStockWidget(
                            key: _kursWidgetKey,
                          ),
                        ),
                        const SizedBox(width: 16.0), // Jarak antar widget
                        Expanded(
                          flex: 2,
                          child: InputStokWidget(
                            onStokChanged: _refreshKursWidget,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Layout untuk layar sempit (misalnya mobile portrait, tablet portrait)
                  // KursStockWidget di atas, InputStokWidget di bawah
                  return Padding(
                    padding: pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KursStockWidget(
                          key: _kursWidgetKey,
                        ),
                        const SizedBox(height: 16.0),
                        InputStokWidget(
                          onStokChanged: _refreshKursWidget,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
