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
  final TextEditingController _mataUangController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();

  bool _isJual = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _fetchDataFromFirestore();
  }

  Future<void> _fetchDataFromFirestore() async {
    try {
      final fetchedData = await _transaksiService.getAllTransaksis();
      setState(() {
        transaksiList = fetchedData;
      });
    } catch (e) {
      print(e);
    }
  }

  void _addOrUpdateTransaksi() async {
    if (_tanggalController.text.isNotEmpty &&
        _mataUangController.text.isNotEmpty &&
        _jumlahController.text.isNotEmpty &&
        _rateController.text.isNotEmpty) {
      Map<String, dynamic> transaksiData = {
        "timestamp": DateTime.parse(_tanggalController.text),
        "kode_mata_uang": _mataUangController.text,
        "kode_transaksi": _isJual ? "Jual" : "Beli",
        "jumlah_barang": double.parse(_jumlahController.text),
        "harga": double.parse(_rateController.text),
        "total_nominal": double.parse(_nominalController.text),
      };

      try {
        if (_editingId == null) {
          await _transaksiService.createTransaksi(transaksiData);
        } else {
          await _transaksiService.updateTransaksi(_editingId!, transaksiData);
          _editingId = null;
        }
        _fetchDataFromFirestore();
      } catch (e) {
        print(e);
      }
      _clearForm();
    }
  }

  void _editTransaksi(TransaksiPublic transaksi) {
    setState(() {
      _tanggalController.text =
          DateFormat('yyyy-MM-dd').format(transaksi.timestamp.toDate());
      _mataUangController.text = transaksi.kodeMataUang;
      _jumlahController.text = transaksi.jumlahBarang.toString();
      _rateController.text = transaksi.harga.toString();
      _nominalController.text = transaksi.totalNominal.toString();
      _isJual = transaksi.kodeTransaksi == "Jual";
      _editingId = transaksi.id;
    });
  }

  void _deleteTransaksi(String id) async {
    try {
      await _transaksiService.deleteTransaksi(id);
      _fetchDataFromFirestore();
    } catch (e) {
      print(e);
    }
  }

  void _clearForm() {
    _tanggalController.clear();
    _mataUangController.clear();
    _jumlahController.clear();
    _rateController.clear();
    _nominalController.clear();
    _isJual = false;
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
    _nominalController.text = nominal.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _tanggalController,
            readOnly: true,
            onTap: () => _selectDate(context),
            decoration: InputDecoration(
                labelText: 'Tanggal', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _mataUangController,
            decoration: InputDecoration(
                labelText: 'Mata Uang', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _jumlahController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateNominal(),
            decoration: InputDecoration(
                labelText: 'Jumlah Mata Uang', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _rateController,
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateNominal(),
            decoration: InputDecoration(
                labelText: 'Rate', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _nominalController,
            readOnly: true,
            decoration: InputDecoration(
                labelText: 'Nominal Transaksi', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                  value: _isJual,
                  onChanged: (val) => setState(() => _isJual = val!)),
              Text('Jual'),
            ],
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: _addOrUpdateTransaksi,
            child: Text(_editingId == null ? 'Input' : 'Update'),
          ),
          SizedBox(height: 16),
          Expanded(
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
                      icon: Icon(Icons.delete, color: Colors.red),
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
    );
  }
}
