import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk Timestamp.fromDate()
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

  // KEMBALIKAN: _tanggalController diperlukan lagi
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();

  final NumberFormat _formatter =
      NumberFormat.currency(locale: "id_ID", symbol: 'Rp ');
  final NumberFormat _qtyFormatter = NumberFormat("#,##0.##", "id_ID");

  String? _editingId;
  String _kodeTransaksi = 'Beli';
  String? _selectedMataUang;
  final List<String> _mataUangList = [
    'usd',
    'eur',
    'jpy',
    'myr',
    'sgd',
    'bnd',
    'sar',
    'thb',
    'hkd'
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ISI OTOMATIS: Tanggal hari ini saat widget pertama kali dimuat
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchDataFromFirestore();
  }

  @override
  void dispose() {
    // KEMBALIKAN: _tanggalController.dispose();
    _tanggalController.dispose();
    _jumlahController.dispose();
    _rateController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataFromFirestore() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedData = await _transaksiService.getAllTransaksi();
      if (mounted) {
        setState(() {
          transaksiList = fetchedData;
        });
      }
    } catch (e) {
      print('Fetch Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addOrUpdateTransaksi() async {
    // KEMBALIKAN: Validasi untuk tanggal
    if (_tanggalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal harus diisi')),
      );
      return;
    }
    if (_selectedMataUang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata uang terlebih dahulu')),
      );
      return;
    }
    if (_jumlahController.text.isEmpty || _rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah dan Rate harus diisi')),
      );
      return;
    }

    // KEMBALIKAN: Parsing tanggal dari controller
    DateTime parsedDate;
    try {
      parsedDate =
          DateFormat('yyyy-MM-dd').parseStrict(_tanggalController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Format tanggal tidak valid. Gunakan yyyy-MM-dd')),
      );
      return;
    }

    final mataUang = _selectedMataUang;
    final jumlah = double.tryParse(
        _jumlahController.text.replaceAll('.', '').replaceAll(',', '.'));
    final rate = double.tryParse(
        _rateController.text.replaceAll('.', '').replaceAll(',', '.'));

    if (jumlah == null || rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Jumlah dan Rate harus berupa angka yang valid')),
      );
      return;
    }
    final nominal = jumlah * rate;

    // Map sekarang selalu menyertakan timestamp dari controller
    Map<String, dynamic> transaksiData = {
      "timestamp": Timestamp.fromDate(parsedDate), // Selalu dari controller
      "kode_mata_uang": mataUang,
      "kode_transaksi": _kodeTransaksi,
      "jumlah_barang": jumlah,
      "harga": rate,
      "total_nominal": nominal,
    };

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    String? originalEditingId = _editingId;

    try {
      if (originalEditingId == null) {
        await _transaksiService.createTransaksi(transaksiData);
      } else {
        await _transaksiService.updateTransaksi(
            originalEditingId, transaksiData);
      }

      _clearForm(); // Ini akan mengisi tanggal dengan hari ini
      await _fetchDataFromFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(originalEditingId == null
                  ? 'Transaksi berhasil ditambahkan!'
                  : 'Transaksi berhasil diperbarui!')),
        );
      }
    } catch (e) {
      print('Add/Update Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat menyimpan: $e')),
        );
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editTransaksi(TransaksiPublic transaksi) {
    if (!mounted) return;
    setState(() {
      // KEMBALIKAN: Isi _tanggalController dengan tanggal transaksi yang diedit
      _tanggalController.text =
          DateFormat('yyyy-MM-dd').format(transaksi.timestamp.toDate());

      final String dbCurrencyCode = transaksi.kodeMataUang.toLowerCase();

      if (_mataUangList.contains(dbCurrencyCode)) {
        _selectedMataUang = dbCurrencyCode;
      } else {
        _selectedMataUang = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Mata uang "${transaksi.kodeMataUang}" tidak ada dalam pilihan. Silakan pilih ulang.'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }

      _jumlahController.text =
          transaksi.jumlahBarang.toString().replaceAll('.', ',');
      _rateController.text = transaksi.harga.toString().replaceAll('.', ',');
      _nominalController.text = _formatter.format(transaksi.totalNominal);
      _kodeTransaksi = transaksi.kodeTransaksi;
      _editingId = transaksi.id;
    });
  }

  Future<void> _confirmDeleteTransaksi(String id) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content:
              const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      _deleteTransaksi(id);
    }
  }

  void _deleteTransaksi(String id) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await _transaksiService.deleteTransaksi(id);
      await _fetchDataFromFirestore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus!')),
        );
      }
    } catch (e) {
      print('Delete Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus transaksi: $e')),
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    // KEMBALIKAN: _tanggalController.clear();
    _tanggalController.clear();
    _jumlahController.clear();
    _rateController.clear();
    _nominalController.clear();
    if (mounted) {
      setState(() {
        // ISI OTOMATIS: Tanggal hari ini setelah form dibersihkan
        _tanggalController.text =
            DateFormat('yyyy-MM-dd').format(DateTime.now());
        _selectedMataUang = null;
        _kodeTransaksi = 'Beli';
        _editingId = null;
      });
    }
  }

  // KEMBALIKAN: Metode _selectDate()
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      // Coba parse tanggal yang ada di controller, jika gagal atau kosong, gunakan hari ini
      initialDate: _tanggalController.text.isNotEmpty
          ? (DateFormat('yyyy-MM-dd').tryParse(_tanggalController.text) ??
              DateTime.now())
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101), // Bisa disesuaikan
    );
    if (picked != null && mounted) {
      setState(() {
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _calculateNominal() {
    final jumlah = double.tryParse(
            _jumlahController.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0.0;
    final rate = double.tryParse(
            _rateController.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0.0;
    final nominal = jumlah * rate;
    if (mounted) {
      _nominalController.text = _formatter.format(nominal);
    }
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // KEMBALIKAN: TextField untuk tanggal
        TextField(
          controller: _tanggalController,
          readOnly: true, // Tetap readOnly, diedit via date picker
          onTap: () => _selectDate(context),
          decoration: InputDecoration(
            labelText: 'Tanggal Transaksi',
            hintText: 'Pilih Tanggal',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
            ),
          ),
        ),
        const SizedBox(height: 12), // SizedBox terkait dikembalikan

        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Beli'),
                value: 'Beli',
                groupValue: _kodeTransaksi,
                onChanged: (String? value) {
                  if (value != null && mounted) {
                    setState(() => _kodeTransaksi = value);
                  }
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Jual'),
                value: 'Jual',
                groupValue: _kodeTransaksi,
                onChanged: (String? value) {
                  if (value != null && mounted) {
                    setState(() => _kodeTransaksi = value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedMataUang,
          decoration: const InputDecoration(
            labelText: 'Pilih Mata Uang',
            border: OutlineInputBorder(),
          ),
          items: _mataUangList
              .map((kode) => DropdownMenuItem(
                    value: kode,
                    child: Text(kode.toUpperCase()),
                  ))
              .toList(),
          onChanged: (value) {
            if (mounted) {
              setState(() {
                _selectedMataUang = value;
              });
            }
          },
          validator: (value) => value == null ? 'Pilih mata uang' : null,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _jumlahController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _calculateNominal(),
          decoration: const InputDecoration(
            labelText: 'Jumlah Mata Uang',
            hintText: 'Contoh: 1000 atau 1.000,50',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _rateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => _calculateNominal(),
          decoration: const InputDecoration(
            labelText: 'Rate (Harga per unit mata uang)',
            hintText: 'Contoh: 15000 atau 15.000,75',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nominalController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Nominal Transaksi (Rp)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.black12,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
          onPressed: _isLoading ? null : _addOrUpdateTransaksi,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white))
              : Text(
                  _editingId == null ? 'Input Transaksi' : 'Update Transaksi'),
        ),
        if (_editingId != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading ? null : _clearForm,
            child: const Text('Batal Edit / Bersihkan Form'),
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_isLoading && transaksiList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (transaksiList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Belum ada transaksi.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transaksiList.length,
      itemBuilder: (context, index) {
        final transaksi = transaksiList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            title: Text(
              '${transaksi.kodeTransaksi} ${transaksi.kodeMataUang.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(transaksi.timestamp.toDate())}'),
                Text(
                    'Jumlah: ${_qtyFormatter.format(transaksi.jumlahBarang)} ${transaksi.kodeMataUang.toUpperCase()}'),
                Text('Rate: ${_formatter.format(transaksi.harga)}'),
                Text('Total: ${_formatter.format(transaksi.totalNominal)}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Hapus Transaksi',
              onPressed: _isLoading
                  ? null
                  : () => _confirmDeleteTransaksi(transaksi.id),
            ),
            onTap: _isLoading ? null : () => _editTransaksi(transaksi),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Transaksi Valas'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Material(
                      elevation: 2.0,
                      borderRadius: BorderRadius.circular(8.0),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildForm(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _buildTransactionList(),
                  ),
                ],
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Material(
                      elevation: 1.0,
                      borderRadius: BorderRadius.circular(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildForm(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text("Riwayat Transaksi",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    _buildTransactionList(),
                  ],
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _fetchDataFromFirestore,
        tooltip: 'Muat Ulang Data',
        icon: const Icon(Icons.refresh),
        label: const Text("Refresh"),
      ),
    );
  }
}
