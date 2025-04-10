import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pastikan untuk menambahkan intl package di pubspec.yaml

class CurrencyCalculator extends StatefulWidget {
  const CurrencyCalculator({super.key});

  @override
  _CurrencyCalculatorState createState() => _CurrencyCalculatorState();
}

class _CurrencyCalculatorState extends State<CurrencyCalculator> {
  final TextEditingController _amountController = TextEditingController();
  double _total = 0.0;

  // Dataset mata uang dengan nilai tukar
  final Map<String, double> _exchangeRates = {
    'MYR': 3500.0,
    'USD': 15900.0,
    'EUR': 16500.0,
    'JPY': 100
  };

  String _selectedCurrency = 'MYR';

  void _calculateTotal() {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double rate = _exchangeRates[_selectedCurrency] ?? 0.0;
    setState(() {
      _total = amount * rate;
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID', // Menggunakan format Indonesia
      symbol: 'Rp. ',
      decimalDigits: 0, // Tidak ada desimal
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kalkulator Mata Uang'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jumlah Mata Uang:',
              style: TextStyle(fontSize: 16.0),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan jumlah mata uang',
              ),
              onChanged: (value) => _calculateTotal(),
            ),
            SizedBox(height: 16.0),
            Text(
              'Pilih Mata Uang:',
              style: TextStyle(fontSize: 16.0),
            ),
            DropdownButton<String>(
              value: _selectedCurrency,
              items: _exchangeRates.keys.map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCurrency = newValue ?? 'MYR';
                  _calculateTotal();
                });
              },
            ),
            SizedBox(height: 16.0),
            Text(
              'Total: ${_formatCurrency(_total)}',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
