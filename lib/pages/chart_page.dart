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
  String apiKey = "SVjXsV3MAOJjuOO2GfKT";

  final List<String> _currencies = [
    'USDIDR',
    'SGDIDR',
    'JPYIDR',
    'MYRIDR',
    'EURIDR',
    'AUDIDR',
    'CNYIDR'
  ]; // Tambahkan/sesuaikan
  String _selectedCurrency = 'USDIDR';
  String _interval = 'daily'; // Pilihan: 'daily', 'hourly', 'minute'
  late String _startDate;
  late String _endDate;

  bool _isLoading = true; // Mulai dengan true untuk loading awal
  List<FlSpot> _chartData = [];
  List<String> _xLabels =
      []; // Menyimpan tanggal/waktu asli untuk tooltip dan label sumbu X
  String? _errorMessage;

  // Untuk scaling sumbu Y dinamis
  double? _minY, _maxY;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    // Default menampilkan data 30 hari terakhir
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    _startDate = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
    _endDate = DateFormat('yyyy-MM-dd').format(today);
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url =
        'https://marketdata.tradermade.com/api/v1/timeseries?api_key=$apiKey&currency=$_selectedCurrency&format=records&start_date=$_startDate&end_date=$_endDate&interval=$_interval&period=1';

    print("ChartPage - Fetching data: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['quotes'] != null && (data['quotes'] as List).isNotEmpty) {
          final List<dynamic> quotes = data['quotes'];

          // TraderMade API mengembalikan data dari terbaru ke terlama jika interval daily/hourly
          // Kita perlu membaliknya agar urutan di grafik benar (terlama ke terbaru)
          final List<dynamic> sortedQuotes = List.from(quotes.reversed);

          List<FlSpot> tempChartData = [];
          List<String> tempXLabels = [];
          double tempMinY = double.maxFinite;
          double tempMaxY = double.minPositive;

          for (int i = 0; i < sortedQuotes.length; i++) {
            final quote = sortedQuotes[i];
            final double closeValue =
                (quote['close'] as num?)?.toDouble() ?? 0.0;
            final String dateStr = quote['date'] as String? ?? '';

            tempChartData.add(FlSpot(i.toDouble(), closeValue));
            tempXLabels.add(dateStr); // Simpan tanggal/waktu asli

            if (closeValue < tempMinY) tempMinY = closeValue;
            if (closeValue > tempMaxY) tempMaxY = closeValue;
          }

          setState(() {
            _chartData = tempChartData;
            _xLabels = tempXLabels;
            if (tempMinY != double.maxFinite &&
                tempMaxY != double.minPositive) {
              final range = tempMaxY - tempMinY;
              // Tambahkan padding 5% ke min dan max Y
              _minY = tempMinY - (range * 0.05);
              _maxY = tempMaxY + (range * 0.05);
              if (_minY == _maxY) {
                // Jika semua nilai sama
                _minY = _minY! - (_minY! * 0.01).abs(); // Sedikit range
                _maxY = _maxY! + (_maxY! * 0.01).abs();
                if (_minY! <= 0 && _maxY! <= 0) {
                  // handle jika nilai 0 atau negatif
                  _minY = -1;
                  _maxY = 1;
                }
              }
            } else {
              _minY = null;
              _maxY = null;
            }
          });
        } else {
          print(
              "ChartPage - No quotes found in response or quotes list is empty.");
          setState(() {
            _chartData = [];
            _xLabels = [];
            _minY = null;
            _maxY = null;
            // _errorMessage = "Tidak ada data untuk parameter yang dipilih."; // Opsional
          });
        }
      } else {
        print("ChartPage - Error fetching data: ${response.statusCode}");
        print("ChartPage - Response body: ${response.body}");
        setState(() {
          _errorMessage =
              "Gagal memuat data (Status: ${response.statusCode}). Coba lagi nanti.";
          _chartData = [];
          _xLabels = [];
        });
      }
    } catch (e) {
      print("ChartPage - Exception fetching data: $e");
      if (mounted) {
        setState(() {
          _errorMessage =
              "Terjadi kesalahan: ${e.toString().substring(0, (e.toString().length > 50) ? 50 : e.toString().length)}...";
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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initial =
        isStartDate ? DateTime.parse(_startDate) : DateTime.parse(_endDate);
    final DateTime first = DateTime(2000);
    final DateTime last = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last)
          ? last
          : (initial.isBefore(first) ? first : initial),
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isStartDate) {
          if (picked.isAfter(DateTime.parse(_endDate))) {
            _startDate = formattedDate;
            _endDate = formattedDate; // Samakan jika start > end
          } else {
            _startDate = formattedDate;
          }
        } else {
          // Memilih end date
          if (picked.isBefore(DateTime.parse(_startDate))) {
            _endDate = formattedDate;
            _startDate = formattedDate; // Samakan jika end < start
          } else {
            _endDate = formattedDate;
          }
        }
      });
      // _fetchData(); // Panggil fetchData setelah tanggal diubah atau tunggu tombol "Muat"
    }
  }

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
            width: 150, // Beri lebar agar dropdown tidak terlalu sempit
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
                        // _fetchData(); // Langsung fetch atau tunggu tombol muat
                      }
                    },
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _selectDate(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: onPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            child: Text(
                'Mulai: ${DateFormat('dd/MM/yy').format(DateTime.parse(_startDate))}',
                style: const TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _selectDate(context, false),
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: onPrimaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            child: Text(
                'Akhir: ${DateFormat('dd/MM/yy').format(DateTime.parse(_endDate))}',
                style: const TextStyle(fontSize: 13)),
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
              items: ['daily', 'hourly', 'minute']
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.capitalize(),
                          style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      if (value != null) setState(() => _interval = value);
                    },
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchData,
            icon: const Icon(Icons.bar_chart_rounded,
                size: 20), // Ganti ikon refresh ke ikon chart
            label: const Text('Tampilkan'),
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
      margin: const EdgeInsets.all(0), // Margin diatur oleh parent (HomePage)
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
              child: _isLoading &&
                      _chartData
                          .isEmpty // Tampilkan loader jika sedang loading DAN belum ada data
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
                                "Tidak ada data untuk ditampilkan.\nSilakan sesuaikan parameter dan klik 'Tampilkan'.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey.shade600),
                              ),
                            )
                          : Padding(
                              // Padding untuk grafik
                              padding:
                                  const EdgeInsets.only(top: 16.0, right: 8.0),
                              child: LineChart(
                                LineChartData(
                                  minY: _minY,
                                  maxY: _maxY,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _chartData,
                                      isCurved: false, // Garis lurus
                                      color: primaryColor,
                                      barWidth: 2.2,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                          show: _chartData.length <
                                              60), // Tampilkan dot jika data tidak terlalu banyak
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
                                        reservedSize: 50, // Ruang untuk label Y
                                        getTitlesWidget: (value, meta) {
                                          // Format angka untuk label Y
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
                                        interval: (_xLabels.length /
                                                (_xLabels.length > 10
                                                    ? 5
                                                    : _xLabels.length > 1
                                                        ? 2
                                                        : 1))
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
                                              String label =
                                                  _interval == 'daily'
                                                      ? DateFormat('dd/MM')
                                                          .format(date)
                                                      : DateFormat('HH:mm')
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
                                                  dateLabel = DateFormat(
                                                          'dd MMM yy HH:mm')
                                                      .format(date);
                                                } catch (e) {
                                                  /* biarkan dateLabel apa adanya */
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
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.9)))
                                                    ]);
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

// Extension untuk capitalize string (misal: 'daily' -> 'Daily')
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
