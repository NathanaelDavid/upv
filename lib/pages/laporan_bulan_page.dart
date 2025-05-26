import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LaporanBulanPage extends StatefulWidget {
  const LaporanBulanPage({super.key});

  @override
  State<LaporanBulanPage> createState() => _LaporanBulanPageState();
}

class _LaporanBulanPageState extends State<LaporanBulanPage> {
  DateTime selectedMonth = DateTime.now();
  bool isLoading = false;
  String? errorMessage;

  List<Map<String, dynamic>> rekapData = [];

  final NumberFormat formatter =
      NumberFormat.decimalPattern('id'); // Format ribuan

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      rekapData = [];
    });

    try {
      final start = DateTime(selectedMonth.year, selectedMonth.month);
      final end = DateTime(selectedMonth.year, selectedMonth.month + 1);

      final transaksiSnapshot = await FirebaseFirestore.instance
          .collection('transaksi')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end))
          .get();

      final transaksiData = <String, Map<String, dynamic>>{};

      for (var doc in transaksiSnapshot.docs) {
        final mataUang = doc['kode_mata_uang'];
        final jenis = doc['kode_transaksi'];
        final jumlah = (doc['jumlah_barang'] ?? 0).toDouble();
        final nominal = (doc['total_nominal'] ?? 0).toDouble();

        if (!transaksiData.containsKey(mataUang)) {
          transaksiData[mataUang] = {
            'totalBeli': 0.0,
            'nominalBeli': 0.0,
            'totalJual': 0.0,
            'nominalJual': 0.0,
          };
        }

        if (jenis == 'Beli') {
          transaksiData[mataUang]!['totalBeli'] += jumlah;
          transaksiData[mataUang]!['nominalBeli'] += nominal;
        } else if (jenis == 'Jual') {
          transaksiData[mataUang]!['totalJual'] += jumlah;
          transaksiData[mataUang]!['nominalJual'] += nominal;
        }
      }

      rekapData = transaksiData.entries.map((entry) {
        final kode = entry.key;
        final data = entry.value;
        final totalBeli = data['totalBeli'];
        final totalJual = data['totalJual'];
        return {
          'kode': kode,
          'totalBeli': totalBeli,
          'nominalBeli': data['nominalBeli'],
          'totalJual': totalJual,
          'nominalJual': data['nominalJual'],
          'stokAkhir': totalBeli - totalJual,
        };
      }).toList();

      setState(() {});
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih Bulan',
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM('id_ID').format(selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Bulanan'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selectMonth(context),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(monthLabel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            if (isLoading)
              const CircularProgressIndicator()
            else if (rekapData.isEmpty)
              const Text('Tidak ada data bulan ini.')
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Mata Uang')),
                      DataColumn(label: Text('Jumlah Beli')),
                      DataColumn(label: Text('Nominal Beli')),
                      DataColumn(label: Text('Jumlah Jual')),
                      DataColumn(label: Text('Nominal Jual')),
                      DataColumn(label: Text('Stok Akhir')),
                    ],
                    rows: rekapData.map((data) {
                      return DataRow(
                        cells: [
                          DataCell(Text(data['kode'])),
                          DataCell(Text(formatter.format(data['totalBeli']))),
                          DataCell(Text(formatter.format(data['nominalBeli']))),
                          DataCell(Text(formatter.format(data['totalJual']))),
                          DataCell(Text(formatter.format(data['nominalJual']))),
                          DataCell(Text(formatter.format(data['stokAkhir']))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
