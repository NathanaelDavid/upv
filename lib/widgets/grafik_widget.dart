import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GrafikMYRWidget extends StatefulWidget {
  const GrafikMYRWidget({super.key});

  @override
  _GrafikMYRWidgetState createState() => _GrafikMYRWidgetState();
}

class _GrafikMYRWidgetState extends State<GrafikMYRWidget> {
  final List<ChartData> _chartData = [
    ChartData('Jan', 4.2),
    ChartData('Feb', 4.1),
    ChartData('Mar', 4.0),
    ChartData('Apr', 3.9),
    ChartData('Mei', 3.8),
    ChartData('Jun', 3.7),
    ChartData('Jul', 3.6),
    ChartData('Agu', 3.5),
    ChartData('Sep', 3.4),
    ChartData('Okt', 3.3),
    ChartData('Nov', 3.2),
    ChartData('Des', 3.1),
  ];

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
