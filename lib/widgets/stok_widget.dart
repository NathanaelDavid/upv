import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../util/stok_service.dart';
import '../models/models_stok.dart';

class StokWidget extends StatefulWidget {
  const StokWidget({super.key});

  @override
  _StokWidgetState createState() => _StokWidgetState();
}

class _StokWidgetState extends State<StokWidget> {
  final StokService _stokService = StokService();
  late Future<StocksPublic> _stocksFuture;

  @override
  void initState() {
    super.initState();
    _stocksFuture = _stokService.getAllStocks();
  }

  void _showStockForm({StockPublic? stock}) {
    final kodeController =
        TextEditingController(text: stock?.kodeMataUang ?? '');
    final hargaBeliController =
        TextEditingController(text: stock?.hargaBeli.toString() ?? '');
    final hargaJualController =
        TextEditingController(text: stock?.hargaJual.toString() ?? '');

    Timestamp selectedTimestamp = stock?.tanggal ?? Timestamp.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(stock == null ? 'Tambah Harga Mata Uang' : 'Update Harga'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: kodeController,
                    decoration:
                        const InputDecoration(labelText: 'Kode Mata Uang')),
                TextField(
                    controller: hargaBeliController,
                    decoration: const InputDecoration(labelText: 'Harga Beli'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: hargaJualController,
                    decoration: const InputDecoration(labelText: 'Harga Jual'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                        "Tanggal: ${selectedTimestamp.toDate().toLocal().toString().split(' ')[0]}"),
                    const Spacer(),
                    TextButton(
                      child: const Text("Pilih Tanggal"),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedTimestamp.toDate(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedTimestamp = Timestamp.fromDate(pickedDate);
                          });
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: Text(stock == null ? 'Tambah' : 'Update'),
              onPressed: () async {
                if (kodeController.text.isEmpty ||
                    hargaBeliController.text.isEmpty ||
                    hargaJualController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Semua field harus diisi!')));
                  return;
                }

                final stockData = StockCreate(
                  kodeMataUang: kodeController.text.trim().toUpperCase(),
                  hargaBeli: double.tryParse(hargaBeliController.text) ?? 0,
                  hargaJual: double.tryParse(hargaJualController.text) ?? 0,
                  tanggal: selectedTimestamp,
                );

                if (stock == null) {
                  await _stokService.createStock(stockData);
                } else {
                  await _stokService.updateStock(stock.id, stockData);
                }

                setState(() {
                  _stocksFuture = _stokService.getAllStocks();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StocksPublic>(
      future: _stocksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final stocks = snapshot.data!.data;
          stocks.sort((a, b) =>
              b.tanggal.toDate().compareTo(a.tanggal.toDate())); // urut terbaru
          return ListView.builder(
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final stock = stocks[index];
              return ListTile(
                title: Text('Mata Uang: ${stock.kodeMataUang}'),
                subtitle: Text(
                  'Harga Beli: ${stock.hargaBeli.toStringAsFixed(2)} | '
                  'Harga Jual: ${stock.hargaJual.toStringAsFixed(2)}\n'
                  'Tanggal: ${stock.tanggal.toDate().toLocal().toString().split(' ')[0]}',
                ),
                onTap: () => _showStockForm(stock: stock),
              );
            },
          );
        } else {
          return const Center(child: Text('Tidak ada data'));
        }
      },
    );
  }
}
