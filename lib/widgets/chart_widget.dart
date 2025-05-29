import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal di tooltip jika diperlukan
import '../models/models_stok.dart'; // Pastikan path ini benar

class ChartWidget extends StatefulWidget {
  const ChartWidget({super.key});

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  String? selectedCurrency;
  List<String> currencies = [];
  List<StockPublic> stockData = [];
  bool isLoadingCurrencies = true; // Untuk loading awal daftar mata uang
  bool isLoadingChartData = false; // Untuk loading data grafik spesifik
  String? errorMessage;

  // TooltipBehavior untuk grafik
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      // Kustomisasi format tooltip
      format: 'point.x : point.y', // Default, bisa dikustomisasi lebih lanjut
      header: '', // Tidak ada header default
      canShowMarker: true,
      // Builder untuk kustomisasi tampilan tooltip sepenuhnya jika diperlukan
      // builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
      //   final StockPublic stockPoint = data as StockPublic;
      //   final String seriesName = series.name ?? '';
      //   return Container(
      //     padding: const EdgeInsets.all(10),
      //     decoration: BoxDecoration(
      //       color: Colors.white,
      //       borderRadius: BorderRadius.circular(5),
      //       boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      //     ),
      //     child: Text('$seriesName\nTanggal: ${DateFormat('dd/MM/yy').format(stockPoint.tanggal.toDate())}\nHarga: ${stockPoint.hargaJual} / ${stockPoint.hargaBeli}'),
      //   );
      // }
    );
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    if (!mounted) return;
    setState(() {
      isLoadingCurrencies = true;
      errorMessage = null;
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('stocks').get();
      if (!mounted) return;

      final allCurrencies = snapshot.docs
          .map((doc) {
            try {
              return doc.get('kodeMataUang') as String?;
            } catch (e) {
              // Tangani jika field tidak ada atau bukan string
              print("Error membaca 'kodeMataUang' dari dokumen ${doc.id}: $e");
              return null;
            }
          })
          .whereType<String>() // Hanya ambil yang berhasil di-cast ke String
          .toSet() // Ambil nilai unik
          .toList();

      allCurrencies.sort(); // Sortir mata uang

      setState(() {
        currencies = allCurrencies;
        if (currencies.isNotEmpty) {
          // Coba pertahankan selectedCurrency jika masih ada, atau pilih yang pertama
          if (selectedCurrency == null ||
              !currencies.contains(selectedCurrency)) {
            selectedCurrency = currencies.first;
          }
        } else {
          selectedCurrency = null;
        }
        isLoadingCurrencies = false;
      });

      if (selectedCurrency != null) {
        await _loadStockData(selectedCurrency!);
      } else {
        // Jika tidak ada mata uang, selesaikan loading
        if (mounted) setState(() => isLoadingCurrencies = false);
      }
    } catch (e) {
      print("Error memuat mata uang: $e");
      if (mounted) {
        setState(() {
          errorMessage = 'Gagal memuat daftar mata uang.';
          isLoadingCurrencies = false;
        });
      }
    }
  }

  Future<void> _loadStockData(String currencyCode) async {
    if (!mounted) return;
    setState(() {
      isLoadingChartData = true;
      errorMessage = null; // Reset error message spesifik untuk data stok
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stocks')
          .where('kodeMataUang', isEqualTo: currencyCode)
          .orderBy('tanggal',
              descending: false) // Urutkan dari tanggal terlama ke terbaru
          .get();
      if (!mounted) return;

      final data = snapshot.docs
          .map((doc) => StockPublic.fromFirestore(doc))
          // Pastikan tanggal tidak null dan valid sebelum konversi
          .where((item) =>
              item.tanggal.seconds >
              0) // Contoh validasi sederhana untuk Timestamp
          .toList();

      setState(() {
        stockData = data;
      });
    } catch (e) {
      print("Error memuat data stok untuk $currencyCode: $e");
      if (mounted) {
        setState(() {
          errorMessage = 'Gagal memuat data grafik untuk $currencyCode.';
          stockData = []; // Kosongkan data jika error
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingChartData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(0), // Margin diatur oleh parent (HomePage)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Grafik Harga Mata Uang',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),

            // Dropdown untuk memilih mata uang
            if (isLoadingCurrencies)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              ))
            else if (currencies.isNotEmpty)
              DropdownButtonFormField<String>(
                value: selectedCurrency,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Pilih Mata Uang',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 14.0),
                ),
                hint: const Text("Pilih Mata Uang"),
                onChanged: isLoadingChartData
                    ? null
                    : (value) {
                        // Nonaktifkan saat chart sedang loading
                        if (value != null && value != selectedCurrency) {
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
              )
            else if (errorMessage ==
                null) // Jika tidak loading dan tidak ada mata uang, dan tidak ada error utama
              const Center(child: Text("Tidak ada mata uang tersedia.")),

            const SizedBox(height: 12.0),

            // Tampilkan pesan error jika ada
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            // Area Grafik
            Expanded(
              child: isLoadingChartData
                  ? const Center(child: CircularProgressIndicator())
                  : stockData.isEmpty &&
                          !isLoadingCurrencies &&
                          errorMessage ==
                              null // Jika tidak ada data setelah load selesai dan tidak ada error
                      ? Center(
                          child: Text(
                          selectedCurrency != null
                              ? 'Tidak ada data grafik untuk $selectedCurrency.'
                              : 'Silakan pilih mata uang.',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ))
                      : SfCartesianChart(
                          primaryXAxis: DateTimeAxis(
                            dateFormat: DateFormat
                                .MMMd(), // Format tanggal di sumbu X (misal: Jan 28)
                            intervalType: DateTimeIntervalType
                                .auto, // Biarkan Syncfusion menentukan interval terbaik
                            majorGridLines: const MajorGridLines(
                                width: 0), // Sembunyikan grid utama X
                            edgeLabelPlacement: EdgeLabelPlacement
                                .shift, // Agar label tidak terpotong
                          ),
                          primaryYAxis: NumericAxis(
                            numberFormat: NumberFormat.compactSimpleCurrency(
                                locale: 'id_ID',
                                name:
                                    ''), // Format angka di sumbu Y (misal: 15K, 1M)
                            axisLine: const AxisLine(
                                width: 0), // Sembunyikan garis sumbu Y
                            majorTickLines: const MajorTickLines(
                                size: 0), // Sembunyikan tick Y
                          ),
                          title: ChartTitle(
                              text: selectedCurrency != null
                                  ? 'Harga Jual & Beli - $selectedCurrency'
                                  : 'Grafik Harga',
                              textStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: primaryColor.withOpacity(0.8))),
                          legend: const Legend(
                            isVisible: true,
                            overflowMode: LegendItemOverflowMode
                                .wrap, // Agar legenda bisa wrap jika banyak
                            position: LegendPosition.bottom,
                          ),
                          tooltipBehavior: _tooltipBehavior,
                          series: <CartesianSeries<StockPublic, DateTime>>[
                            LineSeries<StockPublic, DateTime>(
                              name: 'Harga Jual',
                              color: Colors.red.shade400,
                              dataSource: stockData,
                              xValueMapper: (StockPublic data, _) =>
                                  data.tanggal.toDate(),
                              yValueMapper: (StockPublic data, _) =>
                                  data.hargaJual,
                              markerSettings: const MarkerSettings(
                                  isVisible: true,
                                  height: 3,
                                  width: 3), // Tampilkan marker kecil
                              emptyPointSettings: EmptyPointSettings(
                                  mode: EmptyPointMode
                                      .drop), // Abaikan titik kosong
                            ),
                            LineSeries<StockPublic, DateTime>(
                              name: 'Harga Beli',
                              color: Colors.blue.shade400,
                              dataSource: stockData,
                              xValueMapper: (StockPublic data, _) =>
                                  data.tanggal.toDate(),
                              yValueMapper: (StockPublic data, _) =>
                                  data.hargaBeli,
                              markerSettings: const MarkerSettings(
                                  isVisible: true, height: 3, width: 3),
                              emptyPointSettings:
                                  EmptyPointSettings(mode: EmptyPointMode.drop),
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
