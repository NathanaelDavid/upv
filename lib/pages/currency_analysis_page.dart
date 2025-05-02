import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/analysis_input.dart';
import '../widgets/chart_stock_widget.dart';

class CurrencyAnalysisPage extends StatefulWidget {
  final Function(int) onNavigate; // Callback untuk navigasi (jika perlu)
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
        _analysisData.insert(0, {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Mata Uang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartStockWidget(),
            const SizedBox(height: 20),
            AnalysisInput(
              controller: _analysisController,
              onSubmit: _addAnalysis,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Analisis Anda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Menampilkan daftar analisis sebagai card
            Column(
              children: _analysisData.map((data) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    title: Text(data['analysis'] ?? ''),
                    subtitle: Text(data['timestamp'] ?? ''),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
