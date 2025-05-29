import 'package:flutter/material.dart';
import '../widgets/kalkulator.dart'; // Pastikan path import ini benar
import '../widgets/chart_widget.dart'; // Pastikan path import ini benar
import '../widgets/currency_widget.dart'; // Pastikan path import ini benar

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const double breakpointWidth = 768.0; // Breakpoint untuk beralih layout
    const double chartHeightNarrowScreen =
        350.0; // Tinggi tetap untuk chart di layar sempit

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > breakpointWidth) {
          // Layout untuk layar lebar (misalnya tablet landscape, desktop)
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Widget sejajar dari atas
              children: [
                Expanded(
                  flex: 2, // Kalkulator mengambil 2 bagian dari sisa ruang
                  child: CurrencyCalculator(),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  flex: 4, // Chart mengambil 4 bagian, lebih besar
                  child: ChartWidget(),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  flex: 2, // Kurs mata uang mengambil 2 bagian
                  child: CurrencyWidget(),
                ),
              ],
            ),
          );
        } else {
          // Layout untuk layar sempit (misalnya mobile portrait, tablet portrait)
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // Widget mengisi lebar secara default
              children: [
                // Kalkulator Mata Uang
                // Akan mengisi lebar karena CrossAxisAlignment.stretch
                CurrencyCalculator(),
                const SizedBox(height: 16.0), // Jarak vertikal

                // Widget Grafik dengan tinggi yang ditentukan
                // Akan mengisi lebar karena CrossAxisAlignment.stretch
                SizedBox(
                  height: chartHeightNarrowScreen,
                  child: ChartWidget(),
                ),
                const SizedBox(height: 16.0),

                // Widget Kurs Mata Uang
                // Dibungkus dengan Center agar berada di tengah secara horizontal.
                // Center akan mengizinkan CurrencyWidget untuk mengambil lebar intrinsiknya.
                Center(
                  child: CurrencyWidget(),
                ),

                // Tambahkan SizedBox di akhir jika perlu ruang ekstra di bawah
                // const SizedBox(height: 16.0),
              ],
            ),
          );
        }
      },
    );
  }
}
