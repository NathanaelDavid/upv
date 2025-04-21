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
    final jumlahController =
        TextEditingController(text: stock?.jumlahStok.toString() ?? '');
    final hargaBeliController =
        TextEditingController(text: stock?.hargaBeli.toString() ?? '');
    final hargaJualController =
        TextEditingController(text: stock?.hargaJual.toString() ?? '');

    Timestamp selectedTimestamp = stock?.tanggal ?? Timestamp.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(stock == null ? 'Tambah Stok' : 'Update Stok'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: kodeController,
                    decoration: InputDecoration(labelText: 'Kode Mata Uang')),
                TextField(
                    controller: jumlahController,
                    decoration: InputDecoration(labelText: 'Jumlah Stok'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: hargaBeliController,
                    decoration: InputDecoration(labelText: 'Harga Beli'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: hargaJualController,
                    decoration: InputDecoration(labelText: 'Harga Jual'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                        "Tanggal: ${selectedTimestamp.toDate().toLocal().toString().split(' ')[0]}"),
                    const Spacer(),
                    TextButton(
                      child: Text("Pilih Tanggal"),
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
                child: Text('Batal'),
                onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: Text(stock == null ? 'Tambah' : 'Update'),
              onPressed: () async {
                if (kodeController.text.isEmpty ||
                    jumlahController.text.isEmpty ||
                    hargaBeliController.text.isEmpty ||
                    hargaJualController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Semua field harus diisi!')));
                  return;
                }

                final newStock = StockPublic(
                  id: stock?.id ?? '',
                  kodeMataUang: kodeController.text,
                  jumlahStok: double.tryParse(jumlahController.text) ?? 0,
                  hargaBeli: double.tryParse(hargaBeliController.text) ?? 0,
                  hargaJual: double.tryParse(hargaJualController.text) ?? 0,
                  tanggal: selectedTimestamp,
                );

                if (stock == null) {
                  await _stokService.createStock(StockCreate(
                    kodeMataUang: newStock.kodeMataUang,
                    jumlahStok: newStock.jumlahStok,
                    hargaBeli: newStock.hargaBeli,
                    hargaJual: newStock.hargaJual,
                    tanggal: newStock.tanggal,
                  ));
                } else {
                  await _stokService.updateStock(
                    stock.id,
                    StockCreate(
                      kodeMataUang: newStock.kodeMataUang,
                      jumlahStok: newStock.jumlahStok,
                      hargaBeli: newStock.hargaBeli,
                      hargaJual: newStock.hargaJual,
                      tanggal: newStock.tanggal,
                    ),
                  );
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
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final stocks = snapshot.data!.data;
          return ListView.builder(
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final stock = stocks[index];
              return ListTile(
                title: Text('Mata Uang: ${stock.kodeMataUang}'),
                subtitle: Text(
                    'Jumlah: ${stock.jumlahStok} | Beli: ${stock.hargaBeli} | Jual: ${stock.hargaJual}\nTanggal: ${stock.tanggal.toDate().toLocal().toString().split(' ')[0]}'),
                onTap: () => _showStockForm(stock: stock),
              );
            },
          );
        } else {
          return Center(child: Text('Tidak ada data'));
        }
      },
    );
  }
}
