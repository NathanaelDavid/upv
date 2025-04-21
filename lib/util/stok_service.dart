import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models_stok.dart';

class StokService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'stocks';

  Future<StocksPublic> getAllStocks() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final stocks =
        snapshot.docs.map((doc) => StockPublic.fromFirestore(doc)).toList();
    return StocksPublic(data: stocks);
  }

  Future<StockPublic?> getStockById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    return doc.exists ? StockPublic.fromFirestore(doc) : null;
  }

  Future<StockPublic?> getStockByKode(String kodeMataUang) async {
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where('kodeMataUang', isEqualTo: kodeMataUang)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty
        ? StockPublic.fromFirestore(querySnapshot.docs.first)
        : null;
  }

  Future<void> createStock(StockCreate stock) async {
    await _firestore.collection(_collectionName).add(stock.toMap());
  }

  Future<void> updateStock(String id, StockCreate stock) async {
    await _firestore.collection(_collectionName).doc(id).update(stock.toMap());
  }

  Future<void> deleteStock(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  Future<void> createOrUpdateStock(StockCreate newStock) async {
    final existingStock = await getStockByKode(newStock.kodeMataUang);
    if (existingStock == null) {
      await createStock(newStock);
    } else {
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

      final updated = StockCreate(
        kodeMataUang: newStock.kodeMataUang,
        jumlahStok: totalStokBaru,
        hargaBeli: avgHargaBeli,
        hargaJual: avgHargaJual,
        tanggal: newStock.tanggal,
      );
      await updateStock(existingStock.id, updated);
    }
  }

  Future<void> updateStockAfterTransaction({
    required String kodeMataUang,
    required String tipeTransaksi,
    required double jumlah,
  }) async {
    final existingStock = await getStockByKode(kodeMataUang);
    if (existingStock == null) {
      throw Exception("Mata uang tidak ditemukan saat update stok transaksi");
    }

    double updatedJumlah = existingStock.jumlahStok;
    if (tipeTransaksi == 'Beli') {
      updatedJumlah += jumlah;
    } else if (tipeTransaksi == 'Jual') {
      if (jumlah > updatedJumlah) {
        throw Exception("Stok tidak mencukupi untuk transaksi jual");
      }
      updatedJumlah -= jumlah;
    }

    final updated = StockCreate(
      kodeMataUang: existingStock.kodeMataUang,
      jumlahStok: updatedJumlah,
      hargaBeli: existingStock.hargaBeli,
      hargaJual: existingStock.hargaJual,
      tanggal: existingStock.tanggal,
    );

    await updateStock(existingStock.id, updated);
  }
}
