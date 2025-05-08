import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  String apiKey = "SVjXsV3MAOJjuOO2GfKT";
  final List<String> currencies = ['USDIDR', 'SGDIDR', 'JPYIDR', 'MYRIDR'];
  String selectedCurrency = 'USDIDR';
  String interval = 'daily';
  late String startDate;
  late String endDate;
  bool isLoading = false;

  List<FlSpot> chartData = [];
  List<String> xLabels = [];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final thirtyDaysAgo = today.subtract(Duration(days: 30));
    startDate = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
    endDate = DateFormat('yyyy-MM-dd').format(today);
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    final url =
        'https://marketdata.tradermade.com/api/v1/timeseries?api_key=$apiKey&currency=$selectedCurrency&format=records&start_date=$startDate&end_date=$endDate&interval=$interval&period=1';

    print("Fetching data: $url");

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['quotes'] != null) {
        final List<dynamic> quotes = data['quotes'];

        setState(() {
          chartData = [];
          xLabels = [];
          for (int i = 0; i < quotes.length; i++) {
            final double closeValue = quotes[i]['close']?.toDouble() ?? 0.0;
            chartData.add(FlSpot(i.toDouble(), closeValue));
            xLabels.add(quotes[i]['date']);
          }
        });
      } else {
        print("No quotes found in response.");
      }
    } else {
      print("Error fetching data: ${response.statusCode}");
      print("Response body: ${response.body}");
    }

    setState(() => isLoading = false);
  }

  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    final initialDate =
        isStartDate ? DateTime.parse(startDate) : DateTime.parse(endDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        final formatted = DateFormat('yyyy-MM-dd').format(picked);
        if (isStartDate) {
          startDate = formatted;
        } else {
          endDate = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 200,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: ListView(
              children: currencies.map((currency) {
                return ListTile(
                  title: Text(currency),
                  tileColor:
                      selectedCurrency == currency ? Colors.blue.shade50 : null,
                  selected: selectedCurrency == currency,
                  selectedTileColor: Colors.blue.shade100,
                  onTap: () {
                    setState(() {
                      selectedCurrency = currency;
                    });
                    fetchData();
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: chartData,
                                  isCurved: false,
                                  color: Colors.blue,
                                  barWidth: 2,
                                  belowBarData: BarAreaData(show: false),
                                  dotData: FlDotData(show: false),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true)),
                                rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      int index = value.toInt();
                                      if (index >= 0 &&
                                          index < xLabels.length) {
                                        final date =
                                            DateTime.parse(xLabels[index]);
                                        return Text(
                                            DateFormat('dd/MM').format(date),
                                            style: TextStyle(fontSize: 10));
                                      }
                                      return Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (touchedSpot) =>
                                      Colors.lightBlue,
                                  tooltipBorder:
                                      BorderSide(color: Colors.grey.shade300),
                                  getTooltipItems:
                                      (List<LineBarSpot> touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      return LineTooltipItem(
                                        '${xLabels[spot.x.toInt()]}\n${spot.y.toStringAsFixed(2)}',
                                        TextStyle(color: Colors.white),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => selectDate(context, true),
                        child: Text(
                            'Start Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(startDate))}'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => selectDate(context, false),
                        child: Text(
                            'End Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(endDate))}'),
                      ),
                      SizedBox(width: 10),
                      DropdownButton<String>(
                        value: interval,
                        items: ['daily', 'hourly', 'minute']
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            interval = value!;
                          });
                        },
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: fetchData,
                        child: Text('Load'),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
