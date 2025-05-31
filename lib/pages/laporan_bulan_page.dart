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

  final NumberFormat formatter = NumberFormat.decimalPattern('id_ID');
  final NumberFormat currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
        final data = doc.data();
        final mataUang = data['kode_mata_uang'] as String?;
        final jenis = data['kode_transaksi'] as String?;

        if (mataUang == null || jenis == null) {
          print(
              'Data transaksi tidak lengkap (missing mataUang/jenis): ${doc.id}');
          continue;
        }

        final jumlah = (data['jumlah_barang'] ?? 0).toDouble();
        final nominal = (data['total_nominal'] ?? 0).toDouble();

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
        final totalBeli = data['totalBeli'] as double;
        final totalJual = data['totalJual'] as double;
        return {
          'kode': kode,
          'totalBeli': totalBeli,
          'nominalBeli': data['nominalBeli'] as double,
          'totalJual': totalJual,
          'nominalJual': data['nominalJual'] as double,
          'stokAkhir': totalBeli - totalJual,
        };
      }).toList();

      rekapData
          .sort((a, b) => (a['kode'] as String).compareTo(b['kode'] as String));

      setState(() {});
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data bulanan: $e';
        print('Error _loadData LaporanBulanPage: $e');
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
      helpText: 'Pilih Bulan Laporan',
      fieldHintText: 'Bulan/Tahun',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobileSize = screenWidth < 600;

    Widget mainContent;

    if (isLoading) {
      mainContent =
          const Expanded(child: Center(child: CircularProgressIndicator()));
    } else if (errorMessage != null) {
      mainContent = Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else if (rekapData.isEmpty) {
      mainContent = const Expanded(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Tidak ada data transaksi untuk bulan ini.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else {
      // Perlebar maxTableSectionWidth untuk layar yang lebih besar
      const double maxTableSectionWidth = 1000.0;

      // Properti tabel yang kondisional berdasarkan ukuran layar
      // Perlebar columnSpacing dan cellPadding untuk non-mobile
      final double currentColumnSpacing =
          isMobileSize ? 10.0 : 24.0; // Diperlebar untuk non-mobile
      final double currentHeadingRowHeight = isMobileSize ? 48.0 : 56.0;
      final double currentDataRowMinHeight = isMobileSize ? 32.0 : 38.0;
      final double currentDataRowMaxHeight = isMobileSize ? 42.0 : 48.0;

      final TextStyle headingStyle = TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: isMobileSize
            ? 14
            : 16, // Ukuran font non-mobile bisa sedikit lebih besar
      );
      final TextStyle cellStyle = TextStyle(
        fontSize: isMobileSize
            ? 11
            : 12, // Ukuran font non-mobile bisa sedikit lebih besar
      );
      // Perlebar cellPadding horizontal untuk non-mobile
      final EdgeInsets cellPadding = isMobileSize
          ? const EdgeInsets.symmetric(horizontal: 11.0, vertical: 5.0)
          : const EdgeInsets.symmetric(
              horizontal: 12.0, vertical: 6.0); // Diperlebar untuk non-mobile

      Widget recapColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekapitulasi Transaksi Bulanan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: currentColumnSpacing,
              headingRowHeight: currentHeadingRowHeight,
              dataRowMinHeight: currentDataRowMinHeight,
              dataRowMaxHeight: currentDataRowMaxHeight,
              headingTextStyle: headingStyle,
              headingRowColor: WidgetStateColor.resolveWith((states) =>
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3)),
              columns: [
                const DataColumn(label: Text('Mata\nUang')),
                DataColumn(label: const Text('Jml\nBeli'), numeric: true),
                DataColumn(
                    label: const Text('Nominal Beli\n(Rp)'), numeric: true),
                DataColumn(label: const Text('Jml\nJual'), numeric: true),
                DataColumn(
                    label: const Text('Nominal Jual\n(Rp)'), numeric: true),
                DataColumn(label: const Text('Stok\nAkhir'), numeric: true),
              ],
              rows: rekapData.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Padding(
                        padding: cellPadding,
                        child: Text(data['kode'] as String, style: cellStyle))),
                    DataCell(Padding(
                        padding: cellPadding,
                        child: Text(formatter.format(data['totalBeli']),
                            textAlign: TextAlign.right, style: cellStyle))),
                    DataCell(Padding(
                        padding: cellPadding,
                        child: Text(
                            currencyFormatter.format(data['nominalBeli']),
                            textAlign: TextAlign.right,
                            style: cellStyle))),
                    DataCell(Padding(
                        padding: cellPadding,
                        child: Text(formatter.format(data['totalJual']),
                            textAlign: TextAlign.right, style: cellStyle))),
                    DataCell(Padding(
                        padding: cellPadding,
                        child: Text(
                            currencyFormatter.format(data['nominalJual']),
                            textAlign: TextAlign.right,
                            style: cellStyle))),
                    DataCell(Padding(
                        padding: cellPadding,
                        child: Text(formatter.format(data['stokAkhir']),
                            textAlign: TextAlign.right, style: cellStyle))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      );

      Widget finalRecapSection = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxTableSectionWidth),
          child: recapColumn,
        ),
      );

      mainContent = Expanded(
        child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                finalRecapSection,
              ],
            )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Bulanan'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _selectMonth(context),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(monthLabel),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            mainContent,
          ],
        ),
      ),
    );
  }
}
