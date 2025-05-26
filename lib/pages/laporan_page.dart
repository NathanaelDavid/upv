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
      final snapshot =
          await FirebaseFirestore.instance.collection('stocks').get();
      final allCurrencies = snapshot.docs
          .map((doc) => doc['kodeMataUang'] as String?)
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

      // Create query for fetching data from Firestore based on 'stocks'
      Query query = FirebaseFirestore.instance
          .collection('stocks')
          .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('tanggal', isLessThan: Timestamp.fromDate(end));

      // Apply currency filter if a currency is selected
      if (selectedCurrency != null) {
        query = query.where('kodeMataUang', isEqualTo: selectedCurrency);
      }

      final snapshot = await query.orderBy('tanggal').get();

      final grouped = <DateTime, List<DocumentSnapshot>>{};

      for (var doc in snapshot.docs) {
        final timestamp = doc['tanggal'] as Timestamp?;
        if (timestamp == null) continue;
        final date = DateTime(timestamp.toDate().year, timestamp.toDate().month,
            timestamp.toDate().day);
        grouped.putIfAbsent(date, () => []).add(doc);
      }

      final List<_ChartData> result = [];
      grouped.forEach((date, docs) {
        double totalHargaBeli = 0;
        double totalHargaJual = 0;

        for (var doc in docs) {
          final hargaBeli = (doc['hargaBeli'] ?? 0).toDouble();
          final hargaJual = (doc['hargaJual'] ?? 0).toDouble();

          totalHargaBeli += hargaBeli;
          totalHargaJual += hargaJual;
        }

        result.add(
          _ChartData(
            date: date,
            hargaBeli: totalHargaBeli,
            hargaJual: totalHargaJual,
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
      appBar: AppBar(
        title: const Text('Laporan Harga Beli dan Jual'),
        centerTitle: true,
      ),
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
              const Text('Tidak ada data harga beli dan jual.')
            else ...[
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: SfCartesianChart(
                        primaryXAxis: DateTimeAxis(),
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(text: 'Harga Beli'),
                        ),
                        title: ChartTitle(text: 'Grafik Harga Beli'),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries<_ChartData, DateTime>>[
                          LineSeries<_ChartData, DateTime>(
                            name: 'Harga Beli',
                            dataSource: chartData,
                            xValueMapper: (data, _) => data.date,
                            yValueMapper: (data, _) => data.hargaBeli,
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
                          title: AxisTitle(text: 'Harga Jual'),
                        ),
                        title: ChartTitle(text: 'Grafik Harga Jual'),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries<_ChartData, DateTime>>[
                          LineSeries<_ChartData, DateTime>(
                            name: 'Harga Jual',
                            dataSource: chartData,
                            xValueMapper: (data, _) => data.date,
                            yValueMapper: (data, _) => data.hargaJual,
                            markerSettings:
                                const MarkerSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rekapitulasi Harga Beli dan Jual',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(label: Text('Harga Beli')),
                      DataColumn(label: Text('Harga Jual')),
                    ],
                    rows: chartData.map((data) {
                      return DataRow(
                        cells: [
                          DataCell(
                              Text(DateFormat('dd MMM').format(data.date))),
                          DataCell(Text(data.hargaBeli.toStringAsFixed(2))),
                          DataCell(Text(data.hargaJual.toStringAsFixed(2))),
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
