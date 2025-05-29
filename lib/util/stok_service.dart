import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models_stok.dart'; // Pastikan path ini benar

class StokService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName =
      'stocks'; // Nama koleksi untuk master harga stok

  /// Mengambil semua data master harga stok.
  /// StockPublic yang dikembalikan di sini akan memiliki jumlahStok default (0.0)
  /// karena jumlahStok aktual dihitung dari transaksi.
  Future<StocksPublic> getAllStocks() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('tanggal', descending: true)
          .get();
      // Asumsikan StockPublic.fromFirestore() menangani casing dengan benar
      // atau data di Firestore sudah konsisten lowercase.
      final stocks =
          snapshot.docs.map((doc) => StockPublic.fromFirestore(doc)).toList();
      return StocksPublic(data: stocks);
    } catch (e) {
      print("Error fetching all stocks: $e");
      throw Exception("Gagal mengambil data master stok: $e");
    }
  }

  /// Mengambil data master harga stok berdasarkan ID dokumen.
  Future<StockPublic?> getStockById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      // Asumsikan StockPublic.fromFirestore() menangani casing dengan benar
      return doc.exists ? StockPublic.fromFirestore(doc) : null;
    } catch (e) {
      print("Error fetching stock by ID $id: $e");
      throw Exception("Gagal mengambil stok berdasarkan ID: $e");
    }
  }

  /// Mengambil entri master harga stok terbaru berdasarkan kodeMataUang.
  /// [kodeMataUang] akan dikonversi ke lowercase sebelum query.
  Future<StockPublic?> getStockByKode(String kodeMataUang) async {
    try {
      final String kodeLower =
          kodeMataUang.toLowerCase(); // Konversi ke lowercase
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('kodeMataUang',
              isEqualTo: kodeLower) // Selalu query dengan lowercase
          .orderBy('tanggal', descending: true) // Ambil yang terbaru
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty
          ? StockPublic.fromFirestore(querySnapshot.docs.first)
          : null;
    } catch (e) {
      print("Error fetching stock by kodeMataUang $kodeMataUang: $e");
      throw Exception("Gagal mengambil stok berdasarkan kode: $e");
    }
  }

  /// Membuat entri master harga stok baru.
  /// [stock.kodeMataUang] akan dikonversi ke lowercase sebelum disimpan.
  Future<void> createStock(StockCreate stock) async {
    try {
      // Pastikan kodeMataUang disimpan sebagai lowercase untuk konsistensi query
      final dataToSave = StockCreate(
        kodeMataUang: stock.kodeMataUang.toLowerCase(), // Konversi ke lowercase
        hargaBeli: stock.hargaBeli,
        hargaJual: stock.hargaJual,
        tanggal: stock.tanggal,
      );
      await _firestore.collection(_collectionName).add(dataToSave.toMap());
    } catch (e) {
      print("Error creating stock: $e");
      throw Exception("Gagal membuat stok: $e");
    }
  }

  /// Memperbarui entri master harga stok yang ada.
  /// [stock.kodeMataUang] akan dikonversi ke lowercase sebelum disimpan.
  Future<void> updateStock(String id, StockCreate stock) async {
    try {
      // Pastikan kodeMataUang disimpan sebagai lowercase
      final dataToUpdate = StockCreate(
        kodeMataUang: stock.kodeMataUang.toLowerCase(), // Konversi ke lowercase
        hargaBeli: stock.hargaBeli,
        hargaJual: stock.hargaJual,
        tanggal: stock.tanggal,
      );
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(dataToUpdate.toMap());
    } catch (e) {
      print("Error updating stock $id: $e");
      throw Exception("Gagal memperbarui stok: $e");
    }
  }

  /// Menghapus entri master harga stok.
  Future<void> deleteStock(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      print("Error deleting stock $id: $e");
      throw Exception("Gagal menghapus stok: $e");
    }
  }

  /// Membuat atau memperbarui entri master harga stok.
  /// Jika stok dengan kodeMataUang sudah ada, akan diperbarui; jika tidak, akan dibuat baru.
  /// [newStock.kodeMataUang] akan dikonversi ke lowercase.
  Future<void> createOrUpdateStock(StockCreate newStock) async {
    try {
      // Selalu gunakan lowercase untuk konsistensi
      final String kodeMataUangLower = newStock.kodeMataUang.toLowerCase();
      final stockToSave = StockCreate(
        kodeMataUang: kodeMataUangLower, // Gunakan lowercase
        hargaBeli: newStock.hargaBeli,
        hargaJual: newStock.hargaJual,
        tanggal: newStock.tanggal,
      );

      // getStockByKode sudah menangani konversi ke lowercase
      final existingStock = await getStockByKode(kodeMataUangLower);
      if (existingStock == null) {
        // createStock juga sudah menangani konversi ke lowercase
        await createStock(stockToSave);
      } else {
        // updateStock juga sudah menangani konversi ke lowercase
        await updateStock(existingStock.id, stockToSave);
      }
    } catch (e) {
      print("Error in createOrUpdateStock for ${newStock.kodeMataUang}: $e");
      throw Exception("Gagal membuat atau memperbarui stok: $e");
    }
  }

  /// Memperbarui timestamp pada entri master harga stok setelah terjadi transaksi.
  /// Method ini TIDAK mengubah jumlah stok aktual.
  /// Tujuannya adalah untuk menandai bahwa mata uang ini baru saja terlibat dalam transaksi
  /// dengan memperbarui field 'tanggal' ke waktu saat ini.
  /// [kodeMataUang] akan dikonversi ke lowercase.
  Future<void> updateStockTimestampAfterTransaction({
    required String kodeMataUang,
  }) async {
    try {
      final String kodeLower =
          kodeMataUang.toLowerCase(); // Konversi ke lowercase
      // getStockByKode sudah menangani konversi ke lowercase
      final existingStock = await getStockByKode(kodeLower);

      if (existingStock == null) {
        print(
            "Peringatan: Mata uang $kodeLower tidak ditemukan di master stok saat mencoba update timestamp setelah transaksi.");
        return;
      }

      final stockDataToUpdate = StockCreate(
        kodeMataUang:
            existingStock.kodeMataUang, // Sudah lowercase dari getStockByKode
        hargaBeli: existingStock.hargaBeli,
        hargaJual: existingStock.hargaJual,
        tanggal:
            Timestamp.now(), // Memperbarui tanggal ke waktu transaksi saat ini
      );

      await _firestore
          .collection(_collectionName)
          .doc(existingStock.id)
          .update(stockDataToUpdate.toMap());

      print(
          "Timestamp untuk stok $kodeLower berhasil diperbarui menjadi ${stockDataToUpdate.tanggal.toDate()} setelah transaksi.");
    } catch (e) {
      print(
          "Error in updateStockTimestampAfterTransaction for $kodeMataUang: $e");
      throw Exception("Gagal memperbarui timestamp stok setelah transaksi: $e");
    }
  }
}
