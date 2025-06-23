import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Import PDF generation packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // Masih dibutuhkan untuk pw.MemoryImage dan lainnya
import 'package:path_provider/path_provider.dart'; // Diperlukan untuk path penyimpanan
import 'dart:io'; // Diperlukan untuk File

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

  // --- FUNGSI BARU: _generatePdf() ---
  Future<void> _generatePdf() async {
    setState(() {
      isLoading = true; // Set loading saat membuat PDF
    });

    try {
      final doc = pw.Document();
      final monthLabel = DateFormat.yMMMM('id_ID').format(selectedMonth);

      // Siapkan data untuk tabel PDF
      final List<List<String>> tableData = [];
      // Headers
      tableData.add([
        'Mata Uang',
        'Jml Beli',
        'Nominal Beli (Rp)',
        'Jml Jual',
        'Nominal Jual (Rp)',
        'Stok Akhir'
      ]);

      // Rows
      for (var data in rekapData) {
        tableData.add([
          (data['kode'] as String).toUpperCase(),
          formatter.format(data['totalBeli']),
          currencyFormatter.format(data['nominalBeli']),
          formatter.format(data['totalJual']),
          currencyFormatter.format(data['nominalJual']),
          formatter.format(data['stokAkhir']),
        ]);
      }

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.portrait,
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Text(
                  'Laporan Rekapitulasi Transaksi Bulanan',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  'Bulan: $monthLabel',
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Table.fromTextArray(
                headers: tableData[0], // Gunakan baris pertama sebagai header
                data: tableData.sublist(1), // Sisanya adalah data
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9, // Sesuaikan ukuran font header untuk PDF
                  color: PdfColors.black,
                ),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerRight,
                cellPadding: const pw.EdgeInsets.all(4),
                cellStyle: const pw.TextStyle(
                  fontSize: 8, // Sesuaikan ukuran font cell untuk PDF
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5), // Mata Uang
                  1: const pw.FlexColumnWidth(1.5), // Jml Beli
                  2: const pw.FlexColumnWidth(2), // Nominal Beli
                  3: const pw.FlexColumnWidth(1.5), // Jml Jual
                  4: const pw.FlexColumnWidth(2), // Nominal Jual
                  5: const pw.FlexColumnWidth(1.5), // Stok Akhir
                },
              ),
            ];
          },
        ),
      );

      // --- LOGIKA BARU: Menyimpan PDF ke perangkat ---
      final String fileName =
          "laporan_bulanan_${monthLabel.replaceAll(' ', '_').toLowerCase()}.pdf";
      Directory? directory;

      if (Theme.of(context).platform == TargetPlatform.android) {
        // Untuk Android, coba gunakan getExternalStorageDirectory() atau getDownloadsDirectory()
        // getApplicationDocumentsDirectory() juga bisa, tapi lebih privat
        directory =
            await getExternalStorageDirectory(); // Atau getDownloadsDirectory()
        // Pastikan Anda menangani izin penyimpanan di AndroidManifest.xml
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Untuk Web, Desktop (Linux, Windows, macOS)
        // Printing.sharePdf() atau Printing.layoutPdf() mungkin lebih sesuai
        // Jika ingin menyimpan, ini akan memicu dialog unduhan browser di web
        // atau menyimpan ke direktori sementara di desktop.
        // Untuk web, langsung Printing.sharePdf() sudah cukup memicu download di browser.
        await Printing.sharePdf(bytes: await doc.save(), filename: fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF $fileName berhasil dibuat.')),
          );
        }
        return; // Keluar dari fungsi karena sudah ditangani
      }

      if (directory != null) {
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(await doc.save());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF berhasil disimpan ke: $filePath'),
              action: SnackBarAction(
                label: 'Buka',
                onPressed: () {
                  // Tambahkan logika untuk membuka file atau folder
                  // Ini bisa kompleks dan bergantung pada platform.
                  // Misalnya: open_filex package atau platform-specific code
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Gagal mendapatkan direktori penyimpanan.')),
          );
        }
      }
    } catch (e) {
      print('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
      const double maxTableSectionWidth = 1000.0;

      final double currentColumnSpacing = isMobileSize ? 10.0 : 24.0;
      final double currentHeadingRowHeight = isMobileSize ? 48.0 : 56.0;
      final double currentDataRowMinHeight = isMobileSize ? 32.0 : 38.0;
      final double currentDataRowMaxHeight = isMobileSize ? 42.0 : 48.0;

      final TextStyle headingStyle = TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: isMobileSize ? 14 : 16,
      );
      final TextStyle cellStyle = TextStyle(
        fontSize: isMobileSize ? 11 : 12,
      );
      final EdgeInsets cellPadding = isMobileSize
          ? const EdgeInsets.symmetric(horizontal: 11.0, vertical: 5.0)
          : const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0);

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
        actions: [
          // --- Tombol untuk membuat PDF ---
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Buat Laporan PDF',
            onPressed: rekapData.isEmpty || isLoading ? null : _generatePdf,
          ),
        ],
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
