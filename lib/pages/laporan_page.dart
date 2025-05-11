import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:upv/models/models_stok.dart';
import 'package:upv/models/report_models.dart';
import 'package:upv/models/transaksi_models.dart';
import 'package:upv/util/kode_mata_uang_service.dart';
import 'package:upv/util/report_service.dart';
import 'package:upv/util/stok_service.dart';
import 'package:upv/util/transaksi_service.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String selectedMataUang = 'Semua Mata Uang';
  String selectedBulan = 'Semua Bulan';
  int selectedTahun = DateTime.now().year;

  List<String> bulanList = [
    'Semua Bulan',
    ...List.generate(12, (i) => DateFormat.MMMM().format(DateTime(0, i + 1)))
  ];
  List<int> tahunList = List.generate(5, (i) => DateTime.now().year - i);

  List<String> mataUangList = ['Semua Mata Uang'];
  List<StockPublic> stokData = [];
  List<ReportPublic> reportData = [];

  final StokService _stokService = StokService();
  final KodeMataUangService _kodeMataUangService = KodeMataUangService();
  final ReportService _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final stokData = await _stokService.getAllStocks();
    final kodeMataUang = await _kodeMataUangService.getAllKodeMataUangs();
    final reportData = await _reportService.getReports(
        "usd", "purchases", "2025-04-01", "2025-04-30");

    setState(() {
      this.stokData = stokData.data;
      this.reportData = reportData;
      mataUangList = [
        'Semua Mata Uang',
        ...{...kodeMataUang.map((e) => e.kode)}
      ];
    });
  }

  List<StockPublic> get filteredData {
    return stokData.where((item) {
      final date = item.tanggal.toDate();
      final matchTahun = date.year == selectedTahun;
      final matchBulan = selectedBulan == 'Semua Bulan' ||
          date.month == bulanList.indexOf(selectedBulan);
      final matchMataUang = selectedMataUang == 'Semua Mata Uang' ||
          item.kodeMataUang == selectedMataUang;
      return matchTahun && matchBulan && matchMataUang;
    }).toList();
  }

  Map<DateTime, Map<String, double>> get stokHarian {
    final Map<DateTime, Map<String, double>> grouped = {};

    for (var stock in filteredData) {
      final date = DateTime(
        stock.tanggal.toDate().year,
        stock.tanggal.toDate().month,
        stock.tanggal.toDate().day,
      );

      grouped.putIfAbsent(date, () => {});
      grouped[date]![stock.kodeMataUang] =
          (grouped[date]![stock.kodeMataUang] ?? 0) + stock.jumlahStok;
    }

    return grouped;
  }

  Map<String, List<StockPublic>> get stokKursRekap {
    final map = <String, List<StockPublic>>{};
    for (var item in filteredData) {
      map.putIfAbsent(item.kodeMataUang, () => []).add(item);
    }
    return map;
  }

  // Map<String, Map<String, double>> get transaksiRekap {
  //   final result = <String, Map<String, double>>{};

  //   for (var transaksi in transaksiData) {
  //     final tanggal = transaksi.timestamp.toDate();
  //     final isSameYear = tanggal.year == selectedTahun;
  //     final isSameMonth = selectedBulan == 'Semua Bulan' ||
  //         tanggal.month == bulanList.indexOf(selectedBulan);
  //     if (!isSameYear || !isSameMonth) continue;

  //     final kodeMataUang = transaksi.kodeMataUang;
  //     if (selectedMataUang != 'Semua Mata Uang' &&
  //         kodeMataUang != selectedMataUang) continue;

  //     result.putIfAbsent(
  //         transaksi.kodeMataUang,
  //         () => {
  //               'jualStok': 0.0,
  //               'jualRupiah': 0.0,
  //               'beliStok': 0.0,
  //               'beliRupiah': 0.0,
  //             });

  //     if (transaksi.jenis == 'Jual') {
  //       result[kodeMataUang]!['jualStok'] =
  //           result[kodeMataUang]!['jualStok']! + transaksi.jumlah;
  //       result[kodeMataUang]!['jualRupiah'] =
  //           result[kodeMataUang]!['jualRupiah']! + transaksi.totalNominal;
  //     } else {
  //       result[kodeMataUang]!['beliStok'] =
  //           result[kodeMataUang]!['beliStok']! + transaksi.jumlah;
  //       result[kodeMataUang]!['beliRupiah'] =
  //           result[kodeMataUang]!['beliRupiah']! + transaksi.totalNominal;
  //     }
  //   }

  //   return result;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Pembelian')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
                child: Column(
              children: [
                Expanded(child: buildBarChart()),
                // const SizedBox(height: 16),
                // Expanded(child: _buildDataTables()),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        DropdownButton<String>(
          value: selectedBulan,
          items: bulanList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => selectedBulan = val!),
        ),
        DropdownButton<int>(
          value: selectedTahun,
          items: tahunList
              .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
              .toList(),
          onChanged: (val) => setState(() => selectedTahun = val!),
        ),
        DropdownButton<String>(
          value: selectedMataUang,
          items: mataUangList
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => selectedMataUang = val!),
        ),
      ],
    );
  }

  Widget buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY().toDouble() * 1.2,
        barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.blueAccent,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String date = DateFormat('dd/MM')
                    .format(DateTime.parse(reportData[group.x.toInt()].date));
                String value = "Rp ${NumberFormat('#,###').format(rod.toY)}";

                return BarTooltipItem(
                  '$date\n$value',
                  const TextStyle(color: Colors.white),
                );
              },
            )),
        titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.parse(reportData[value.toInt()].date);
                  return Text(
                    DateFormat('dd/MM').format(date),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            )),
        borderData: FlBorderData(show: false),
        barGroups: reportData.asMap().entries.map((entry) {
          int index = entry.key;
          ReportPublic report = entry.value;
          return BarChartGroupData(x: index, barRods: [
            // BarChartRodData(
            //   toY: report.totalNominal.toDouble(),
            //   color: Colors.blue,
            //   width: 8,
            //   borderRadius: BorderRadius.circular(4),
            // ),
            BarChartRodData(
              toY: report.totalJumlahBarang.toDouble(),
              color: Colors.green,
              width: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            // BarChartRodData(
            //   toY: report.transaksiCount.toDouble(),
            //   color: Colors.orange,
            //   width: 8,
            //   borderRadius: BorderRadius.circular(4),
            // ),
          ]);
        }).toList(),
      ),
    );
  }

  int _getMaxY() {
    return reportData.fold<int>(
      0,
      (prev, r) => [prev, r.totalNominal, r.totalJumlahBarang, r.transaksiCount]
          .reduce((a, b) => a > b ? a : b),
    );
  }

  // Widget buildGroupedBarChart() {
  //   final groupedData = stokHarian;

  //   if (groupedData.isEmpty) {
  //     return const Center(child: Text("Tidak ada data"));
  //   }

  //   final dates = groupedData.keys.toList()..sort();
  //   final allCurrencies =
  //       <String>{for (final map in groupedData.values) ...map.keys}.toList();

  //   return Column(
  //     children: [
  //       Expanded(
  //         child: BarChart(
  //           BarChartData(
  //             barGroups: List.generate(dates.length, (index) {
  //               final date = dates[index];
  //               final stokPerCurrency = groupedData[date]!;

  //               return BarChartGroupData(
  //                 x: index,
  //                 barRods: allCurrencies.map((currency) {
  //                   final stok = stokPerCurrency[currency] ?? 0.0;
  //                   return BarChartRodData(
  //                     toY: stok,
  //                     width: 8,
  //                     color: _getColorForCurrency(currency),
  //                     borderRadius: BorderRadius.zero,
  //                   );
  //                 }).toList(),
  //               );
  //             }),
  //             titlesData: FlTitlesData(
  //               bottomTitles: AxisTitles(
  //                 sideTitles: SideTitles(
  //                   showTitles: true,
  //                   getTitlesWidget: (value, meta) {
  //                     final index = value.toInt();
  //                     if (index < 0 || index >= dates.length) {
  //                       return const SizedBox.shrink();
  //                     }
  //                     return Text(
  //                       DateFormat('dd/MM').format(dates[index]),
  //                       style: const TextStyle(fontSize: 10),
  //                     );
  //                   },
  //                 ),
  //               ),
  //               leftTitles: AxisTitles(
  //                 sideTitles: SideTitles(showTitles: true),
  //               ),
  //             ),
  //             gridData: FlGridData(show: true),
  //             borderData: FlBorderData(show: true),
  //             groupsSpace: 16,
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       _buildChartLegend(allCurrencies),
  //     ],
  //   );
  // }

  // Color _getColorForCurrency(String kodeMataUang) {
  //   final colors = [
  //     Colors.blue,
  //     Colors.green,
  //     Colors.orange,
  //     Colors.red,
  //     Colors.purple,
  //     Colors.cyan,
  //     Colors.brown,
  //     Colors.indigo,
  //   ];

  //   final index = kodeMataUang.hashCode % colors.length;
  //   return colors[index];
  // }

  // Widget _buildChartLegend(List<String> currencies) {
  //   return Wrap(
  //     spacing: 12,
  //     children: currencies.map((code) {
  //       return Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Container(width: 12, height: 12, color: _getColorForCurrency(code)),
  //           const SizedBox(width: 4),
  //           Text(code),
  //         ],
  //       );
  //     }).toList(),
  //   );
  // }

  // Widget _buildDataTables() {
  //   return ListView(
  //     children: [
  //       const Text("Rekapitulasi Stok per Mata Uang",
  //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //       const SizedBox(height: 8),
  //       _buildStokTable(),
  //       const SizedBox(height: 24),
  //       const Text("Rekap Transaksi per Mata Uang",
  //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //       const SizedBox(height: 8),
  //       _buildTransaksiTable(),
  //     ],
  //   );
  // }

  // Widget _buildStokTable() {
  //   return DataTable(
  //     columns: const [
  //       DataColumn(label: Text("Mata Uang")),
  //       DataColumn(label: Text("Total Stok")),
  //       DataColumn(label: Text("Total Rupiah")),
  //     ],
  //     rows: stokKursRekap.entries.map((entry) {
  //       final totalStok = entry.value.fold(0.0, (sum, e) => sum + e.jumlahStok);
  //       final totalRupiah =
  //           entry.value.fold(0.0, (sum, e) => sum + e.jumlahStok * e.hargaJual);
  //       return DataRow(cells: [
  //         DataCell(Text(entry.key)),
  //         DataCell(Text(totalStok.toStringAsFixed(2))),
  //         DataCell(Text("Rp ${NumberFormat('#,###').format(totalRupiah)}")),
  //       ]);
  //     }).toList(),
  //   );
  // }

  // Widget _buildTransaksiTable() {
  //   return DataTable(
  //     columns: const [
  //       DataColumn(label: Text("Mata Uang")),
  //       DataColumn(label: Text("Beli (Stok)")),
  //       DataColumn(label: Text("Beli (Rp)")),
  //       DataColumn(label: Text("Jual (Stok)")),
  //       DataColumn(label: Text("Jual (Rp)")),
  //     ],
  //     rows: transaksiRekap.entries.map((entry) {
  //       final val = entry.value;
  //       return DataRow(cells: [
  //         DataCell(Text(entry.key)),
  //         DataCell(Text(val['beliStok']!.toStringAsFixed(2))),
  //         DataCell(
  //             Text("Rp ${NumberFormat('#,###').format(val['beliRupiah'])}")),
  //         DataCell(Text(val['jualStok']!.toStringAsFixed(2))),
  //         DataCell(
  //             Text("Rp ${NumberFormat('#,###').format(val['jualRupiah'])}")),
  //       ]);
  //     }).toList(),
  //   );
  // }
}
