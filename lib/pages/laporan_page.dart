import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _ChartData {
  final DateTime date;
  final double hargaBeli;
  final double hargaJual;

  _ChartData({
    required this.date,
    required this.hargaBeli,
    required this.hargaJual,
  });
}

class _LaporanPageState extends State<LaporanPage> {
  String? selectedCurrency;
  DateTime selectedMonth = DateTime.now();
  List<String> currencies = [];
  List<_ChartData> chartData = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stocks')
          .get(); // Target collection 'stocks'
      final allCurrencies = snapshot.docs
          .map((doc) => doc['kodeMataUang'] as String?) // Field 'kodeMataUang'
          .whereType<String>()
          .toSet()
          .toList();

      currencies.clear(); // Pastikan list kosong sebelum diisi ulang
      currencies.addAll(allCurrencies);

      setState(() {
        if (currencies.isNotEmpty && selectedCurrency == null) {
          selectedCurrency = currencies.first;
        }
      });

      if (selectedCurrency != null) {
        await _loadChartData();
      } else if (currencies.isEmpty) {
        setState(() {
          errorMessage =
              'Tidak ada data mata uang ditemukan di collection stocks.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat mata uang: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadChartData() async {
    if (selectedCurrency == null && currencies.isNotEmpty) {
      setState(() {
        selectedCurrency = currencies.first;
      });
    } else if (selectedCurrency == null && currencies.isEmpty) {
      setState(() {
        isLoading = false;
        chartData = [];
        errorMessage =
            'Pilih mata uang terlebih dahulu (tidak ada mata uang tersedia).';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      chartData = [];
    });

    try {
      DateTime start = DateTime(selectedMonth.year, selectedMonth.month);
      DateTime end = DateTime(selectedMonth.year, selectedMonth.month + 1);

      Query query = FirebaseFirestore.instance
          .collection('stocks') // Target collection 'stocks'
          .where('tanggal',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(start)) // Field 'tanggal'
          .where('tanggal', isLessThan: Timestamp.fromDate(end));

      if (selectedCurrency != null) {
        query = query.where('kodeMataUang',
            isEqualTo: selectedCurrency); // Field 'kodeMataUang'
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Mata uang belum dipilih.';
        });
        return;
      }

      final snapshot = await query.orderBy('tanggal').get();
      final grouped = <DateTime, List<DocumentSnapshot>>{};

      for (var doc in snapshot.docs) {
        final timestamp = doc['tanggal'] as Timestamp?; // Field 'tanggal'
        if (timestamp == null) continue;
        final date = DateTime(
          timestamp.toDate().year,
          timestamp.toDate().month,
          timestamp.toDate().day,
        );
        grouped.putIfAbsent(date, () => []).add(doc);
      }

      final List<_ChartData> result = [];
      grouped.forEach((date, docs) {
        double totalHargaBeli = 0;
        double totalHargaJual = 0;
        int countBeli = 0;
        int countJual = 0;

        for (var doc in docs) {
          final hargaBeli =
              (doc['hargaBeli'] ?? 0).toDouble(); // Field 'hargaBeli'
          final hargaJual =
              (doc['hargaJual'] ?? 0).toDouble(); // Field 'hargaJual'

          if (doc['hargaBeli'] != null) {
            totalHargaBeli += hargaBeli;
            countBeli++;
          }
          if (doc['hargaJual'] != null) {
            totalHargaJual += hargaJual;
            countJual++;
          }
        }

        // Menggunakan total harga. Jika ingin rata-rata, gunakan baris di bawah:
        // double avgHargaBeli = countBeli > 0 ? totalHargaBeli / countBeli : 0;
        // double avgHargaJual = countJual > 0 ? totalHargaJual / countJual : 0;

        result.add(
          _ChartData(
            date: date,
            hargaBeli: totalHargaBeli, // atau avgHargaBeli
            hargaJual: totalHargaJual, // atau avgHargaJual
          ),
        );
      });
      result.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        chartData = result;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data harga dari stocks: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
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
      await _loadChartData();
    }
  }

  Widget _buildHargaBeliJualChart() {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat.d(),
        intervalType: DateTimeIntervalType.days,
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Harga'),
        numberFormat:
            NumberFormat.compactSimpleCurrency(locale: 'id_ID', name: ''),
      ),
      title: ChartTitle(text: 'Grafik Harga Beli dan Jual Harian'),
      legend: const Legend(isVisible: true, position: LegendPosition.bottom),
      tooltipBehavior: TooltipBehavior(
          enable: true, header: '', canShowMarker: false, shared: true),
      series: <CartesianSeries<_ChartData, DateTime>>[
        LineSeries<_ChartData, DateTime>(
          name: 'Harga Beli',
          dataSource: chartData,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.hargaBeli,
          color: Colors.blue,
          markerSettings: const MarkerSettings(isVisible: true),
          emptyPointSettings: EmptyPointSettings(mode: EmptyPointMode.drop),
        ),
        LineSeries<_ChartData, DateTime>(
          name: 'Harga Jual',
          dataSource: chartData,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.hargaJual,
          color: Colors.red,
          markerSettings: const MarkerSettings(isVisible: true),
          emptyPointSettings: EmptyPointSettings(mode: EmptyPointMode.drop),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM('id_ID').format(selectedMonth);
    // final screenWidth = MediaQuery.of(context).size.width; // Tidak lagi digunakan secara langsung untuk logic ini
    // final bool isVeryWideScreenForTableCentering = screenWidth > 900; // Tidak lagi digunakan untuk keputusan ini

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
    } else if (chartData.isEmpty) {
      mainContent = const Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tidak ada data harga untuk periode dan mata uang terpilih.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else {
      // Lebar maksimum tabel, sesuaikan jika perlu agar nyaman di mobile dan tetap baik di web.
      const double maxTableSectionWidth = 700.0;

      // Kolom untuk judul rekap dan tabel data.
      // CrossAxisAlignment.start agar judul rata kiri di dalam ConstrainedBox.
      Widget recapColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekapitulasi Harga Harian',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingRowColor: MaterialStateColor.resolveWith(
                  (states) => Theme.of(context).colorScheme.primaryContainer),
              columns: const [
                DataColumn(
                    label: Text('Tanggal',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Harga Beli',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true),
                DataColumn(
                    label: Text('Harga Jual',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true),
              ],
              rows: chartData.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text(
                        DateFormat('dd MMM yy', 'id_ID').format(data.date))),
                    DataCell(Text(NumberFormat.currency(
                            locale: 'id_ID', symbol: '', decimalDigits: 2)
                        .format(data.hargaBeli))),
                    DataCell(Text(NumberFormat.currency(
                            locale: 'id_ID', symbol: '', decimalDigits: 2)
                        .format(data.hargaJual))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      );

      // Selalu bungkus bagian rekapitulasi dengan Align dan ConstrainedBox
      // untuk membuatnya di tengah dengan lebar maksimum yang ditentukan.
      Widget finalRecapSection = Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxTableSectionWidth),
          child: recapColumn,
        ),
      );

      mainContent = Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // Agar Align (dan chart) mengambil lebar penuh
            children: [
              SizedBox(height: 350, child: _buildHargaBeliJualChart()),
              const SizedBox(height: 24),
              finalRecapSection, // Bagian rekapitulasi yang sekarang selalu di tengah
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Harga Beli & Jual'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Mata Uang',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    value: selectedCurrency,
                    hint: const Text('Pilih Mata Uang'),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCurrency = value);
                        _loadChartData();
                      }
                    },
                    items: currencies.map((code) {
                      return DropdownMenuItem(value: code, child: Text(code));
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _selectMonth(context),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(monthLabel),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            mainContent,
          ],
        ),
      ),
    );
  }
}
