import 'package:flutter/material.dart';
import '../util/stok_service.dart';
import '../models/models_stok.dart';

class KursStockWidget extends StatefulWidget {
  const KursStockWidget({super.key});

  @override
  State<KursStockWidget> createState() => _StockWidgetState();
}

class _StockWidgetState extends State<KursStockWidget> {
  final StokService _stockService = StokService(); // Perbaiki nama class
  List<StockPublic> _stocks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    try {
      final data = await _stockService.getAllStocks();
      setState(() {
        _stocks = data.data; // akses list dari StocksPublic
        _loading = false;
      });
    } catch (e) {
      print('Error loading stocks: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Stok Mata Uang',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Kode')),
                  DataColumn(label: Text('Stok')),
                  DataColumn(label: Text('Beli')),
                  DataColumn(label: Text('Jual')),
                ],
                rows: _stocks.map((stock) {
                  return DataRow(
                    cells: [
                      DataCell(Text(stock.kodeMataUang)),
                      DataCell(Text(stock.jumlahStok.toString())),
                      DataCell(Text(stock.hargaBeli.toString())),
                      DataCell(Text(stock.hargaJual.toString())),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
  }
}
