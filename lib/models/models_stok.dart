import 'package:cloud_firestore/cloud_firestore.dart';

// Model untuk menampilkan data stok publik, termasuk jumlah stok yang sudah dikalkulasi
class StockPublic {
  final String id;
  final String kodeMataUang;
  final double hargaBeli;
  final double hargaJual;
  final Timestamp tanggal; // Tanggal kapan harga ini ditetapkan/diperbarui
  final double jumlahStok; // Jumlah stok aktual, dihitung dari transaksi

  StockPublic({
    required this.id,
    required this.kodeMataUang,
    required this.hargaBeli,
    required this.hargaJual,
    required this.tanggal,
    this.jumlahStok = 0.0, // Default jika tidak disediakan
  });

  factory StockPublic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockPublic(
      id: doc.id,
      kodeMataUang: data['kodeMataUang'] as String? ?? '',
      hargaBeli: (data['hargaBeli'] as num?)?.toDouble() ?? 0.0,
      hargaJual: (data['hargaJual'] as num?)?.toDouble() ?? 0.0,
      tanggal: data['tanggal'] as Timestamp? ?? Timestamp.now(),
      // jumlahStok tidak diambil langsung dari Firestore 'stocks' collection.
      // Ini akan diinisialisasi ke nilai default (0.0) oleh konstruktor StockPublic.
      // Nilai ini akan diperbarui kemudian oleh KursStockWidget setelah kalkulasi dari transaksi.
    );
  }

  // Method untuk membuat salinan objek dengan jumlahStok yang diperbarui
  StockPublic copyWith({
    double? jumlahStok,
  }) {
    return StockPublic(
      id: id,
      kodeMataUang: kodeMataUang,
      hargaBeli: hargaBeli,
      hargaJual: hargaJual,
      tanggal: tanggal,
      jumlahStok: jumlahStok ?? this.jumlahStok,
    );
  }
}

// Wrapper class jika getAllStocks() mengembalikan struktur ini
class StocksPublic {
  final List<StockPublic> data;
  StocksPublic({required this.data});
}

// Model untuk membuat atau memperbarui entri master harga stok di Firestore
// Tidak menyertakan jumlahStok karena itu dihitung dari transaksi, bukan disimpan di master harga.
class StockCreate {
  final String kodeMataUang;
  final double hargaBeli;
  final double hargaJual;
  final Timestamp tanggal;

  StockCreate({
    required this.kodeMataUang,
    required this.hargaBeli,
    required this.hargaJual,
    required this.tanggal,
    // Tidak ada jumlahStok di sini
  });

  Map<String, dynamic> toMap() {
    return {
      'kodeMataUang': kodeMataUang,
      'hargaBeli': hargaBeli,
      'hargaJual': hargaJual,
      'tanggal': tanggal,
      // Tidak ada 'jumlahStok'
    };
  }
}
