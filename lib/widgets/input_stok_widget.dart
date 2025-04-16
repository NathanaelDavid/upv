import 'package:flutter/material.dart';
import '../models/models_stok.dart';
import '../util/stok_service.dart';

class InputStokWidget extends StatefulWidget {
  final StockPublic? existingStock;
  const InputStokWidget({super.key, this.existingStock});

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
  void initState() {
    super.initState();
    if (widget.existingStock != null) {
      _kodeMataUangController.text = widget.existingStock!.kodeMataUang;
      _jumlahStokController.text = widget.existingStock!.jumlahStok.toString();
      _hargaBeliController.text = widget.existingStock!.hargaBeli.toString();
      _hargaJualController.text = widget.existingStock!.hargaJual.toString();
    }
  }

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
        kodeMataUang: _kodeMataUangController.text.trim(),
        jumlahStok: double.tryParse(_jumlahStokController.text.trim()) ?? 0.0,
        hargaBeli: double.tryParse(_hargaBeliController.text.trim()) ?? 0.0,
        hargaJual: double.tryParse(_hargaJualController.text.trim()) ?? 0.0,
      );

      try {
        if (widget.existingStock == null) {
          await _stokService.createStock(newStock);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stok berhasil ditambahkan!')),
          );
        } else {
          await _stokService.updateStock(widget.existingStock!.id, newStock);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stok berhasil diperbarui!')),
          );
        }
        Navigator.pop(context);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operasi gagal: $error')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingStock == null ? 'Tambah Stok' : 'Edit Stok'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _kodeMataUangController,
                decoration: _inputDecoration('Kode Mata Uang'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jumlahStokController,
                decoration: _inputDecoration('Jumlah Stok'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? 'Tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hargaBeliController,
                decoration: _inputDecoration('Harga Beli'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? 'Tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hargaJualController,
                decoration: _inputDecoration('Harga Jual'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? 'Tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(widget.existingStock == null
                      ? 'Tambah Stok'
                      : 'Update Stok'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
