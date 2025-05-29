// lib/widgets/input_transaksi_widget.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi_models.dart'; // Pastikan path ini benar

// --- Model untuk setiap baris item transaksi ---
class TransactionItemInputModel {
  String id;
  String? firestoreDocId;
  TextEditingController tanggalController;
  TextEditingController jumlahController;
  TextEditingController rateController;
  TextEditingController nominalController;
  String kodeTransaksi;
  String? selectedMataUang;

  static final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: "id_ID", symbol: 'Rp ', decimalDigits: 0);
  static final NumberFormat _numberFormatter =
      NumberFormat.decimalPattern('id_ID');

  TransactionItemInputModel({
    this.firestoreDocId,
    String? initialTanggal,
    String? initialKodeTransaksi,
    String? initialSelectedMataUang,
    double? initialJumlah,
    double? initialRate,
  })  : id = UniqueKey().toString(),
        tanggalController = TextEditingController(
            text: initialTanggal ??
                DateFormat('yyyy-MM-dd').format(DateTime.now())),
        jumlahController = TextEditingController(
            text: initialJumlah != null
                ? _numberFormatter.format(initialJumlah)
                : ''),
        rateController = TextEditingController(
            text: initialRate != null
                ? _numberFormatter.format(initialRate)
                : ''),
        nominalController = TextEditingController(),
        kodeTransaksi = initialKodeTransaksi ?? 'Beli',
        selectedMataUang = initialSelectedMataUang {
    jumlahController.addListener(_calculateNominal);
    rateController.addListener(_calculateNominal);
    if (initialJumlah != null && initialRate != null) {
      _calculateNominal();
    }
  }

  factory TransactionItemInputModel.fromTransaksiPublic(
      TransaksiPublic trx, List<String> validMataUang) {
    String trxMataUangLower = trx.kodeMataUang.toLowerCase();
    String? validSelectedMataUang =
        validMataUang.contains(trxMataUangLower) ? trxMataUangLower : null;
    if (validSelectedMataUang == null && trx.kodeMataUang.isNotEmpty) {
      print(
          "Warning: Mata uang '${trx.kodeMataUang}' dari TransaksiPublic (id: ${trx.id}) tidak ada di daftar mata uang valid: $validMataUang. Menggunakan null.");
    }

    return TransactionItemInputModel(
      firestoreDocId: trx.id,
      initialTanggal: DateFormat('yyyy-MM-dd').format(trx.timestamp.toDate()),
      initialKodeTransaksi: trx.kodeTransaksi,
      initialSelectedMataUang: validSelectedMataUang,
      initialJumlah: trx.jumlahBarang,
      initialRate: trx.harga,
    );
  }

  void _calculateNominal() {
    final jumlah = double.tryParse(
            jumlahController.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0.0;
    final rate = double.tryParse(
            rateController.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0.0;
    final nominal = jumlah * rate;
    final formattedNominal = _currencyFormatter.format(nominal);
    if (nominalController.value.text != formattedNominal) {
      nominalController.text = formattedNominal;
    }
  }

  Map<String, dynamic>? toMap() {
    final tanggal = tanggalController.text;
    final mataUang = selectedMataUang;
    final jumlah = double.tryParse(
        jumlahController.text.replaceAll('.', '').replaceAll(',', '.'));
    final rate = double.tryParse(
        rateController.text.replaceAll('.', '').replaceAll(',', '.'));

    if (tanggal.isEmpty ||
        mataUang == null ||
        jumlah == null ||
        rate == null ||
        jumlah <= 0 ||
        rate <= 0) {
      print(
          "Validation failed in toMap: tanggal=$tanggal, mataUang=$mataUang, jumlah=$jumlah, rate=$rate");
      return null;
    }
    final double nominalHitung = jumlah * rate;

    DateTime parsedDate;
    try {
      parsedDate = DateFormat('yyyy-MM-dd').parseStrict(tanggal);
    } catch (e) {
      print("Error parsing date: $e. Input: $tanggal");
      return null;
    }

    return {
      "timestamp": Timestamp.fromDate(parsedDate),
      "kode_mata_uang": mataUang,
      "kode_transaksi": kodeTransaksi,
      "jumlah_barang": jumlah,
      "harga": rate,
      "total_nominal": nominalHitung,
    };
  }

  void dispose() {
    jumlahController.removeListener(_calculateNominal);
    rateController.removeListener(_calculateNominal);
    tanggalController.dispose();
    jumlahController.dispose();
    rateController.dispose();
    nominalController.dispose();
  }
}
// --- Akhir Model ---

class InputTransaksiWidget extends StatefulWidget {
  final Function(List<Map<String, dynamic>> listTransaksiData) onSave;
  final VoidCallback? onClearAllRequest;
  final List<TransactionItemInputModel> initialItems;
  final bool isEditMode;
  final List<String> mataUangListSource;

  const InputTransaksiWidget({
    super.key,
    required this.onSave,
    this.onClearAllRequest,
    required this.initialItems,
    this.isEditMode = false,
    required this.mataUangListSource,
  });

  @override
  _InputTransaksiWidgetState createState() => _InputTransaksiWidgetState();
}

class _InputTransaksiWidgetState extends State<InputTransaksiWidget> {
  final _formKey = GlobalKey<FormState>();
  List<TransactionItemInputModel> _transactionItems = [];
  late List<String> _localMataUangList;

  @override
  void initState() {
    super.initState();
    _localMataUangList = List.from(widget.mataUangListSource);
    _initializeItems(widget.initialItems);
  }

  @override
  void didUpdateWidget(covariant InputTransaksiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mataUangListSource != oldWidget.mataUangListSource) {
      _localMataUangList = List.from(widget.mataUangListSource);
    }

    bool itemsChanged = widget.initialItems.length !=
            oldWidget.initialItems.length ||
        (widget.initialItems.isNotEmpty &&
            oldWidget.initialItems.isNotEmpty &&
            widget.initialItems.first.id != oldWidget.initialItems.first.id) ||
        (widget.initialItems.length == 1 &&
            oldWidget.initialItems.length == 1 &&
            widget.initialItems.first.firestoreDocId !=
                oldWidget.initialItems.first.firestoreDocId &&
            oldWidget.initialItems.first.firestoreDocId != null);

    if (itemsChanged || widget.isEditMode != oldWidget.isEditMode) {
      _initializeItems(widget.initialItems);
    }
  }

  void _initializeItems(List<TransactionItemInputModel> newItems) {
    for (var oldItem in _transactionItems) {
      if (!newItems.any((newItem) => newItem.id == oldItem.id)) {
        oldItem.dispose();
      }
    }
    _transactionItems = List.from(newItems);

    if (_transactionItems.isEmpty && !widget.isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _addNewTransactionItemLocally();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          bool needsSetState = false;
          for (var item in _transactionItems) {
            if (item.selectedMataUang != null &&
                !_localMataUangList.contains(item.selectedMataUang)) {
              item.selectedMataUang = null;
              needsSetState = true;
            }
          }
          if (needsSetState) {
            setState(() {});
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (var item in _transactionItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewTransactionItemLocally() {
    if (widget.isEditMode) return;
    setState(() {
      _transactionItems.add(TransactionItemInputModel(
        initialTanggal: _transactionItems.isNotEmpty
            ? _transactionItems.last.tanggalController.text
            : null,
        initialKodeTransaksi: _transactionItems.isNotEmpty
            ? _transactionItems.last.kodeTransaksi
            : 'Beli',
        initialSelectedMataUang: null,
      ));
    });
  }

  void _removeTransactionItemLocally(String id) {
    if (widget.isEditMode && _transactionItems.length <= 1) return;

    setState(() {
      final itemIndex = _transactionItems.indexWhere((item) => item.id == id);
      if (itemIndex != -1) {
        _transactionItems[itemIndex].dispose();
        _transactionItems.removeAt(itemIndex);
      }
      if (_transactionItems.isEmpty && !widget.isEditMode) {
        _addNewTransactionItemLocally();
      }
    });
  }

  // --- METODE _handleSave YANG DIPERBARUI ---
  void _handleSave() {
    final currentContext = context; // Tangkap context sebelum operasi apapun
    FocusScope.of(currentContext)
        .unfocus(); // Unfocus menggunakan currentContext

    // Pastikan widget masih mounted setelah unfocus dan sebelum validasi
    if (!mounted) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        // Gunakan currentContext
        const SnackBar(
            content: Text('Harap perbaiki error pada form sebelum menyimpan.')),
      );
      return;
    }

    List<Map<String, dynamic>> allValidTransaksiData = [];
    bool allItemsValid = true;

    if (_transactionItems.isEmpty) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        // Gunakan currentContext
        const SnackBar(
            content: Text('Tidak ada item transaksi untuk disimpan.')),
      );
      return;
    }

    for (var item in _transactionItems) {
      final data = item.toMap();
      if (data != null) {
        allValidTransaksiData.add(data);
      } else {
        allItemsValid = false;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          // Gunakan currentContext
          const SnackBar(
              content: Text(
                  'Data tidak valid pada salah satu item. Pastikan jumlah & rate > 0 dan semua field terisi.')),
        );
        break;
      }
    }

    if (allItemsValid && allValidTransaksiData.isNotEmpty) {
      widget.onSave(
          allValidTransaksiData); // Pemanggilan ini bisa menyebabkan widget ini di-dispose
    } else if (allValidTransaksiData.isEmpty && allItemsValid) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        // Gunakan currentContext
        const SnackBar(
            content: Text('Tidak ada transaksi valid untuk disimpan.')),
      );
    }
    // Tidak ada operasi yang menggunakan 'context' atau 'mounted' setelah widget.onSave()
  }
  // --- AKHIR METODE _handleSave YANG DIPERBARUI ---

  Future<void> _selectDate(
      BuildContext context, TransactionItemInputModel item) async {
    final currentContext = context; // Tangkap context
    final DateTime? picked = await showDatePicker(
      context: currentContext,
      initialDate: item.tanggalController.text.isNotEmpty
          ? (DateFormat('yyyy-MM-dd').tryParse(item.tanggalController.text) ??
              DateTime.now())
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (!mounted) return; // Cek mounted setelah await
    if (picked != null) {
      setState(() {
        item.tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildTransactionItemRow(TransactionItemInputModel item, int index) {
    if (item.selectedMataUang != null &&
        !_localMataUangList.contains(item.selectedMataUang)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            item.selectedMataUang = null;
          });
        }
      });
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    widget.isEditMode
                        ? "Edit Transaksi"
                        : "Item Transaksi #${index + 1}",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (_transactionItems.length > 1 && !widget.isEditMode)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        color: Colors.red.shade400),
                    onPressed: () => _removeTransactionItemLocally(item.id),
                    tooltip: "Hapus item ini",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: item.tanggalController,
              readOnly: true,
              onTap: () => _selectDate(context, item),
              decoration: const InputDecoration(
                labelText: 'Tanggal',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, size: 20),
                isDense: true,
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: RadioListTile<String>(
                      title: const Text('Beli', style: TextStyle(fontSize: 14)),
                      value: 'Beli',
                      groupValue: item.kodeTransaksi,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        if (mounted && v != null) {
                          setState(() => item.kodeTransaksi = v);
                        }
                      })),
              Expanded(
                  child: RadioListTile<String>(
                      title: const Text('Jual', style: TextStyle(fontSize: 14)),
                      value: 'Jual',
                      groupValue: item.kodeTransaksi,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) {
                        if (mounted && v != null) {
                          setState(() => item.kodeTransaksi = v);
                        }
                      })),
            ]),
            const SizedBox(height: 2),
            DropdownButtonFormField<String>(
              value: item.selectedMataUang,
              decoration: const InputDecoration(
                  labelText: 'Mata Uang',
                  border: OutlineInputBorder(),
                  isDense: true),
              isExpanded: true,
              hint: const Text('Pilih Mata Uang...'),
              items: _localMataUangList
                  .map((kode) => DropdownMenuItem(
                      value: kode, child: Text(kode.toUpperCase())))
                  .toList(),
              onChanged: (value) {
                if (mounted && value != null) {
                  setState(() => item.selectedMataUang = value);
                }
              },
              validator: (v) => v == null ? 'Wajib dipilih' : null,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextFormField(
                controller: item.jumlahController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(),
                    isDense: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Isi';
                  final val = double.tryParse(
                      v.replaceAll('.', '').replaceAll(',', '.'));
                  if (val == null) return 'Angka invalid';
                  if (val <= 0) return '> 0';
                  return null;
                },
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: TextFormField(
                controller: item.rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Rate',
                    border: OutlineInputBorder(),
                    isDense: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Isi';
                  final val = double.tryParse(
                      v.replaceAll('.', '').replaceAll(',', '.'));
                  if (val == null) return 'Angka invalid';
                  if (val <= 0) return '> 0';
                  return null;
                },
              )),
            ]),
            const SizedBox(height: 10),
            TextFormField(
              controller: item.nominalController,
              readOnly: true,
              decoration: const InputDecoration(
                  labelText: 'Nominal',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFf0f0f0),
                  isDense: true),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                widget.isEditMode ? 'Edit Transaksi' : 'Input Multi Transaksi',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            if (_transactionItems.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactionItems.length,
                itemBuilder: (context, index) {
                  return _buildTransactionItemRow(
                      _transactionItems[index], index);
                },
              )
            else
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                      child: Text(widget.isEditMode
                          ? "Memuat data untuk diedit..."
                          : "Klik 'Tambah Item' untuk memulai."))),
            const SizedBox(height: 12),
            if (!widget.isEditMode)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon:
                        const Icon(Icons.add_circle_outline_rounded, size: 20),
                    label: const Text('Tambah Item'),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4)),
                    onPressed: _addNewTransactionItemLocally,
                  ),
                  if (_transactionItems.length > 1)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_sweep_outlined,
                          color: Colors.orangeAccent, size: 20),
                      label: const Text('Bersihkan Semua',
                          style: TextStyle(color: Colors.orangeAccent)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4)),
                      onPressed: () {
                        if (widget.onClearAllRequest != null) {
                          widget.onClearAllRequest!();
                        }
                      },
                    ),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined),
              label: Text(widget.isEditMode
                  ? 'Update Transaksi'
                  : 'Simpan Transaksi (${_transactionItems.where((item) => item.toMap() != null).length})'),
              onPressed: (_transactionItems.isNotEmpty &&
                      _transactionItems.any((item) =>
                          item.jumlahController.text.isNotEmpty &&
                          item.rateController.text.isNotEmpty))
                  ? _handleSave
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            if (widget.isEditMode)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  child: const Text('Batal Edit'),
                  onPressed: () {
                    if (widget.onClearAllRequest != null) {
                      widget.onClearAllRequest!();
                    }
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
