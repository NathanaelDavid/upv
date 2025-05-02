import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models_stok.dart';

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
  List<DocumentSnapshot> transaksiData = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final stockSnapshot = await FirebaseFirestore.instance
        .collection('stock')
        .orderBy('tanggal', descending: true)
        .get();

    final transaksiSnapshot =
        await FirebaseFirestore.instance.collection('transaksi').get();

    final allStock = stockSnapshot.docs
        .map((doc) => StockPublic.fromFirestore(doc))
        .toList();

    setState(() {
      stokData = allStock;
      transaksiData = transaksiSnapshot.docs;
      mataUangList = [
        'Semua Mata Uang',
        ...{...allStock.map((e) => e.kodeMataUang)}
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

  List<MapEntry<DateTime, StockPublic>> get groupedByDate {
    final map = <String, StockPublic>{};
    for (var item in filteredData) {
      final dateStr = DateFormat('yyyy-MM-dd').format(item.tanggal.toDate());
      map[dateStr] = item;
    }
    final entries = map.entries.map((e) {
      return MapEntry(DateTime.parse(e.key), e.value);
    }).toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  Map<String, List<StockPublic>> get groupedByCurrency {
    final map = <String, List<StockPublic>>{};
    for (var item in filteredData) {
      map.putIfAbsent(item.kodeMataUang, () => []).add(item);
    }
    return map;
  }

  Map<String, Map<String, double>> get transaksiRekap {
    final result = <String, Map<String, double>>{};

    for (var doc in transaksiData) {
      final data = doc.data() as Map<String, dynamic>;
      final tanggal = (data['tanggal'] as Timestamp?)?.toDate();
      if (tanggal == null) continue;

      final isSameYear = tanggal.year == selectedTahun;
      final isSameMonth = selectedBulan == 'Semua Bulan' ||
          tanggal.month == bulanList.indexOf(selectedBulan);
      if (!isSameYear || !isSameMonth) continue;

      final kode = data['kodeMataUang'] ?? '';
      final jenis = data['jenisTransaksi'];
      final jumlah = (data['jumlah'] ?? 0).toDouble();
      final total = (data['total'] ?? 0).toDouble();

      if (selectedMataUang != 'Semua Mata Uang' && kode != selectedMataUang)
        continue;

      result.putIfAbsent(
          kode,
          () => {
                'jualStok': 0.0,
                'jualRupiah': 0.0,
                'beliStok': 0.0,
                'beliRupiah': 0.0,
              });

      if (jenis == 'Jual') {
        result[kode]!['jualStok'] = result[kode]!['jualStok']! + jumlah;
        result[kode]!['jualRupiah'] = result[kode]!['jualRupiah']! + total;
      } else {
        result[kode]!['beliStok'] = result[kode]!['beliStok']! + jumlah;
        result[kode]!['beliRupiah'] = result[kode]!['beliRupiah']! + total;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedByDate;
    final perCurrency = groupedByCurrency;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Stok')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
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
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: grouped.isEmpty
                        ? const Center(child: Text("Tidak ada data"))
                        : LineChart(
                            LineChartData(
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      int index = value.toInt();
                                      if (index < 0 ||
                                          index >= grouped.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final date = grouped[index].key;
                                      return Text(
                                          DateFormat('dd/MM').format(date),
                                          style: const TextStyle(fontSize: 10));
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 2,
                                  dotData: FlDotData(show: false),
                                  spots: List.generate(
                                    grouped.length,
                                    (i) => FlSpot(i.toDouble(),
                                        grouped[i].value.jumlahStok),
                                  ),
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 2,
                                  dotData: FlDotData(show: false),
                                  spots: List.generate(
                                    grouped.length,
                                    (i) => FlSpot(i.toDouble(),
                                        grouped[i].value.hargaJual),
                                  ),
                                  belowBarData: BarAreaData(show: false),
                                ),
                                LineChartBarData(
                                  isCurved: true,
                                  color: Colors.red,
                                  barWidth: 2,
                                  dotData: FlDotData(show: false),
                                  spots: List.generate(
                                    grouped.length,
                                    (i) => FlSpot(i.toDouble(),
                                        grouped[i].value.hargaBeli),
                                  ),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        const Text("Rekapitulasi Stok per Mata Uang",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        DataTable(
                          columns: const [
                            DataColumn(label: Text("Mata Uang")),
                            DataColumn(label: Text("Total Stok")),
                            DataColumn(label: Text("Total Rupiah")),
                          ],
                          rows: perCurrency.entries.map((entry) {
                            final totalStok = entry.value
                                .fold(0.0, (sum, e) => sum + e.jumlahStok);
                            final totalRupiah = entry.value.fold(0.0,
                                (sum, e) => sum + e.jumlahStok * e.hargaJual);
                            return DataRow(cells: [
                              DataCell(Text(entry.key)),
                              DataCell(Text(totalStok.toStringAsFixed(2))),
                              DataCell(Text(
                                  "Rp ${NumberFormat('#,###').format(totalRupiah)}")),
                            ]);
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text("Rekap Transaksi per Mata Uang",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        DataTable(
                          columns: const [
                            DataColumn(label: Text("Mata Uang")),
                            DataColumn(label: Text("Beli (Stok)")),
                            DataColumn(label: Text("Beli (Rp)")),
                            DataColumn(label: Text("Jual (Stok)")),
                            DataColumn(label: Text("Jual (Rp)")),
                          ],
                          rows: transaksiRekap.entries.map((entry) {
                            final val = entry.value;
                            return DataRow(cells: [
                              DataCell(Text(entry.key)),
                              DataCell(
                                  Text(val['beliStok']!.toStringAsFixed(2))),
                              DataCell(Text(
                                  "Rp ${NumberFormat('#,###').format(val['beliRupiah'])}")),
                              DataCell(
                                  Text(val['jualStok']!.toStringAsFixed(2))),
                              DataCell(Text(
                                  "Rp ${NumberFormat('#,###').format(val['jualRupiah'])}")),
                            ]);
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
