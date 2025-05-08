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
  final TextEditingController _hargaBeliController = TextEditingController();
  final TextEditingController _hargaJualController = TextEditingController();
  final StokService _stokService = StokService();

  List<String> _availableCurrencies = [];
  String? _selectedCurrencyCode;
  bool _useSellRate = true;
  double _total = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableCurrencies();
  }

  Future<void> _loadAvailableCurrencies() async {
    try {
      final stocksPublic = await _stokService.getAllStocks();
      final codes =
          stocksPublic.data.map((e) => e.kodeMataUang).toSet().toList();
      setState(() {
        _availableCurrencies = codes;
        _selectedCurrencyCode = codes.isNotEmpty ? codes.first : null;
      });
      if (_selectedCurrencyCode != null) {
        await _loadLatestRateForCurrency(_selectedCurrencyCode!);
      }
    } catch (e) {
      print(e);
      setState(() => _loading = false);
    }
  }

  Future<void> _loadLatestRateForCurrency(String code) async {
    setState(() => _loading = true);

    try {
      final stocksPublic = await _stokService.getAllStocks();
      final filtered = stocksPublic.data
          .where((e) => e.kodeMataUang == code)
          .toList()
        ..sort((a, b) => b.tanggal.compareTo(a.tanggal)); // terbaru duluan

      if (filtered.isNotEmpty) {
        final latest = filtered.first;
        _hargaBeliController.text = latest.hargaBeli.toStringAsFixed(0);
        _hargaJualController.text = latest.hargaJual.toStringAsFixed(0);
      }

      setState(() => _loading = false);
      _calculateTotal();
    } catch (e) {
      print(e);
      setState(() => _loading = false);
    }
  }

  void _calculateTotal() {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double rate = _useSellRate
        ? double.tryParse(_hargaJualController.text) ?? 0.0
        : double.tryParse(_hargaBeliController.text) ?? 0.0;
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
              child: SingleChildScrollView(
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
                    DropdownButton<String>(
                      value: _selectedCurrencyCode,
                      items: _availableCurrencies.map((code) {
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text(code),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCurrencyCode = value);
                          _loadLatestRateForCurrency(value);
                        }
                      },
                    ),
                    SizedBox(height: 16.0),
                    Text('Harga Beli:', style: TextStyle(fontSize: 16.0)),
                    TextField(
                      controller: _hargaBeliController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan harga beli',
                      ),
                      onChanged: (_) => _calculateTotal(),
                    ),
                    SizedBox(height: 8.0),
                    Text('Harga Jual:', style: TextStyle(fontSize: 16.0)),
                    TextField(
                      controller: _hargaJualController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan harga jual',
                      ),
                      onChanged: (_) => _calculateTotal(),
                    ),
                    SizedBox(height: 8.0),
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
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
