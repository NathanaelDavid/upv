import 'package:flutter/material.dart';
import '../widgets/chart_widget.dart';
import '../widgets/grafik_list_widget.dart';

class GrafikPage extends StatelessWidget {
  const GrafikPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Bagian kiri: Kumpulan Grafik (GrafikListWidget)
                Expanded(
                  flex: 2,
                  child: GrafikListWidget(
                    onItemSelected: (String item) {
                      // Aksi jika grafik dipilih dari daftar
                      print('Grafik dipilih: $item');
                    },
                  ),
                ),

                // Bagian kanan: Grafik besar yang dipilih
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    color: Colors.grey[200],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grafik yang dipilih:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                            child:
                                ChartWidget() // Pastikan ChartWidget sudah diimport
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
