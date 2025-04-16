import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models_stok.dart';
import '../util/stok_service.dart';

class CurrencyCalculator extends StatefulWidget {
  const CurrencyCalculator({super.key});

  @override
  _CurrencyCalculatorState createState() => _CurrencyCalculatorState();
}

class _CurrencyCalculatorState extends State<CurrencyCalculator> {
  final TextEditingController _amountController = TextEditingController();
  final StokService _stokService = StokService();

  List<StockPublic> _currencies = [];
  StockPublic? _selectedCurrency;
  bool _useSellRate = true;
  double _total = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrencyData();
  }

  Future<void> _loadCurrencyData() async {
    try {
      final stocksPublic = await _stokService.getAllStocks();
      setState(() {
        _currencies = stocksPublic.data;
        _selectedCurrency =
            stocksPublic.data.isNotEmpty ? stocksPublic.data[0] : null;
        _loading = false;
      });
      _calculateTotal();
    } catch (e) {
      print(e);
      setState(() => _loading = false);
    }
  }

  void _calculateTotal() {
    if (_selectedCurrency == null) return;
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double rate = _useSellRate
        ? _selectedCurrency!.hargaJual
        : _selectedCurrency!.hargaBeli;
    setState(() {
      _total = amount * rate;
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kalkulator Mata Uang')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jumlah Mata Uang:', style: TextStyle(fontSize: 16.0)),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan jumlah mata uang',
                    ),
                    onChanged: (_) => _calculateTotal(),
                  ),
                  SizedBox(height: 16.0),
                  Text('Pilih Mata Uang:', style: TextStyle(fontSize: 16.0)),
                  DropdownButton<StockPublic>(
                    value: _selectedCurrency,
                    items: _currencies.map((stock) {
                      return DropdownMenuItem<StockPublic>(
                        value: stock,
                        child: Text(stock.kodeMataUang),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCurrency = value);
                      _calculateTotal();
                    },
                  ),
                  Row(
                    children: [
                      Text('Gunakan rate: '),
                      Switch(
                        value: _useSellRate,
                        onChanged: (value) {
                          setState(() => _useSellRate = value);
                          _calculateTotal();
                        },
                      ),
                      Text(_useSellRate ? 'Jual' : 'Beli'),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Total: ${_formatCurrency(_total)}',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
    );
  }
}
