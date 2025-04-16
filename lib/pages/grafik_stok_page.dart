import 'package:flutter/material.dart';
import '../widgets/kurs_stok_widget.dart';
import '../widgets/input_stok_widget.dart';

class GrafikStokPage extends StatelessWidget {
  const GrafikStokPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grafik Stok Mata Uang'),
      ),
      body: Row(
        children: [
          // Bagian kiri: Placeholder grafik
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.blue[50],
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: InputStokWidget(),
                ),
              ),
            ),
          ),

          // Bagian kanan: Daftar stok
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: KursStockWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
