import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models_stok.dart';
import '../util/stok_service.dart';

class InputStokWidget extends StatefulWidget {
  const InputStokWidget({super.key});

  @override
  _InputStokWidgetState createState() => _InputStokWidgetState();
}

class _InputStokWidgetState extends State<InputStokWidget> {
  final StokService _stokService = StokService();
  final List<StockPublic> stokList = [];

  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _kodeMataUangController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _hargaBeliController = TextEditingController();
  final TextEditingController _hargaJualController = TextEditingController();

  String? _editingId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _stokService.getAllStocks();
      setState(() {
        stokList.clear();
        stokList.addAll(data.data);
      });
    } catch (e) {
      print("Fetch Error: $e");
    }
  }

  void _clearForm() {
    _tanggalController.clear();
    _kodeMataUangController.clear();
    _jumlahController.clear();
    _hargaBeliController.clear();
    _hargaJualController.clear();
    _editingId = null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _addOrUpdateStok() async {
    try {
      final tanggal = _tanggalController.text;
      final kodeMataUang = _kodeMataUangController.text;
      final jumlah = double.tryParse(_jumlahController.text);
      final hargaBeli = double.tryParse(_hargaBeliController.text);
      final hargaJual = double.tryParse(_hargaJualController.text);

      if (tanggal.isEmpty ||
          kodeMataUang.isEmpty ||
          jumlah == null ||
          hargaBeli == null ||
          hargaJual == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua field wajib diisi!')),
        );
        return;
      }

      final stock = StockCreate(
        kodeMataUang: kodeMataUang,
        jumlahStok: jumlah,
        hargaBeli: hargaBeli,
        hargaJual: hargaJual,
        tanggal: Timestamp.fromDate(DateTime.parse(tanggal)),
      );

      if (_editingId == null) {
        await _stokService.createStock(stock);
      } else {
        await _stokService.updateStock(_editingId!, stock);
      }

      await _fetchData();
      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _editingId == null ? 'Stok ditambahkan!' : 'Stok diperbarui!')),
      );
    } catch (e) {
      print("Add/Update Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _editStok(StockPublic stok) {
    setState(() {
      _tanggalController.text =
          DateFormat('yyyy-MM-dd').format(stok.tanggal.toDate());
      _kodeMataUangController.text = stok.kodeMataUang;
      _jumlahController.text = stok.jumlahStok.toString();
      _hargaBeliController.text = stok.hargaBeli.toString();
      _hargaJualController.text = stok.hargaJual.toString();
      _editingId = stok.id;
    });
  }

  void _deleteStok(String id) async {
    try {
      await _stokService.deleteStock(id);
      await _fetchData();
    } catch (e) {
      print("Delete Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Stok')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _tanggalController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: const InputDecoration(
                  labelText: 'Tanggal', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _kodeMataUangController,
              decoration: const InputDecoration(
                  labelText: 'Kode Mata Uang', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Jumlah', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hargaBeliController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Harga Beli', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hargaJualController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Harga Jual', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addOrUpdateStok,
                child: Text(_editingId == null ? 'Input' : 'Update'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: stokList.length,
                itemBuilder: (context, index) {
                  final stok = stokList[index];
                  return Card(
                    child: ListTile(
                      title: Text('${stok.kodeMataUang}'),
                      subtitle: Text(
                          'Tanggal: ${DateFormat('yyyy-MM-dd').format(stok.tanggal.toDate())}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteStok(stok.id),
                      ),
                      onTap: () => _editStok(stok),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
