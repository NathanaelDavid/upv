import 'package:flutter/material.dart';
import '../widgets/kalkulator.dart';
import '../widgets/chart_widget.dart';
import '../widgets/currency_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          // Bagian Chat
          Expanded(
            flex: 2,
            child: CurrencyCalculator(),
          ),
          SizedBox(width: 16.0),

          // Bagian Grafik
          Expanded(
            flex: 4,
            child: ChartWidget(),
          ),
          SizedBox(width: 16.0),

          // Bagian Kurs Mata Uang
          Expanded(
            flex: 2,
            child: CurrencyWidget(),
          ),
        ],
      ),
    );
  }
}
