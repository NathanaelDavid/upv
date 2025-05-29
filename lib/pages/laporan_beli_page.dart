import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class LaporanBeliPage extends StatefulWidget {
  const LaporanBeliPage({super.key});

  @override
  State<LaporanBeliPage> createState() => _LaporanBeliPageState();
}

class _ChartData {
  final DateTime date;
  final double avgHarga;
  final double totalNominal;
  final double jumlahBarang;

  _ChartData({
    required this.date,
    required this.avgHarga,
    required this.totalNominal,
    required this.jumlahBarang,
  });
}

class _LaporanBeliPageState extends State<LaporanBeliPage> {
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
      final snapshot =
          await FirebaseFirestore.instance.collection('transaksi').get();
      final allCurrencies = snapshot.docs
          .map((doc) => doc['kode_mata_uang'] as String?)
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
          errorMessage = 'Tidak ada data mata uang ditemukan.';
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
          .collection('transaksi')
          .where('kode_transaksi', isEqualTo: 'Beli')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end));

      if (selectedCurrency != null) {
        query = query.where('kode_mata_uang', isEqualTo: selectedCurrency);
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Mata uang belum dipilih.';
        });
        return;
      }

      final snapshot = await query.orderBy('timestamp').get();
      final grouped = <DateTime, List<DocumentSnapshot>>{};

      for (var doc in snapshot.docs) {
        final timestamp = doc['timestamp'] as Timestamp?;
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
        double totalNominal = 0;
        double totalHarga = 0;
        double totalQty = 0;
        int count = 0;

        for (var doc in docs) {
          final harga = (doc['harga'] ?? 0).toDouble();
          final nominal = (doc['total_nominal'] ?? 0).toDouble();
          final qty = (doc['jumlah_barang'] ?? 0).toDouble();

          totalHarga += harga;
          totalNominal += nominal;
          totalQty += qty;
          count++;
        }

        result.add(
          _ChartData(
            date: date,
            avgHarga: count > 0 ? totalHarga / count : 0,
            totalNominal: totalNominal,
            jumlahBarang: totalQty,
          ),
        );
      });
      result.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        chartData = result;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data: $e';
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
      helpText: 'Pilih Bulan',
      fieldHintText: 'Bulan/Tahun',
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
      await _loadChartData();
    }
  }

  Widget _buildKursAndNominalChart() {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat.d(),
        intervalType: DateTimeIntervalType.days,
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Kurs'),
        name: 'HargaAxis',
        numberFormat:
            NumberFormat.compactSimpleCurrency(locale: 'id_ID', name: ''),
      ),
      axes: <ChartAxis>[
        NumericAxis(
          name: 'NominalAxis',
          opposedPosition: true,
          title: AxisTitle(text: 'Total Nominal (Rp)'),
          numberFormat: NumberFormat.compactSimpleCurrency(
              locale: 'id_ID', decimalDigits: 0),
        ),
      ],
      title: ChartTitle(text: 'Grafik Kurs & Nominal'),
      legend: const Legend(isVisible: true, position: LegendPosition.bottom),
      tooltipBehavior:
          TooltipBehavior(enable: true, header: '', canShowMarker: false),
      series: <CartesianSeries<_ChartData, DateTime>>[
        LineSeries<_ChartData, DateTime>(
          name: 'Kurs',
          dataSource: chartData,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.avgHarga,
          yAxisName: 'HargaAxis',
          markerSettings: const MarkerSettings(isVisible: true),
          emptyPointSettings: EmptyPointSettings(mode: EmptyPointMode.drop),
        ),
        LineSeries<_ChartData, DateTime>(
          name: 'Total Nominal',
          dataSource: chartData,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.totalNominal,
          yAxisName: 'NominalAxis',
          markerSettings: const MarkerSettings(isVisible: true),
          emptyPointSettings: EmptyPointSettings(mode: EmptyPointMode.drop),
        ),
      ],
    );
  }

  Widget _buildStokChart() {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat.d(),
        intervalType: DateTimeIntervalType.days,
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Jumlah Barang'),
        numberFormat: NumberFormat.compact(),
      ),
      title: ChartTitle(text: 'Grafik Stok Pembelian'),
      legend: const Legend(isVisible: true, position: LegendPosition.bottom),
      tooltipBehavior:
          TooltipBehavior(enable: true, header: '', canShowMarker: false),
      series: <CartesianSeries<_ChartData, DateTime>>[
        ColumnSeries<_ChartData, DateTime>(
          name: 'Jumlah Barang',
          dataSource: chartData,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.jumlahBarang,
          dataLabelSettings: const DataLabelSettings(
              isVisible: true, labelAlignment: ChartDataLabelAlignment.top),
          emptyPointSettings: EmptyPointSettings(mode: EmptyPointMode.drop),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM('id_ID').format(selectedMonth);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 700;
    // Pertimbangkan breakpoint yang lebih besar untuk "web layar lebar" jika diperlukan, misal > 1000
    final bool isVeryWideScreenForTableCentering = screenWidth > 900;

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
              'Tidak ada data pembelian untuk periode dan mata uang terpilih.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else {
      // Batas lebar maksimum untuk tabel rekapitulasi di layar lebar
      const double maxTableSectionWidth = 800.0;

      // Widget untuk kolom rekapitulasi (judul + tabel)
      Widget recapColumn = Column(
        // Jika veryWide, judul align start. Jika tidak, judul stretch.
        crossAxisAlignment: isVeryWideScreenForTableCentering
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Rekapitulasi Transaksi Pembelian',
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
                    label: Text('Kurs',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true),
                DataColumn(
                    label: Text('Total Nominal (Rp)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true),
                DataColumn(
                    label: Text('Jumlah Barang',
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
                        .format(data.avgHarga))),
                    DataCell(Text(NumberFormat.currency(
                            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                        .format(data.totalNominal))),
                    DataCell(Text(NumberFormat.decimalPattern('id_ID')
                        .format(data.jumlahBarang))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      );

      // Bungkus kolom rekapitulasi jika layar sangat lebar untuk centering
      Widget finalRecapSection;
      if (isVeryWideScreenForTableCentering) {
        finalRecapSection = Align(
          alignment: Alignment.center, // Pusatkan ConstrainedBox
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxTableSectionWidth),
            child:
                recapColumn, // Kolom rekapitulasi (judul+tabel) akan berada di dalam box ini
          ),
        );
      } else {
        finalRecapSection =
            recapColumn; // Tampilan normal (stretch) untuk layar yang tidak terlalu lebar
      }

      mainContent = Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // Stretch children like charts and Align
            children: [
              // Bagian Grafik
              isWideScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: SizedBox(
                                height: 350,
                                child: _buildKursAndNominalChart())),
                        const SizedBox(width: 16),
                        Expanded(
                            child: SizedBox(
                                height: 350, child: _buildStokChart())),
                      ],
                    )
                  : Column(
                      children: [
                        SizedBox(
                            height: 350, child: _buildKursAndNominalChart()),
                        const SizedBox(height: 16),
                        SizedBox(height: 350, child: _buildStokChart()),
                      ],
                    ),
              const SizedBox(height: 24),
              // Bagian Rekapitulasi Transaksi (sudah di-handle untuk centering)
              finalRecapSection,
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pembelian'),
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
