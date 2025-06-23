import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  // PERHATIAN: Menyimpan API key secara hardcode tidak aman untuk aplikasi produksi.
  // Pertimbangkan untuk menyimpannya menggunakan environment variables atau cara yang lebih aman.
  final String apiKey = "9cQVkIBQ9ytkkEtf676C";

  final List<String> _currencies = [
    'USDIDR',
    'SGDIDR',
    'JPYIDR',
    'MYRIDR',
    'EURIDR',
    'AUDIDR',
    'CNYIDR'
  ];
  String _selectedCurrency = 'USDIDR';

  // Interval tetap 'daily' karena kita menampilkan rentang 30 hari.
  String _interval = 'daily';

  late String _startDate;
  late String _endDate;

  bool _isLoading = true;
  List<FlSpot> _chartData = [];
  List<String> _xLabels = [];
  String? _errorMessage;

  double? _minY, _maxY;

  @override
  void initState() {
    super.initState();
    _setSpecificDateRange(); // Memanggil fungsi untuk menetapkan rentang tanggal spesifik
    _fetchData();
  }

  /// Menetapkan tanggal mulai ke 20 Mei 2025 dan tanggal berakhir 30 hari setelahnya.
  void _setSpecificDateRange() {
    final specificStartDate = DateTime(2025, 5, 20); // 20 Mei 2025
    // Menghitung tanggal berakhir 30 hari setelah tanggal mulai
    final specificEndDate = specificStartDate.add(const Duration(days: 30));

    _startDate = DateFormat('yyyy-MM-dd').format(specificStartDate);
    _endDate = DateFormat('yyyy-MM-dd').format(specificEndDate);
  }

  /// Mengambil data kurs dari TraderMade API.
  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _setSpecificDateRange(); // Pastikan tanggal diatur ulang setiap kali mengambil data

    final url =
        'https://marketdata.tradermade.com/api/v1/timeseries?api_key=$apiKey&currency=$_selectedCurrency&format=records&start_date=$_startDate&end_date=$_endDate&interval=$_interval&period=1';

    print("ChartPage - Mengambil data dari URL: $url");

    try {
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['quotes'] != null && (data['quotes'] as List).isNotEmpty) {
          final List<dynamic> quotes = data['quotes'];

          // --- PERBAIKAN PENTING DI SINI ---
          // Menghapus 'quotes.reversed' karena API mungkin sudah mengembalikan data dalam urutan ASCENDING (terlama ke terbaru).
          // Jika API mengembalikan TERBARU ke TERLAMA, Anda perlu mengaktifkan kembali `quotes.reversed`.
          // Verifikasi dengan melihat output 'First X label' dan 'Last X label' di konsol.
          final List<dynamic> processedQuotes = List.from(quotes);

          // DEBUG: Cetak 3 quote pertama (processed, ini seharusnya yang paling lampau jika perbaikan berhasil)
          print("ChartPage - Processed quotes (first 3):");
          for (int i = 0;
              i < (processedQuotes.length > 3 ? 3 : processedQuotes.length);
              i++) {
            print(processedQuotes[i]);
          }

          List<FlSpot> tempChartData = [];
          List<String> tempXLabels = [];
          double tempMinY = double.maxFinite;
          double tempMaxY = double.minPositive;

          for (int i = 0; i < processedQuotes.length; i++) {
            final quote = processedQuotes[i];
            final double closeValue =
                (quote['close'] as num?)?.toDouble() ?? 0.0;
            final String dateStr = quote['date'] as String? ?? '';

            if (closeValue == 0.0 && dateStr.isEmpty) {
              continue; // Lewati titik data yang tidak valid
            }

            tempChartData.add(FlSpot(i.toDouble(), closeValue));
            tempXLabels.add(dateStr);

            if (closeValue < tempMinY) tempMinY = closeValue;
            if (closeValue > tempMaxY) tempMaxY = closeValue;
          }

          // DEBUG: Cetak label X pertama dan terakhir untuk verifikasi
          if (tempXLabels.isNotEmpty) {
            print("ChartPage - First X label: ${tempXLabels.first}");
            print("ChartPage - Last X label: ${tempXLabels.last}");
          }

          setState(() {
            _chartData = tempChartData;
            _xLabels = tempXLabels;

            if (tempMinY != double.maxFinite &&
                tempMaxY != double.minPositive) {
              final range = tempMaxY - tempMinY;
              _minY = tempMinY - (range * 0.05);
              _maxY = tempMaxY + (range * 0.05);

              if (_minY == _maxY) {
                _minY = _minY! - (_minY! * 0.01).abs();
                _maxY = _maxY! + (_maxY! * 0.01).abs();
                if (_minY == _maxY && _minY! == 0) {
                  _minY = -1;
                  _maxY = 1;
                } else if (_minY! <= 0 && _maxY! <= 0) {
                  _minY = _minY! * 1.1;
                  _maxY = _maxY! * 0.9;
                }
              }
            } else {
              _minY = null;
              _maxY = null;
            }
          });
        } else {
          print("ChartPage - Tidak ada data 'quotes' atau kosong.");
          setState(() {
            _chartData = [];
            _xLabels = [];
            _minY = null;
            _maxY = null;
            _errorMessage = "Tidak ada data untuk parameter yang dipilih.";
          });
        }
      } else {
        print("ChartPage - Gagal mengambil data: ${response.statusCode}");
        print("ChartPage - Body respons: ${response.body}");
        setState(() {
          _errorMessage =
              "Gagal memuat data (Status: ${response.statusCode}). Coba lagi nanti. ${response.body}";
          _chartData = [];
          _xLabels = [];
        });
      }
    } catch (e) {
      print("ChartPage - Pengecualian saat mengambil data: $e");
      if (mounted) {
        setState(() {
          _errorMessage =
              "Terjadi kesalahan koneksi: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length)}...";
          _chartData = [];
          _xLabels = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Membangun panel kontrol dengan dropdown mata uang dan interval.
  Widget _buildControlsPanel(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: _selectedCurrency,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Mata Uang',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 10.0),
              ),
              items: _currencies.map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(currency, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedCurrency = newValue);
                        _fetchData();
                      }
                    },
            ),
          ),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              value: _interval,
              decoration: InputDecoration(
                labelText: 'Interval',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 10.0),
              ),
              items: ['daily']
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.capitalize(),
                          style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _interval = value);
                        _fetchData();
                      }
                    },
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchData,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Refresh Grafik'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: onPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Grafik Kurs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            _buildControlsPanel(context),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: _isLoading && _chartData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(_errorMessage!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 16),
                              textAlign: TextAlign.center),
                        ))
                      : _chartData.isEmpty
                          ? Center(
                              child: Text(
                                "Tidak ada data untuk ditampilkan.\nSilakan sesuaikan parameter dan klik 'Refresh Grafik'.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey.shade600),
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.only(top: 16.0, right: 8.0),
                              child: LineChart(
                                LineChartData(
                                  minY: _minY,
                                  maxY: _maxY,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _chartData,
                                      isCurved: false,
                                      color: primaryColor,
                                      barWidth: 2.2,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                          show: _chartData.length < 60),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: primaryColor.withOpacity(0.15),
                                      ),
                                    ),
                                  ],
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 50,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            NumberFormat.compact()
                                                .format(value),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black54),
                                            textAlign: TextAlign.left,
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        interval: (_xLabels.length / 5)
                                            .ceilToDouble()
                                            .clamp(1, double.infinity),
                                        getTitlesWidget: (value, meta) {
                                          final int index = value.toInt();
                                          if (index >= 0 &&
                                              index < _xLabels.length) {
                                            final dateStr = _xLabels[index];
                                            try {
                                              final date =
                                                  DateTime.parse(dateStr);
                                              String label = DateFormat('dd/MM')
                                                  .format(date);
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 6.0),
                                                child: Text(label,
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.black54)),
                                              );
                                            } catch (e) {
                                              return const Text('');
                                            }
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 1),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: (_maxY != null &&
                                            _minY != null &&
                                            _maxY! > _minY!)
                                        ? (_maxY! - _minY!) / 4
                                        : null,
                                    verticalInterval: (_xLabels.length / 5)
                                        .ceilToDouble()
                                        .clamp(1, double.infinity),
                                    getDrawingHorizontalLine: (value) => FlLine(
                                        color: Colors.grey.shade200,
                                        strokeWidth: 0.7),
                                    getDrawingVerticalLine: (value) => FlLine(
                                        color: Colors.grey.shade200,
                                        strokeWidth: 0.7),
                                  ),
                                  lineTouchData: LineTouchData(
                                    handleBuiltInTouches: true,
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipColor: (touchedSpot) =>
                                          primaryColor.withOpacity(0.85),
                                      tooltipPadding: const EdgeInsets.all(10),
                                      tooltipRoundedRadius: 8,
                                      getTooltipItems:
                                          (List<LineBarSpot> touchedSpots) {
                                        return touchedSpots
                                            .map((spot) {
                                              final int index = spot.x.toInt();
                                              if (index >= 0 &&
                                                  index < _xLabels.length) {
                                                String dateLabel =
                                                    _xLabels[index];
                                                try {
                                                  final date =
                                                      DateTime.parse(dateLabel);
                                                  dateLabel =
                                                      DateFormat('dd MMM yy')
                                                          .format(date);
                                                } catch (e) {
                                                  // Fallback jika penguraian tanggal gagal
                                                }

                                                final valStr =
                                                    NumberFormat.currency(
                                                            locale: 'id_ID',
                                                            symbol: 'Rp ',
                                                            decimalDigits: 0)
                                                        .format(spot.y);
                                                return LineTooltipItem(
                                                  '$dateLabel\n',
                                                  TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12),
                                                  children: [
                                                    TextSpan(
                                                        text: valStr,
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.9)))
                                                  ],
                                                );
                                              }
                                              return null;
                                            })
                                            .whereType<LineTooltipItem>()
                                            .toList();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension untuk mengkapitalisasi huruf pertama dari sebuah string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
