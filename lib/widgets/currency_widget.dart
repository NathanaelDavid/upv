import 'package:flutter/material.dart';
import '../util/stok_service.dart';
import '../util/transaksi_service.dart'; // Tambahkan jika belum ada
import '../models/models_stok.dart';

class CurrencyWidget extends StatefulWidget {
  const CurrencyWidget({super.key});

  @override
  State<CurrencyWidget> createState() => _KursStockWidgetState();
}

class _KursStockWidgetState extends State<CurrencyWidget> {
  final StokService _stockService = StokService();
  final TransaksiService _transaksiService = TransaksiService(); // Tambahkan
  Map<String, StockPublic> _finalStockMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stockData = await _stockService.getAllStocks();
      final transaksiData = await _transaksiService.getAllTransaksi();

      // Gabungkan berdasarkan kode mata uang
      Map<String, StockPublic> groupedStock = {};

      for (var stock in stockData.data) {
        if (!groupedStock.containsKey(stock.kodeMataUang) ||
            stock.tanggal
                .toDate()
                .isAfter(groupedStock[stock.kodeMataUang]!.tanggal.toDate())) {
          groupedStock[stock.kodeMataUang] = stock;
        }
      }

      // Proses transaksi: beli tambah stok, jual kurangi stok
      for (var transaksi in transaksiData) {
        final kode = transaksi.kodeMataUang;
        final jumlah = transaksi.jumlah;

        if (groupedStock.containsKey(kode)) {
          var existingStock = groupedStock[kode]!;

          double updatedJumlah = existingStock.jumlahStok;
          if (transaksi.jenis == 'beli') {
            updatedJumlah += jumlah;
          } else if (transaksi.jenis == 'jual') {
            updatedJumlah -= jumlah;
          }

          groupedStock[kode] = StockPublic(
            id: existingStock.id,
            kodeMataUang: existingStock.kodeMataUang,
            jumlahStok: updatedJumlah,
            hargaBeli: existingStock.hargaBeli,
            hargaJual: existingStock.hargaJual,
            tanggal: existingStock.tanggal,
          );
        }
      }

      setState(() {
        _finalStockMap = groupedStock;
        _loading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
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
                  // DataColumn(label: Text('Stok')),
                  DataColumn(label: Text('Beli')),
                  DataColumn(label: Text('Jual')),
                ],
                rows: _finalStockMap.values.map((stock) {
                  return DataRow(
                    cells: [
                      DataCell(Text(stock.kodeMataUang)),
                      // DataCell(Text(stock.jumlahStok.toStringAsFixed(2))),
                      DataCell(Text(stock.hargaBeli.toStringAsFixed(2))),
                      DataCell(Text(stock.hargaJual.toStringAsFixed(2))),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
  }
}
