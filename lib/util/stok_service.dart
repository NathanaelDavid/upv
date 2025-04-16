import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models_stok.dart';

class StokService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'stocks';

  /// Mengambil semua data stok dari Firestore
  Future<StocksPublic> getAllStocks() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final stocks = snapshot.docs.map((doc) {
        return StockPublic.fromFirestore(doc);
      }).toList();
      return StocksPublic(data: stocks);
    } catch (e) {
      throw Exception("Error fetching stocks: $e");
    }
  }

  /// Mengambil satu data stok berdasarkan ID dokumen
  Future<StockPublic?> getStockById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return StockPublic.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception("Error fetching stock by ID: $e");
    }
  }

  /// Mengambil data stok berdasarkan kode mata uang (unik)
  Future<StockPublic?> getStockByKode(String kodeMataUang) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('kodeMataUang', isEqualTo: kodeMataUang)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return StockPublic.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception("Error fetching stock by kodeMataUang: $e");
    }
  }

  /// Menambahkan data stok baru ke Firestore
  Future<void> createStock(StockCreate stock) async {
    try {
      await _firestore.collection(_collectionName).add(stock.toMap());
    } catch (e) {
      throw Exception("Error creating stock: $e");
    }
  }

  /// Memperbarui data stok berdasarkan ID dokumen
  Future<void> updateStock(String id, StockCreate stock) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(stock.toMap());
    } catch (e) {
      throw Exception("Error updating stock: $e");
    }
  }

  /// Menghapus data stok berdasarkan ID dokumen
  Future<void> deleteStock(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception("Error deleting stock: $e");
    }
  }

  /// Menambahkan atau memperbarui data stok berdasarkan kode mata uang
  Future<void> createOrUpdateStock(StockCreate newStock) async {
    try {
      final existingStock = await getStockByKode(newStock.kodeMataUang);

      if (existingStock == null) {
        // Tidak ada stok dengan kode tersebut, buat baru
        await createStock(newStock);
      } else {
        // Update stok lama
        final double totalStokBaru =
            existingStock.jumlahStok + newStock.jumlahStok;

        final double avgHargaBeli =
            ((existingStock.hargaBeli * existingStock.jumlahStok) +
                    (newStock.hargaBeli * newStock.jumlahStok)) /
                totalStokBaru;

        final double avgHargaJual =
            ((existingStock.hargaJual * existingStock.jumlahStok) +
                    (newStock.hargaJual * newStock.jumlahStok)) /
                totalStokBaru;

        final updatedStock = StockCreate(
          kodeMataUang: newStock.kodeMataUang,
          jumlahStok: totalStokBaru,
          hargaBeli: avgHargaBeli,
          hargaJual: avgHargaJual,
        );

        await updateStock(existingStock.id, updatedStock);
      }
    } catch (e) {
      throw Exception("Error creating/updating stock: $e");
    }
  }
}
