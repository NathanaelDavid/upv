import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Timestamp if models use it directly
import '../util/stok_service.dart';
import '../util/transaksi_service.dart';
import '../models/models_stok.dart'; // Should contain StockPublic with copyWith
import '../models/transaksi_models.dart'; // Should contain TransaksiPublic

class KursStockWidget extends StatefulWidget {
  const KursStockWidget({super.key});

  @override
  State<KursStockWidget> createState() => _KursStockWidgetState();
}

class _KursStockWidgetState extends State<KursStockWidget> {
  final StokService _stockService = StokService();
  final TransaksiService _transaksiService = TransaksiService();
  Map<String, StockPublic> _finalStockMap = {};
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      // 1. Fetch all master stock price data (contains hargaBeli, hargaJual, tanggal)
      // The StockPublic objects from getAllStocks() will have jumlahStok initialized to 0.0 by default.
      final stockData = await _stockService.getAllStocks();

      // 2. Fetch all transaction data
      final List<TransaksiPublic> transaksiData =
          await _transaksiService.getAllTransaksi();

      // 3. Create a map to hold the latest master stock data for each currency code.
      // Key: kodeMataUang, Value: StockPublic object with latest price info.
      // The jumlahStok in these StockPublic objects will be calculated next.
      Map<String, StockPublic> latestMasterStockMap = {};

      for (var masterStock in stockData.data) {
        final kode = masterStock.kodeMataUang;
        // If we haven't seen this currency, or if this entry is newer, update.
        if (!latestMasterStockMap.containsKey(kode) ||
            masterStock.tanggal
                .toDate()
                .isAfter(latestMasterStockMap[kode]!.tanggal.toDate())) {
          // Store the master stock. Its jumlahStok is still the initial default (e.g., 0.0).
          latestMasterStockMap[kode] = masterStock;
        }
      }

      // 4. Now, iterate through transactions to calculate and update jumlahStok
      // for each currency in our latestMasterStockMap.
      for (var transaksi in transaksiData) {
        final kode = transaksi.kodeMataUang;
        final jumlah = transaksi.jumlah; // Assuming this is double
        final jenis = transaksi.jenis; // Assuming this is 'beli' or 'jual'

        if (latestMasterStockMap.containsKey(kode)) {
          var currentStockInfo = latestMasterStockMap[kode]!;

          // Start with the already accumulated stock for this currency code in the map
          double newAccumulatedStock = currentStockInfo.jumlahStok;

          if (jenis == 'beli') {
            newAccumulatedStock += jumlah;
          } else if (jenis == 'jual') {
            newAccumulatedStock -= jumlah;
          }

          // Update the StockPublic object in the map with the new accumulated jumlahStok
          latestMasterStockMap[kode] = currentStockInfo.copyWith(
            jumlahStok: newAccumulatedStock,
          );
        }
        // Optional: Handle transactions for currencies not in master stock data?
        // For now, we only update stock for currencies that have a master price entry.
      }

      setState(() {
        _finalStockMap = latestMasterStockMap;
        _loading = false;
      });
    } catch (e) {
      print('Error loading data for KursStockWidget: $e');
      setState(() {
        _errorMessage = "Gagal memuat data: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_finalStockMap.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data kurs atau stok untuk ditampilkan.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      // Added SingleChildScrollView for responsiveness
      scrollDirection: Axis.vertical,
      child: Padding(
        // Added padding for better aesthetics
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Kurs & Stok Mata Uang',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              // Ensure DataTable fits width
              width: double.infinity,
              child: DataTable(
                columnSpacing: 20, // Adjust spacing
                headingRowColor: WidgetStateColor.resolveWith(
                    (states) => const Color.fromARGB(88, 206, 229, 248)),
                columns: const [
                  DataColumn(
                      label: Text('Kode',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text('Stok',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true),
                  DataColumn(
                      label: Text('Beli',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true),
                  DataColumn(
                      label: Text('Jual',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true),
                ],
                rows: _finalStockMap.values.map((stock) {
                  return DataRow(
                    cells: [
                      DataCell(Text(stock.kodeMataUang)),
                      DataCell(Text(stock.jumlahStok.toStringAsFixed(2))),
                      DataCell(Text(stock.hargaBeli.toStringAsFixed(2))),
                      DataCell(Text(stock.hargaJual.toStringAsFixed(2))),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              // Added a refresh button
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}
