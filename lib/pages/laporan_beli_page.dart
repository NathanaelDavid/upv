import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:upv/util/currency_service.dart';
import 'package:upv/util/report_service.dart';

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
  final _currencyService = CurrencyService();
  final _reportService = ReportService();

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
      final currenciesData = await _currencyService.getAllCurrencies();
      final currenciesList =
          currenciesData.map((currency) => currency.kode).toSet().toList();

      setState(() {
        currencies.addAll(currenciesList);
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
      if (selectedCurrency != null) {
        final startDate = DateTime(selectedMonth.year, selectedMonth.month);
        final endDate = DateTime(selectedMonth.year, selectedMonth.month + 1);
        final startDateString = DateFormat('yyyy-MM-dd').format(startDate);
        final endDateString = DateFormat('yyyy-MM-dd').format(endDate);
        final reportData = await _reportService.getReports(
            selectedCurrency!, "purchases", startDateString, endDateString);

        final List<_ChartData> result = reportData.map((data) {
          return _ChartData(
            date: DateTime.parse(data.date),
            avgHarga: data.totalJumlahBarang.toDouble() /
                data.totalNominal.toDouble(),
            totalNominal: data.totalNominal.toDouble(),
            jumlahBarang: data.totalJumlahBarang.toDouble(),
          );
        }).toList();

        setState(() {
          chartData = result;
        });
      }
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
      appBar: AppBar(title: const Text('Laporan Pembelian')),
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
              const Text('Tidak ada data pembelian.')
            else ...[
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: SfCartesianChart(
                        primaryXAxis: DateTimeAxis(),
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(text: 'Kurs'),
                          name: 'HargaAxis',
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
                        title: ChartTitle(text: 'Grafik Pembelian'),
                        legend: const Legend(isVisible: true),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries<_ChartData, DateTime>>[
                          LineSeries<_ChartData, DateTime>(
                            name: 'Kurs',
                            dataSource: chartData,
                            xValueMapper: (data, _) => data.date,
                            yValueMapper: (data, _) => data.avgHarga,
                            yAxisName: 'HargaAxis',
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
                        title: ChartTitle(text: 'Grafik Stok Pembelian'),
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
                'Rekapitulasi Transaksi Pembelian',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(label: Text('Kurs')),
                      DataColumn(label: Text('Total Nominal (Rp)')),
                      DataColumn(label: Text('Jumlah Barang')),
                    ],
                    rows: chartData.map((data) {
                      return DataRow(
                        cells: [
                          DataCell(
                              Text(DateFormat('dd MMM').format(data.date))),
                          DataCell(Text(data.avgHarga.toStringAsFixed(2))),
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
