// lib/pages/invoice_page.dart
import 'dart:typed_data'; // Untuk Uint8List
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Jika Anda ingin download langsung di web tanpa dialog share/print dari `printing`
// import 'package:universal_html/html.dart' as html;

import '../models/transaksi_models.dart'; // Sesuaikan path
import '../util/transaksi_service.dart'; // Sesuaikan path
import '../widgets/daftar_transaksi_invoice.dart'; // Pastikan ini adalah widget yang benar

enum TipeInvoice { jual, beli }

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final TransaksiService _transaksiService = TransaksiService();
  List<TransaksiPublic> _semuaTransaksi = [];
  List<TransaksiPublic> _transaksiTampil = [];
  final Set<String> _selectedIds = {};

  TipeInvoice _tipeInvoiceTerpilih = TipeInvoice.jual;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: "id_ID", symbol: 'Rp ', decimalDigits: 0);
  final NumberFormat _numberFormatter = NumberFormat.decimalPattern('id_ID');

  // Detail Perusahaan Anda (ganti dengan data asli)
  static const String _namaPerusahaan = "PT. UNTUNG PRIMA VALASINDO";
  static const String _alamatPerusahaan =
      "Pasar Baru lantai 3 Blok C2 No. 60 Jl. Otto Iskandardinata No. 70, Bandung.";
  static const String _kontakPerusahaan =
      "Telp: (021) 555-1234 | Email: ptuntungprimavalasindo@gmail.com";
  static const String _websitePerusahaan = "www.upvalasindo.com";

  @override
  void initState() {
    super.initState();
    _loadTransaksi();
  }

  Future<void> _loadTransaksi() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _semuaTransaksi = await _transaksiService.getAllTransaksi();
      _filterTransaksiDitampilkan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal memuat transaksi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterTransaksiDitampilkan() {
    if (!mounted) return;
    setState(() {
      final String jenisFilter =
          _tipeInvoiceTerpilih == TipeInvoice.jual ? 'jual' : 'beli';
      _transaksiTampil = _semuaTransaksi
          .where((t) => t.kodeTransaksi.toLowerCase() == jenisFilter)
          .toList();
      _selectedIds.clear();
    });
  }

  void _handleSelectTransaksi(TransaksiPublic transaksi, bool isSelected) {
    if (!mounted) return;
    setState(() {
      if (isSelected) {
        _selectedIds.add(transaksi.id);
      } else {
        _selectedIds.remove(transaksi.id);
      }
    });
  }

  Future<Uint8List> _buildPdf(
    PdfPageFormat pageFormat,
    List<TransaksiPublic> items,
    TipeInvoice tipe,
  ) async {
    final pdf = pw.Document();
    // ... (Implementasi _buildPdf dari respons sebelumnya tetap sama persis) ...
    final String jenisInvoiceText =
        tipe == TipeInvoice.jual ? "PENJUALAN" : "PEMBELIAN";
    final String nomorInvoice =
        "INV/${DateFormat('yyyyMMdd').format(DateTime.now())}/${tipe == TipeInvoice.jual ? "J" : "B"}/${items.length.toString().padLeft(3, '0')}";
    final String tanggalInvoice =
        DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

    String pihakTerkaitNama = "Pelanggan Umum";
    String pihakTerkaitAlamat = "Jl. Transaksi Umum No. 1";
    if (tipe == TipeInvoice.beli) {
      pihakTerkaitNama = "Supplier Utama";
      pihakTerkaitAlamat = "Jl. Pemasok No. A1";
    }

    double totalNominalKeseluruhan =
        items.fold(0.0, (sum, item) => sum + item.totalNominal);

    pw.TextStyle regularStyle = const pw.TextStyle(fontSize: 10);
    pw.TextStyle boldStyle =
        pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    pw.TextStyle smallStyle = const pw.TextStyle(fontSize: 8);
    pw.TextStyle smallGreyStyle =
        const pw.TextStyle(fontSize: 8, color: PdfColors.grey700);

    pdf.addPage(
      pw.MultiPage(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          header: (pw.Context context) {
            return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(_namaPerusahaan,
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 20)),
                              pw.SizedBox(height: 2),
                              pw.Text(_alamatPerusahaan,
                                  style: const pw.TextStyle(fontSize: 9)),
                              pw.SizedBox(height: 1),
                              pw.Text(_kontakPerusahaan,
                                  style: const pw.TextStyle(fontSize: 9)),
                              pw.SizedBox(height: 1),
                              pw.Text(_websitePerusahaan,
                                  style: const pw.TextStyle(
                                      fontSize: 9,
                                      color: PdfColors.blueGrey700)),
                            ]),
                      ]),
                  pw.Divider(
                      thickness: 2, height: 30, color: PdfColors.blueGrey800),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("INVOICE $jenisInvoiceText",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 18,
                                color: PdfColors.blueGrey800)),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("Nomor: $nomorInvoice",
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text("Tanggal: $tanggalInvoice",
                                  style: const pw.TextStyle(fontSize: 10)),
                            ])
                      ]),
                  pw.SizedBox(height: 15),
                  pw.Text(
                      tipe == TipeInvoice.jual
                          ? "Kepada Yth:"
                          : "Tagihan Dari:",
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey700)),
                  pw.Text(pihakTerkaitNama,
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text(pihakTerkaitAlamat,
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 20),
                ]);
          },
          build: (pw.Context context) => [
                pw.TableHelper.fromTextArray(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey500, width: 0.7),
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                      color: PdfColors.white),
                  headerAlignment: pw.Alignment.center,
                  headerPadding:
                      const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey700),
                  headers: [
                    'No.',
                    'Deskripsi Transaksi',
                    'Jumlah',
                    'Rate',
                    'Total (Rp)'
                  ],
                  cellStyle: regularStyle.copyWith(fontSize: 8),
                  cellPadding:
                      const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellAlignments: {
                    0: pw.Alignment.center,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  data: List<List<String>>.generate(
                    items.length,
                    (index) {
                      final t = items[index];
                      return [
                        (index + 1).toString(),
                        '${t.kodeTransaksi.toUpperCase()} ${t.kodeMataUang.toUpperCase()}\n(Tgl: ${DateFormat('dd/MM/yy HH:mm', "id_ID").format(t.timestamp.toDate())})',
                        _numberFormatter.format(t.jumlahBarang),
                        _currencyFormatter
                            .format(t.harga)
                            .replaceAll('Rp ', ''),
                        _currencyFormatter
                            .format(t.totalNominal)
                            .replaceAll('Rp ', ''),
                      ];
                    },
                  ),
                ),
                pw.SizedBox(height: 25),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                  pw.Container(
                      width: pageFormat.availableWidth / 2.2,
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Subtotal:', style: boldStyle),
                                  pw.Text(
                                      _currencyFormatter
                                          .format(totalNominalKeseluruhan),
                                      style: regularStyle),
                                ]),
                            pw.Divider(color: PdfColors.grey500, height: 8),
                            pw.Container(
                                padding:
                                    const pw.EdgeInsets.symmetric(vertical: 4),
                                color: PdfColors.blueGrey50,
                                child: pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text('TOTAL:',
                                          style:
                                              boldStyle.copyWith(fontSize: 12)),
                                      pw.Text(
                                          _currencyFormatter
                                              .format(totalNominalKeseluruhan),
                                          style:
                                              boldStyle.copyWith(fontSize: 12)),
                                    ]))
                          ]))
                ]),
                pw.SizedBox(height: 30),
                pw.Text(
                    "Pembayaran dapat dilakukan melalui transfer ke rekening:\nBank Central Asia (BCA) - No. Rek: 123-456-7890 a/n $_namaPerusahaan\nMohon konfirmasi setelah melakukan pembayaran.",
                    style: smallStyle.copyWith(fontSize: 8.5),
                    textAlign: pw.TextAlign.left),
                pw.SizedBox(height: 40),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(children: [
                        pw.Text("Dibuat Oleh,", style: smallStyle),
                        pw.SizedBox(height: 60),
                        pw.Container(
                            width: 120,
                            child: pw.Divider(
                                thickness: 0.5, color: PdfColors.black)),
                        pw.Text("( Staff Administrasi )", style: smallStyle),
                      ]),
                      pw.Column(children: [
                        pw.Text("Mengetahui,", style: smallStyle),
                        pw.SizedBox(height: 60),
                        pw.Container(
                            width: 120,
                            child: pw.Divider(
                                thickness: 0.5, color: PdfColors.black)),
                        pw.Text("( Pelanggan )", style: smallStyle),
                      ])
                    ])
              ],
          footer: (pw.Context context) {
            return pw.Container(
                alignment: pw.Alignment.center,
                margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
                child: pw.Text(
                    'Terima kasih atas kepercayaan Anda. - $_websitePerusahaan - Halaman ${context.pageNumber} dari ${context.pagesCount}',
                    style: smallGreyStyle));
          }),
    );
    return pdf.save();
  }

  Future<void> _generateAndHandlePdf() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih minimal satu transaksi.")));
      return;
    }
    if (!mounted) return;
    setState(() => _isGeneratingPdf = true);

    final List<TransaksiPublic> transaksiUntukInvoice =
        _semuaTransaksi.where((t) => _selectedIds.contains(t.id)).toList();

    try {
      final Uint8List pdfBytes = await _buildPdf(
        PdfPageFormat.a4,
        transaksiUntukInvoice,
        _tipeInvoiceTerpilih,
      );

      final String fileName =
          "Invoice_${_tipeInvoiceTerpilih == TipeInvoice.jual ? "Jual" : "Beli"}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf";

      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      print("Error generating/handling PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal membuat PDF: $e")));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Widget _buildFilterSection() {
    // ... (fungsi ini tetap sama) ...
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: SegmentedButton<TipeInvoice>(
        style: SegmentedButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          selectedBackgroundColor:
              Theme.of(context).primaryColor.withOpacity(0.2),
          selectedForegroundColor: Theme.of(context).primaryColor,
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        segments: const <ButtonSegment<TipeInvoice>>[
          ButtonSegment<TipeInvoice>(
              value: TipeInvoice.jual,
              label: Text('Invoice Jual'),
              icon: Icon(Icons.arrow_circle_up_outlined)),
          ButtonSegment<TipeInvoice>(
              value: TipeInvoice.beli,
              label: Text('Invoice Beli'),
              icon: Icon(Icons.arrow_circle_down_outlined)),
        ],
        selected: <TipeInvoice>{_tipeInvoiceTerpilih},
        onSelectionChanged: (Set<TipeInvoice> newSelection) {
          if (newSelection.isNotEmpty && mounted) {
            setState(() {
              _tipeInvoiceTerpilih = newSelection.first;
              _filterTransaksiDitampilkan();
            });
          }
        },
      ),
    );
  }

  Widget _buildDaftarTransaksiSection() {
    // ... (fungsi ini tetap sama, memanggil DaftarTransaksiInvoice) ...
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transaksiTampil.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Tidak ada transaksi ${_tipeInvoiceTerpilih == TipeInvoice.jual ? "penjualan" : "pembelian"} untuk ditampilkan.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    return DaftarTransaksiInvoice(
      transaksiList: _transaksiTampil,
      selectedTransaksiIds: _selectedIds,
      onSelect: _handleSelectTransaksi,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tidak lagi mengambil warna dari Theme.of(context).primaryColor untuk AppBar
    // karena kita ingin default atau transparan.

    return Scaffold(
      appBar: AppBar(
        // --- PERUBAHAN AppBar ---
        title: const Text("Pembuatan Invoice"),
        centerTitle: true, // Judul di tengah

        // 1. Hapus backgroundColor untuk menggunakan warna default tema atau buat transparan
        backgroundColor:
            Colors.transparent, // Atau biarkan null untuk default tema
        elevation:
            0, // Hapus bayangan jika background transparan atau menyatu dengan body

        // 2. Atur warna teks dan ikon menjadi hitam
        titleTextStyle: const TextStyle(
          color: Colors.black, // Warna teks judul menjadi hitam
          fontSize: 20, // Sesuaikan ukuran font jika perlu
          fontWeight: FontWeight.w500, // Sesuaikan ketebalan jika perlu
        ),
        iconTheme: const IconThemeData(
          color:
              Colors.black, // Warna untuk leading icon (misal tombol kembali)
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.black, // Warna untuk ikon di actions (jika ada)
        ),
        // --- AKHIR PERUBAHAN AppBar ---
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 700;

          if (isWideScreen) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildFilterSection(),
                      Expanded(child: _buildDaftarTransaksiSection()),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: _selectedIds.isEmpty
                        ? const Text("Pilih transaksi untuk membuat invoice.")
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${_selectedIds.length} transaksi dipilih.",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              const SizedBox(height: 20),
                              Text(
                                  "Total: ${_currencyFormatter.format(_semuaTransaksi.where((t) => _selectedIds.contains(t.id)).fold(0.0, (sum, item) => sum + item.totalNominal))}",
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: _isGeneratingPdf
                                    ? null
                                    : _generateAndHandlePdf,
                                icon: _isGeneratingPdf
                                    ? Container(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary)) // Warna progress
                                    : const Icon(Icons.picture_as_pdf_outlined),
                                label: Text(_isGeneratingPdf
                                    ? "Membuat..."
                                    : "Buat & Bagikan PDF"),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .primaryColor, // Warna tombol
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 15)),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            );
          } else {
            // Layout untuk layar sempit (mobile)
            return Column(
              children: [
                _buildFilterSection(),
                Expanded(child: _buildDaftarTransaksiSection()),
              ],
            );
          }
        },
      ),
      floatingActionButton:
          (MediaQuery.of(context).size.width <= 700 && !_isLoading)
              ? FloatingActionButton.extended(
                  onPressed: (_selectedIds.isEmpty || _isGeneratingPdf)
                      ? null
                      : _generateAndHandlePdf,
                  icon: _isGeneratingPdf
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Theme.of(context).colorScheme.onPrimary),
                        )
                      : Icon(Icons.picture_as_pdf_outlined,
                          color: Theme.of(context).colorScheme.onPrimary),
                  label: Text(
                      _isGeneratingPdf ? "Membuat..." : "Buat & Bagikan PDF",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary)),
                  backgroundColor: (_selectedIds.isEmpty || _isGeneratingPdf)
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                )
              : null,
    );
  }
}
