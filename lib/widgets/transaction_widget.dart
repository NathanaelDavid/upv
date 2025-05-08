import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi_models.dart';
import '../util/transaksi_service.dart';

class TransactionWidget extends StatefulWidget {
  const TransactionWidget({super.key});

  @override
  _TransactionWidgetState createState() => _TransactionWidgetState();
}

class _TransactionWidgetState extends State<TransactionWidget> {
  List<TransaksiPublic> transaksiList = [];
  final TransaksiService _transaksiService = TransaksiService();

  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  final NumberFormat _formatter =
      NumberFormat.currency(locale: "id_ID", symbol: 'Rp ');

  String? _editingId;
  String _kodeTransaksi = 'Beli';
  String? _selectedMataUang;
  final List<String> _mataUangList = [
    'USD',
    'EUR',
    'JPY',
    'IDR',
    'SGD'
  ]; // Ganti sesuai data kamu

  @override
  void initState() {
    super.initState();
    _fetchDataFromFirestore();
  }

  Future<void> _fetchDataFromFirestore() async {
    try {
      final fetchedData = await _transaksiService.getAllTransaksi();
      setState(() {
        transaksiList = fetchedData;
      });
    } catch (e) {
      print('Fetch Error: $e');
    }
  }

  void _addOrUpdateTransaksi() async {
    try {
      final tanggal = _tanggalController.text;
      final mataUang = _selectedMataUang;
      final jumlah = double.tryParse(_jumlahController.text);
      final rate = double.tryParse(_rateController.text);
      final nominal = jumlah != null && rate != null ? jumlah * rate : null;

      if (tanggal.isEmpty ||
          mataUang == null ||
          jumlah == null ||
          rate == null ||
          nominal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua field harus diisi dengan benar')),
        );
        return;
      }

      Map<String, dynamic> transaksiData = {
        "timestamp": DateTime.parse(tanggal),
        "kode_mata_uang": mataUang,
        "kode_transaksi": _kodeTransaksi,
        "jumlah_barang": jumlah,
        "harga": rate,
        "total_nominal": nominal,
      };

      if (_editingId == null) {
        await _transaksiService.createTransaksi(transaksiData);
      } else {
        await _transaksiService.updateTransaksi(_editingId!, transaksiData);
      }

      _clearForm();
      await _fetchDataFromFirestore();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_editingId == null
                ? 'Transaksi ditambahkan!'
                : 'Transaksi diperbarui!')),
      );
    } catch (e) {
      print('Add/Update Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _editTransaksi(TransaksiPublic transaksi) {
    setState(() {
      _tanggalController.text =
          DateFormat('yyyy-MM-dd').format(transaksi.timestamp.toDate());
      _selectedMataUang = transaksi.kodeMataUang;
      _jumlahController.text = transaksi.jumlahBarang.toString();
      _rateController.text = transaksi.harga.toString();
      _nominalController.text = _formatter.format(transaksi.totalNominal);
      _kodeTransaksi = transaksi.kodeTransaksi;
      _editingId = transaksi.id;
    });
  }

  void _deleteTransaksi(String id) async {
    try {
      await _transaksiService.deleteTransaksi(id);
      await _fetchDataFromFirestore();
    } catch (e) {
      print('Delete Error: $e');
    }
  }

  void _clearForm() {
    _tanggalController.clear();
    _selectedMataUang = null;
    _jumlahController.clear();
    _rateController.clear();
    _nominalController.clear();
    _kodeTransaksi = 'Beli';
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
      setState(() {
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _calculateNominal() {
    final jumlah = double.tryParse(_jumlahController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final nominal = jumlah * rate;
    _nominalController.text = _formatter.format(nominal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: ListView(
                children: [
                  TextField(
                    controller: _tanggalController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Beli'),
                          value: _kodeTransaksi == 'Beli',
                          onChanged: (bool? value) {
                            if (value == true) {
                              setState(() => _kodeTransaksi = 'Beli');
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Jual'),
                          value: _kodeTransaksi == 'Jual',
                          onChanged: (bool? value) {
                            if (value == true) {
                              setState(() => _kodeTransaksi = 'Jual');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedMataUang,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Mata Uang',
                      border: OutlineInputBorder(),
                    ),
                    items: _mataUangList
                        .map((kode) => DropdownMenuItem(
                              value: kode,
                              child: Text(kode),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMataUang = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateNominal(),
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Mata Uang',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateNominal(),
                    decoration: const InputDecoration(
                      labelText: 'Rate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nominalController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Nominal Transaksi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addOrUpdateTransaksi,
                      child: Text(_editingId == null ? 'Input' : 'Update'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: transaksiList.length,
                itemBuilder: (context, index) {
                  final transaksi = transaksiList[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                          '${transaksi.kodeMataUang} - ${transaksi.kodeTransaksi}'),
                      subtitle: Text(
                          'Tanggal: ${DateFormat('yyyy-MM-dd').format(transaksi.timestamp.toDate())}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTransaksi(transaksi.id),
                      ),
                      onTap: () => _editTransaksi(transaksi),
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
