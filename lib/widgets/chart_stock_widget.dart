import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartStockWidget extends StatelessWidget {
  final List<ChartData> _chartData = [
    ChartData('Jan', 10821),
    ChartData('Feb', 11047),
    ChartData('Mar', 11272),
    ChartData('Apr', 11497),
    ChartData('Mei', 11722),
    ChartData('Jun', 11947),
    ChartData('Jul', 12172),
    ChartData('Agu', 12397),
    ChartData('Sep', 12622),
    ChartData('Okt', 12847),
    ChartData('Nov', 13072),
    ChartData('Des', 13297),
  ];

  ChartStockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      title: ChartTitle(text: 'Grafik Prediksi Mata Uang MYR dalam 1 Tahun'),
      series: [
        LineSeries<ChartData, String>(
          dataSource: _chartData,
          xValueMapper: (ChartData data, _) => data.month,
          yValueMapper: (ChartData data, _) => data.value,
        ),
      ],
    );
  }
}

class ChartData {
  final String month;
  final double value;

  ChartData(this.month, this.value);
}
