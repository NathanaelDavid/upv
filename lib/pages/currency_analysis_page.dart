import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import '../widgets/currency_dropdown.dart';
import '../widgets/analysis_input.dart';
import '../widgets/analysis_list.dart';
import '../widgets/chart_stock_widget.dart'; // Pastikan import widget ini

class CurrencyAnalysisPage extends StatefulWidget {
  final Function(int) onNavigate; // Callback untuk navigasi
  final int selectedIndex; // Indeks halaman aktif

  const CurrencyAnalysisPage({
    super.key,
    required this.onNavigate,
    required this.selectedIndex,
  });

  @override
  _CurrencyAnalysisPageState createState() => _CurrencyAnalysisPageState();
}

class _CurrencyAnalysisPageState extends State<CurrencyAnalysisPage> {
  final TextEditingController _analysisController = TextEditingController();
  final List<Map<String, String>> _analysisData = [];

  void _addAnalysis() {
    if (_analysisController.text.isNotEmpty) {
      final timeStamp =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      setState(() {
        _analysisData.add({
          'analysis': _analysisController.text,
          'timestamp': timeStamp,
        });
      });
      _analysisController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tuliskan analisis Anda!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Langsung render grafik di sini
                  ChartStockWidget(),
                  const SizedBox(height: 16),
                  AnalysisInput(
                    controller: _analysisController,
                    onSubmit: _addAnalysis,
                  ),
                  const Divider(),
                  Expanded(
                    child: AnalysisList(analysisData: _analysisData),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
