import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartWidget extends StatelessWidget {
  final List<ChartData> _chartData = [
    ChartData('Jan', 3340),
    ChartData('Feb', 3280),
    ChartData('Mar', 3300),
    ChartData('Apr', 3345),
    ChartData('Mei', 3400),
    ChartData('Jun', 3340),
    ChartData('Jul', 3460),
    ChartData('Agu', 3670),
    ChartData('Sep', 3550),
    ChartData('Okt', 3610),
    ChartData('Nov', 3550),
    ChartData('Des', 3590),
  ];

  ChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grafik Mata Uang MYR'),
      ),
      body: Center(
        child: SfCartesianChart(
          primaryXAxis: CategoryAxis(),
          title: ChartTitle(text: 'Grafik Mata Uang MYR dalam 1 Tahun'),
          series: [
            LineSeries<ChartData, String>(
              dataSource: _chartData,
              xValueMapper: (ChartData data, _) => data.month,
              yValueMapper: (ChartData data, _) => data.value,
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  String month;
  double value;

  ChartData(this.month, this.value);
}
