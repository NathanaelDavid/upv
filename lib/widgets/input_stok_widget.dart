import 'package:flutter/material.dart';
import '../models/models_stok.dart';
import '../util/stok_service.dart';

class InputStokWidget extends StatefulWidget {
  const InputStokWidget({super.key});

  @override
  State<InputStokWidget> createState() => _InputStokWidgetState();
}

class _InputStokWidgetState extends State<InputStokWidget> {
  final _formKey = GlobalKey<FormState>();
  final _kodeMataUangController = TextEditingController();
  final _jumlahStokController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final StokService _stokService = StokService();

  @override
  void dispose() {
    _kodeMataUangController.dispose();
    _jumlahStokController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    super.dispose();
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      final newStock = StockCreate(
        kodeMataUang: _kodeMataUangController.text,
        jumlahStok: double.parse(_jumlahStokController.text),
        hargaBeli: double.parse(_hargaBeliController.text),
        hargaJual: double.parse(_hargaJualController.text),
      );

      try {
        await _stokService.createStock(newStock);

        _formKey.currentState!.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok berhasil ditambahkan!')),
        );
        setState(() {});
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah stok: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Stok')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _kodeMataUangController,
                decoration: const InputDecoration(labelText: 'Kode Mata Uang'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kode mata uang tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _jumlahStokController,
                decoration: const InputDecoration(labelText: 'Jumlah Stok'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah stok tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _hargaBeliController,
                decoration: const InputDecoration(labelText: 'Harga Beli'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga beli tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _hargaJualController,
                decoration: const InputDecoration(labelText: 'Harga Jual'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga jual tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitData,
                child: const Text('Tambah Stok'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
