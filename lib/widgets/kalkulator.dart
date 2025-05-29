import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk FilteringTextInputFormatter
import 'package:intl/intl.dart';
import '../models/models_stok.dart'; // Pastikan path ini benar
import '../util/stok_service.dart'; // Pastikan path ini benar

class CurrencyCalculator extends StatefulWidget {
  const CurrencyCalculator({super.key});

  @override
  State<CurrencyCalculator> createState() => _CurrencyCalculatorState();
}

class _CurrencyCalculatorState extends State<CurrencyCalculator> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _hargaBeliController = TextEditingController();
  final TextEditingController _hargaJualController = TextEditingController();
  final StokService _stokService = StokService();

  List<String> _availableCurrencies = [];
  String? _selectedCurrencyCode;
  bool _useSellRate = true;
  double _total = 0.0;
  bool _loading = true; // Untuk loading awal daftar mata uang
  bool _loadingRates = false; // Untuk loading saat mengambil kurs spesifik
  String? _errorMessage;

  static const double _priceFieldsBreakpoint = 450.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculateTotal);
    _hargaBeliController.addListener(_calculateTotal);
    _hargaJualController.addListener(_calculateTotal);
    _loadAvailableCurrencies();
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateTotal);
    _amountController.dispose();
    _hargaBeliController.removeListener(_calculateTotal);
    _hargaBeliController.dispose();
    _hargaJualController.removeListener(_calculateTotal);
    _hargaJualController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCurrencies() async {
    if (!mounted) return;
    setState(() {
      _loading = true; // Loading utama untuk daftar mata uang
      _errorMessage = null;
    });
    try {
      final stocksPublic = await _stokService.getAllStocks();
      if (!mounted) return;

      final codes =
          stocksPublic.data.map((e) => e.kodeMataUang).toSet().toList();
      codes.sort();

      setState(() {
        _availableCurrencies = codes;
        if (codes.isNotEmpty) {
          if (_selectedCurrencyCode == null ||
              !codes.contains(_selectedCurrencyCode)) {
            _selectedCurrencyCode = codes.first;
          }
        } else {
          _selectedCurrencyCode = null;
        }
      });

      if (_selectedCurrencyCode != null) {
        // Setelah daftar mata uang dimuat, muat kurs untuk yang terpilih
        // _loadingRates akan dihandle oleh _loadLatestRateForCurrency
        await _loadLatestRateForCurrency(_selectedCurrencyCode!,
            isInitialLoad: true);
      } else {
        setState(() =>
            _loading = false); // Selesai loading utama jika tidak ada mata uang
      }
    } catch (e) {
      print("Error loading available currencies: $e");
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = "Gagal memuat daftar mata uang.";
        });
      }
    }
  }

  Future<void> _loadLatestRateForCurrency(String code,
      {bool isInitialLoad = false}) async {
    if (!mounted) return;
    setState(() {
      _loadingRates = true; // Mulai loading untuk kurs spesifik
      if (!isInitialLoad)
        _loading =
            true; // Juga set loading utama jika bukan initial load (misal dari tombol refresh)
      _errorMessage = null;
    });

    try {
      final stocksPublic = await _stokService.getAllStocks();
      if (!mounted) return;

      final filtered =
          stocksPublic.data.where((e) => e.kodeMataUang == code).toList();
      filtered.sort((a, b) => b.tanggal.compareTo(a.tanggal));

      if (filtered.isNotEmpty) {
        final latest = filtered.first;
        // Tetap set nilai awal, pengguna bisa mengubahnya
        _hargaBeliController.text = latest.hargaBeli.toStringAsFixed(0);
        _hargaJualController.text = latest.hargaJual.toStringAsFixed(0);
      } else {
        // Jika tidak ada data, jangan hapus input pengguna jika sudah ada
        // kecuali jika ini adalah pemanggilan pertama untuk mata uang tersebut.
        // Untuk kesederhanaan, kita bisa biarkan field kosong jika data tidak ada.
        // Atau, jika ingin mempertahankan input manual, jangan clear di sini.
        // Untuk sekarang, kita clear jika tidak ada data dari service.
        _hargaBeliController.clear();
        _hargaJualController.clear();
        print("Tidak ada data stok ditemukan untuk $code dari service.");
      }
      _calculateTotal();
    } catch (e) {
      print("Error loading latest rate for $code: $e");
      if (mounted) {
        // Jangan clear input pengguna saat error, biarkan mereka tetap dengan nilai manualnya.
        // _hargaBeliController.clear();
        // _hargaJualController.clear();
        _errorMessage = "Gagal memuat kurs terbaru untuk $code.";
        _calculateTotal();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingRates = false;
          if (!isInitialLoad || _availableCurrencies.isEmpty)
            _loading = false; // Matikan loading utama setelah selesai
        });
      }
    }
  }

  void _calculateTotal() {
    if (!mounted) return;
    final double amount = double.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0.0;
    final String rateText =
        _useSellRate ? _hargaJualController.text : _hargaBeliController.text;
    final double rate =
        double.tryParse(rateText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    setState(() {
      _total = amount * rate;
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    // final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary; // Tidak terpakai di sini

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading && _availableCurrencies.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kalkulator Kurs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20.0),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10.0),
                    ],
                    _buildTextField(
                      controller: _amountController,
                      label: 'Jumlah Mata Uang Asing',
                      hint: 'Contoh: 100',
                      isAmount: true,
                      // Nonaktifkan saat loading rate agar tidak memicu kalkulasi dengan rate lama
                      enabled: !_loadingRates,
                    ),
                    const SizedBox(height: 16.0),
                    Text('Pilih Mata Uang:',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4.0),
                    if (_availableCurrencies.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedCurrencyCode,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 14.0),
                        ),
                        items: _availableCurrencies.map((code) {
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text(code),
                          );
                        }).toList(),
                        onChanged: _loadingRates
                            ? null
                            : (value) {
                                if (value != null &&
                                    value != _selectedCurrencyCode) {
                                  setState(() => _selectedCurrencyCode = value);
                                  _loadLatestRateForCurrency(value);
                                }
                              },
                        hint: const Text('Pilih Valas'),
                      )
                    else if (!_loading)
                      const Text('Tidak ada mata uang tersedia.',
                          style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16.0),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > _priceFieldsBreakpoint) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _hargaBeliController,
                                  label: 'Harga Beli (Rp)',
                                  hint: 'Masukkan harga beli',
                                  // readOnly: false, // Dihapus, defaultnya false
                                  enabled: !_loadingRates,
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: _buildTextField(
                                  controller: _hargaJualController,
                                  label: 'Harga Jual (Rp)',
                                  hint: 'Masukkan harga jual',
                                  // readOnly: false, // Dihapus
                                  enabled: !_loadingRates,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: _hargaBeliController,
                                label: 'Harga Beli (Rp)',
                                hint: 'Masukkan harga beli',
                                // readOnly: false,
                                enabled: !_loadingRates,
                              ),
                              const SizedBox(height: 16.0),
                              _buildTextField(
                                controller: _hargaJualController,
                                label: 'Harga Jual (Rp)',
                                hint: 'Masukkan harga jual',
                                // readOnly: false,
                                enabled: !_loadingRates,
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                            child: Text('Hitung berdasarkan Harga:',
                                style: Theme.of(context).textTheme.titleSmall)),
                        const SizedBox(width: 8),
                        Text(_useSellRate ? 'Jual' : 'Beli',
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold)),
                        Switch(
                          value: _useSellRate,
                          onChanged: _loadingRates
                              ? null
                              : (value) {
                                  setState(() => _useSellRate = value);
                                  _calculateTotal();
                                },
                          activeColor: primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Total Estimasi:',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (_loadingRates) // Tampilkan loader kecil di samping total saat kurs sedang dimuat
                          const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.5))
                        else
                          Text(
                            _formatCurrency(_total),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    if (_selectedCurrencyCode != null)
                      Center(
                        child: TextButton.icon(
                          icon: _loadingRates
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh, size: 18),
                          label: const Text('Perbarui Kurs dari Sistem'),
                          onPressed: _loadingRates
                              ? null
                              : () => _loadLatestRateForCurrency(
                                  _selectedCurrencyCode!),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool readOnly = false, // Default tetap false
    bool isAmount = false,
    bool enabled = true, // Tambahkan parameter enabled
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4.0),
        TextFormField(
          controller: controller,
          readOnly: readOnly, // readOnly sekarang bisa diatur dari pemanggilan
          enabled: enabled, // Gunakan parameter enabled
          keyboardType: const TextInputType.numberWithOptions(
              decimal:
                  false), // Ubah ke false untuk decimal agar bisa pakai .replaceAll
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Hanya izinkan digit
            // Anda bisa menambahkan custom formatter untuk format ribuan saat input jika diinginkan
          ],
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
            filled: readOnly ||
                !enabled, // Field di-grey jika readonly atau disabled
            fillColor: (readOnly || !enabled) ? Colors.grey.shade100 : null,
          ),
        ),
      ],
    );
  }
}
