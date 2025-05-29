import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for TextInputFormatter
import 'package:intl/intl.dart';
import '../models/models_stok.dart';
import '../util/stok_service.dart';

// Helper class to enforce lowercase input
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}

class InputStokWidget extends StatefulWidget {
  final VoidCallback onStokChanged;

  const InputStokWidget({super.key, required this.onStokChanged});

  @override
  _InputStokWidgetState createState() => _InputStokWidgetState();
}

class _InputStokWidgetState extends State<InputStokWidget> {
  final StokService _stokService = StokService();
  final List<StockPublic> stokList = [];

  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _kodeMataUangController = TextEditingController();
  final TextEditingController _hargaBeliController = TextEditingController();
  final TextEditingController _hargaJualController = TextEditingController();

  List<String> _mataUangList = [];
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchMataUangList();
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _kodeMataUangController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    super.dispose();
  }

  Future<void> _fetchMataUangList() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('mata_uang').get();
      if (!mounted) return;
      setState(() {
        _mataUangList = snapshot.docs
            .map((doc) => doc['kode'].toString().toLowerCase())
            .where((kode) => kode.isNotEmpty) // Ensure no empty codes
            .toSet() // Ensure uniqueness
            .toList(); // Convert to list
      });
    } catch (e) {
      print("Fetch mata uang error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar mata uang: $e')),
        );
      }
    }
  }

  Future<void> _fetchData() async {
    try {
      final data = await _stokService.getAllStocks();
      if (!mounted) return;
      setState(() {
        stokList.clear();
        stokList.addAll(data.data);
      });
    } catch (e) {
      print("Fetch Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data stok: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _tanggalController.clear();
    _kodeMataUangController.clear(); // This will be lowercase
    _hargaBeliController.clear();
    _hargaJualController.clear();
    setState(() {
      // Ensure UI reflects _editingId change
      _editingId = null;
    });
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
    if (!mounted) return;
    try {
      final tanggal = _tanggalController.text;
      // _kodeMataUangController.text is already lowercase due to formatter and selection logic
      final kodeMataUang = _kodeMataUangController.text;
      final hargaBeli = double.tryParse(_hargaBeliController.text);
      final hargaJual = double.tryParse(_hargaJualController.text);

      if (tanggal.isEmpty ||
          kodeMataUang.isEmpty ||
          hargaBeli == null ||
          hargaJual == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua field wajib diisi!')),
        );
        return;
      }

      final stock = StockCreate(
        kodeMataUang: kodeMataUang, // Already lowercase
        hargaBeli: hargaBeli,
        hargaJual: hargaJual,
        tanggal: Timestamp.fromDate(DateTime.parse(tanggal)),
      );

      if (_editingId == null) {
        await _stokService.createStock(stock);
      } else {
        await _stokService.updateStock(_editingId!, stock);
      }

      await _fetchData(); // Refreshes stokList
      _clearForm();
      widget.onStokChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _editingId == null ? 'Stok ditambahkan!' : 'Stok diperbarui!'),
        ),
      );
    } catch (e) {
      print("Add/Update Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _editStok(StockPublic stok) {
    setState(() {
      _tanggalController.text =
          DateFormat('yyyy-MM-dd').format(stok.tanggal.toDate());
      // Assuming stok.kodeMataUang from StokService is already lowercase
      _kodeMataUangController.text = stok.kodeMataUang;
      _hargaBeliController.text = stok.hargaBeli.toString();
      _hargaJualController.text = stok.hargaJual.toString();
      _editingId = stok.id;
    });
  }

  void _showDeleteConfirmationDialog(String id, String kodeMataUang) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Anda yakin ingin menghapus stok $kodeMataUang?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(ctx).pop();
                _deleteStok(id);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteStok(String id) async {
    if (!mounted) return;
    try {
      await _stokService.deleteStock(id);
      await _fetchData(); // Refreshes stokList
      widget.onStokChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok berhasil dihapus!')),
      );
    } catch (e) {
      print("Delete Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus stok: $e')),
      );
    }
  }

  // Helper method to build the form section
  Widget _buildFormSection(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
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
            const SizedBox(height: 12),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return _mataUangList.isEmpty
                      ? const Iterable<String>.empty()
                      : _mataUangList;
                }
                return _mataUangList.where((String option) {
                  return option.contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                // _mataUangList is already lowercase, so selection is lowercase
                setState(() {
                  // Use setState to ensure UI updates if dependent widgets need it
                  _kodeMataUangController.text = selection;
                });
              },
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                // Sync from _kodeMataUangController to the field when builder runs
                // This ensures that if _kodeMataUangController is set (e.g. by _editStok or onSelected),
                // the field reflects this value.
                if (textEditingController.text !=
                    _kodeMataUangController.text) {
                  textEditingController.value =
                      textEditingController.value.copyWith(
                    text: _kodeMataUangController
                        .text, // This should be lowercase
                    selection: TextSelection.fromPosition(TextPosition(
                        offset: _kodeMataUangController.text.length)),
                  );
                }

                // Listener to update _kodeMataUangController from the field's input
                // This listener is on Autocomplete's internal controller.
                // The LowerCaseTextFormatter will ensure textEditingController.text is lowercase.
                // Adding/removing listeners here can be complex. The formatter simplifies things.
                // The existing listener pattern in the original code:
                // textEditingController.removeListener(_syncKodeMataUangFromField); // Hypothetical removal
                // _syncKodeMataUangFromField = () { ... }; // Hypothetical assignment
                // textEditingController.addListener(_syncKodeMataUangFromField);
                // For simplicity, we rely on the formatter and the sync at the beginning of fieldViewBuilder.
                // If direct typing needs to update _kodeMataUangController immediately without selection:
                // One simple way is to use onFieldSubmitted or handle it via the TextField's onChanged if Autocomplete allowed direct TextField customization.
                // With current Autocomplete, the formatter is key.
                // The original listener:
                textEditingController.addListener(() {
                  // If the formatter is active, textEditingController.text will be lowercase.
                  if (_kodeMataUangController.text !=
                      textEditingController.text) {
                    _kodeMataUangController.text = textEditingController.text;
                  }
                });

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                      labelText: 'Kode Mata Uang',
                      border: OutlineInputBorder()),
                  inputFormatters: [
                    LowerCaseTextFormatter()
                  ], // Ensures input is lowercase
                  onSubmitted: (_) =>
                      onFieldSubmitted(), // Call onFieldSubmitted if user presses done
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hargaBeliController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Harga Beli', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hargaJualController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Harga Jual', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addOrUpdateStok,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(_editingId == null ? 'Input Stok' : 'Update Stok',
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the list section
  Widget _buildListSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: Text(
            'Daftar Stok (${stokList.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: stokList.isEmpty
              ? const Center(child: Text('Belum ada data stok.'))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  itemCount: stokList.length,
                  itemBuilder: (context, index) {
                    final stok = stokList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 5.0),
                      child: ListTile(
                        title: Text(
                            stok.kodeMataUang
                                .toUpperCase(), // Display as uppercase for readability
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Tgl: ${DateFormat('dd MMM yyyy').format(stok.tanggal.toDate())} | Beli: ${NumberFormat.decimalPattern('id_ID').format(stok.hargaBeli)} | Jual: ${NumberFormat.decimalPattern('id_ID').format(stok.hargaJual)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          tooltip: 'Hapus Stok',
                          onPressed: () => _showDeleteConfirmationDialog(
                              stok.id, stok.kodeMataUang),
                        ),
                        onTap: () => _editStok(stok),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use a fixed height or allow it to be flexible based on parent constraints.
    // The SizedBox with a percentage of screen height might be too restrictive on mobile
    // if content overflows. Consider removing it or making it conditional.
    // For now, keeping it as per original structure.
    return SizedBox(
      height:
          MediaQuery.of(context).size.height * 0.85, // Adjusted height slightly
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Define a breakpoint for mobile layout
          bool isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            // Mobile layout: Form on top, List below
            return Column(
              children: [
                _buildFormSection(
                    context), // This section will scroll if content is too long
                const Divider(height: 1),
                Expanded(
                    child: _buildListSection(
                        context)), // List takes remaining space
              ],
            );
          } else {
            // Desktop layout: Form on left, List on right
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2, // Form takes 2 parts of the space
                  child: _buildFormSection(context),
                ),
                const VerticalDivider(width: 1),
                Flexible(
                  flex: 3, // List takes 3 parts of the space
                  child: _buildListSection(context),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
