import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp

import '../util/stok_service.dart';
import '../util/transaksi_service.dart';
import '../models/models_stok.dart';
// import '../models/models_transaksi.dart'; // Not directly used in this widget for now

class CurrencyWidget extends StatefulWidget {
  const CurrencyWidget({super.key});

  @override
  State<CurrencyWidget> createState() => _KursStockWidgetState();
}

class _KursStockWidgetState extends State<CurrencyWidget> {
  final StokService _stockService = StokService();
  final TransaksiService _transaksiService = TransaksiService();

  Map<String, StockPublic> _finalStockMap = {};
  DateTime?
      _lastOverallUpdate; // Variabel untuk melacak tanggal update terbaru keseluruhan
  bool _loading = true;

  // Mendapatkan instance Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      // Mengambil semua data stok untuk mengisi _finalStockMap
      final stockDataResponse = await _stockService.getAllStocks();

      // Data transaksi tidak digunakan di sini untuk display, jadi komentar jika tidak perlu.
      // await _transaksiService.getAllTransaksi();

      Map<String, StockPublic> groupedStockByLatestDate = {};
      for (var stock in stockDataResponse.data) {
        final kodeMataUang = stock.kodeMataUang;

        // Memastikan hanya menyimpan entri stok terbaru per mata uang
        if (!groupedStockByLatestDate.containsKey(kodeMataUang) ||
            stock.tanggal.toDate().isAfter(
                groupedStockByLatestDate[kodeMataUang]!.tanggal.toDate())) {
          groupedStockByLatestDate[kodeMataUang] = stock;
        }
      }

      // --- OPTIMASI UTAMA: Mendapatkan timestamp update terakhir secara GLOBAL dari Firestore ---
      // Query langsung Firestore untuk mendapatkan dokumen stok terbaru (limit 1)
      // Ini jauh lebih efisien daripada mengiterasi semua `stockDataResponse.data`
      // jika `stockDataResponse.data` sendiri mengambil seluruh koleksi yang besar.
      DateTime? effectiveLastUpdate;
      try {
        final lastStockSnapshot = await _firestore
            .collection('stocks')
            .orderBy('tanggal', descending: true)
            .limit(1)
            .get();

        if (lastStockSnapshot.docs.isNotEmpty) {
          final latestTimestampDoc = lastStockSnapshot.docs.first;
          final timestamp = latestTimestampDoc['tanggal'] as Timestamp?;
          if (timestamp != null) {
            effectiveLastUpdate = timestamp.toDate();
          }
        }
      } catch (e) {
        print('Error fetching latest overall stock timestamp: $e');
        // Lanjutkan tanpa timestamp jika ada error
      }
      // ---------------------------------------------------------------------------------------

      setState(() {
        _finalStockMap = groupedStockByLatestDate;
        _lastOverallUpdate =
            effectiveLastUpdate; // Set tanggal update keseluruhan
        _loading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data kurs: $e')),
        );
      }
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String lastUpdateText = _lastOverallUpdate != null
        ? 'Terakhir Diperbarui: ${DateFormat('dd MMM.yyyy, HH:mm').format(_lastOverallUpdate!)}'
        : 'Belum ada data update.';

    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Kurs Mata Uang',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Text(
                lastUpdateText,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),

              // --- PERBAIKAN: DataTable sekarang ada di dalam SingleChildScrollView untuk HORIZONTAL saja ---
              // dan akan digulirkan secara vertikal oleh ListView induk di MarketingPage.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Hanya scrolling horizontal
                child: DataTable(
                  // Tidak perlu physics atau shrinkWrap di sini karena DataTable
                  // bukanlah scrollable utama di sumbu vertikal.
                  // Ia akan mengambil tinggi yang dibutuhkan oleh semua barisnya.
                  columns: const [
                    DataColumn(label: Text('Kode')),
                    DataColumn(label: Text('Beli')),
                    DataColumn(label: Text('Jual')),
                  ],
                  rows: _finalStockMap.values.map((stock) {
                    return DataRow(
                      cells: [
                        DataCell(Text(stock.kodeMataUang.toUpperCase())),
                        DataCell(Text(stock.hargaBeli.toStringAsFixed(2))),
                        DataCell(Text(stock.hargaJual.toStringAsFixed(2))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
  }
}
