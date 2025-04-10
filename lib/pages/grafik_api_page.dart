import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';

class ForexScreen extends StatefulWidget {
  @override
  _ForexScreenState createState() => _ForexScreenState();
}

class _ForexScreenState extends State<ForexScreen> {
  Map<String, double> exchangeRates = {};
  List<_ChartData> chartData = [];
  bool isLoading = true;
  String selectedCurrency = "USD";
  final List<String> filteredCurrencies = ["MYR", "JPY", "USD", "SGD"];

  @override
  void initState() {
    super.initState();
    fetchExchangeRates();
  }

  Future<void> fetchExchangeRates() async {
    final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/USD');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        exchangeRates = Map<String, double>.from(data['rates']).map((key,
                value) =>
            MapEntry(key, filteredCurrencies.contains(key) ? (1 / value) : 0));
        updateChartData();
        isLoading = false;
      });
    }
  }

  void updateChartData() {
    // Simulate fetching 1-month historical data with daily points
    chartData = List.generate(30, (index) {
      return _ChartData("Day ${30 - index}",
          (exchangeRates[selectedCurrency] ?? 0) * (1 + (index % 5) * 0.005));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forex Rates (Currency to IDR)")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                DropdownButton<String>(
                  value: selectedCurrency,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCurrency = newValue!;
                      updateChartData();
                    });
                  },
                  items: filteredCurrencies
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text("$value/IDR"),
                    );
                  }).toList(),
                ),
                SizedBox(height: 300, child: forexChart()),
                Expanded(child: forexList()),
              ],
            ),
    );
  }

  Widget forexChart() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        series: <LineSeries<_ChartData, String>>[
          LineSeries<_ChartData, String>(
            dataSource: chartData,
            xValueMapper: (_ChartData data, _) => data.currency,
            yValueMapper: (_ChartData data, _) => data.rate,
            dataLabelSettings: DataLabelSettings(isVisible: true),
          )
        ],
      ),
    );
  }

  Widget forexList() {
    return ListView.builder(
      itemCount: filteredCurrencies.length,
      itemBuilder: (context, index) {
        String currency = filteredCurrencies[index];
        double rate = exchangeRates[currency] ?? 0;
        return ListTile(
          title: Text("$currency/IDR"),
          trailing: Text(rate.toStringAsFixed(2)),
          onTap: () {
            setState(() {
              selectedCurrency = currency;
              updateChartData();
            });
          },
        );
      },
    );
  }
}

class _ChartData {
  final String currency;
  final double rate;
  _ChartData(this.currency, this.rate);
}
