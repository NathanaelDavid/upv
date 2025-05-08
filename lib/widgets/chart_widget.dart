import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/models_stok.dart';

class ChartWidget extends StatefulWidget {
  const ChartWidget({super.key});

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  String? selectedCurrency;
  List<String> currencies = [];
  List<StockPublic> stockData = [];
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
        currencies = allCurrencies;
        selectedCurrency = currencies.isNotEmpty ? currencies.first : null;
      });

      if (selectedCurrency != null) {
        await _loadStockData(selectedCurrency!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat mata uang: $e';
      });
    }
  }

  Future<void> _loadStockData(String currencyCode) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stocks')
          .where('kodeMataUang', isEqualTo: currencyCode)
          .orderBy('tanggal')
          .get();

      final data = snapshot.docs
          .map((doc) => StockPublic.fromFirestore(doc))
          .where((item) => item.tanggal != null)
          .toList();

      setState(() {
        stockData = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data stok: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grafik Harga Mata Uang')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedCurrency,
              hint: const Text("Pilih Mata Uang"),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCurrency = value;
                  });
                  _loadStockData(value);
                }
              },
              items: currencies
                  .map((code) => DropdownMenuItem(
                        value: code,
                        child: Text(code),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: stockData.isEmpty
                    ? const Center(
                        child: Text('Tidak ada data untuk ditampilkan'))
                    : SfCartesianChart(
                        primaryXAxis: DateTimeAxis(),
                        title: ChartTitle(
                            text: 'Harga Jual & Beli - $selectedCurrency'),
                        legend: const Legend(isVisible: true),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries>[
                          LineSeries<StockPublic, DateTime>(
                            name: 'Harga Jual',
                            color: Colors.red, // Merah
                            dataSource: stockData,
                            xValueMapper: (data, _) => data.tanggal.toDate(),
                            yValueMapper: (data, _) => data.hargaJual,
                          ),
                          LineSeries<StockPublic, DateTime>(
                            name: 'Harga Beli',
                            color: Colors.blue, // Biru
                            dataSource: stockData,
                            xValueMapper: (data, _) => data.tanggal.toDate(),
                            yValueMapper: (data, _) => data.hargaBeli,
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
