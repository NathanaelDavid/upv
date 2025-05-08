import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class LaporanJualPage extends StatefulWidget {
  const LaporanJualPage({super.key});

  @override
  State<LaporanJualPage> createState() => _LaporanJualPageState();
}

class _ChartData {
  final DateTime date;
  final double kurs;
  final double totalNominal;
  final double jumlahBarang;

  _ChartData({
    required this.date,
    required this.kurs,
    required this.totalNominal,
    required this.jumlahBarang,
  });
}

class _LaporanJualPageState extends State<LaporanJualPage> {
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

      setState(() {
        currencies.addAll(allCurrencies);
        selectedCurrency = currencies.isNotEmpty ? currencies.first : null;
      });

      await _loadChartData();
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat mata uang: $e';
      });
    }
  }

  Future<void> _loadChartData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      DateTime start = DateTime(selectedMonth.year, selectedMonth.month);
      DateTime end = DateTime(selectedMonth.year, selectedMonth.month + 1);

      Query query = FirebaseFirestore.instance
          .collection('transaksi')
          .where('kode_transaksi', isEqualTo: 'Jual')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end));

      if (selectedCurrency != null) {
        query = query.where('kode_mata_uang', isEqualTo: selectedCurrency);
      }

      final snapshot = await query.orderBy('timestamp').get();

      final grouped = <DateTime, List<DocumentSnapshot>>{};

      for (var doc in snapshot.docs) {
        final timestamp = doc['timestamp'] as Timestamp?;
        if (timestamp == null) continue;
        final date = DateTime(timestamp.toDate().year, timestamp.toDate().month,
            timestamp.toDate().day);
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
            kurs: count > 0 ? totalHarga / count : 0,
            totalNominal: totalNominal,
            jumlahBarang: totalQty,
          ),
        );
      });

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
      await _loadChartData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM().format(selectedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Penjualan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCurrency,
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            if (isLoading)
              const CircularProgressIndicator()
            else if (chartData.isEmpty)
              const Text('Tidak ada data penjualan.')
            else ...[
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: SfCartesianChart(
                        primaryXAxis: DateTimeAxis(),
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(text: 'Kurs'),
                          name: 'KursAxis',
                        ),
                        axes: <ChartAxis>[
                          NumericAxis(
                            name: 'NominalAxis',
                            opposedPosition: true,
                            title: AxisTitle(text: 'Total Nominal (Rp)'),
                          ),
                          NumericAxis(
                            name: 'QtyAxis',
                            opposedPosition: true,
                            title: AxisTitle(text: 'Jumlah Barang'),
                            plotOffset: 40,
                          ),
                        ],
                        title: ChartTitle(text: 'Grafik Penjualan'),
                        legend: const Legend(isVisible: true),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries<_ChartData, DateTime>>[
                          LineSeries<_ChartData, DateTime>(
                            name: 'Kurs',
                            dataSource: chartData,
                            xValueMapper: (data, _) => data.date,
                            yValueMapper: (data, _) => data.kurs,
                            yAxisName: 'KursAxis',
                            markerSettings:
                                const MarkerSettings(isVisible: true),
                          ),
                          LineSeries<_ChartData, DateTime>(
                            name: 'Total Nominal',
                            dataSource: chartData,
                            xValueMapper: (data, _) => data.date,
                            yValueMapper: (data, _) => data.totalNominal,
                            yAxisName: 'NominalAxis',
                            markerSettings:
                                const MarkerSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SfCartesianChart(
                        primaryXAxis: DateTimeAxis(),
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(text: 'Jumlah Barang'),
                        ),
                        title: ChartTitle(text: 'Grafik Stok Penjualan'),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries<_ChartData, DateTime>>[
                          ColumnSeries<_ChartData, DateTime>(
                            name: 'Jumlah Barang',
                            dataSource: chartData,
                            xValueMapper: (data, _) => data.date,
                            yValueMapper: (data, _) => data.jumlahBarang,
                            dataLabelSettings:
                                const DataLabelSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rekapitulasi Penjualan Harian',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(label: Text('Kurs')),
                      DataColumn(label: Text('Total Nominal')),
                      DataColumn(label: Text('Jumlah Barang')),
                    ],
                    rows: chartData.map((data) {
                      return DataRow(
                        cells: [
                          DataCell(
                              Text(DateFormat('dd MMM').format(data.date))),
                          DataCell(Text(data.kurs.toStringAsFixed(2))),
                          DataCell(Text(data.totalNominal.toStringAsFixed(2))),
                          DataCell(Text(data.jumlahBarang.toStringAsFixed(2))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
