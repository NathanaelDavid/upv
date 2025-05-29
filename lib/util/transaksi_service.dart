import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaksi_models.dart'; // Diperlukan untuk tipe return List<TransaksiPublic>

class TransaksiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = "transaksi"; // Nama koleksi di Firestore

  /// Ambil semua transaksi dari Firestore (terurut dari terbaru)
  Future<List<TransaksiPublic>> getAllTransaksi() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TransaksiPublic.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching transaksi: $e");
      throw Exception("Gagal mengambil data transaksi: $e");
    }
  }

  /// Tambah transaksi baru ke Firestore
  /// Menerima Map yang sudah memiliki 'timestamp' sebagai objek Timestamp Firestore
  Future<void> createTransaksi(Map<String, dynamic> transaksiData) async {
    try {
      // Tidak lagi menggunakan FieldValue.serverTimestamp() di sini
      // karena timestamp dikirim dari client (TransactionWidget)
      await _firestore.collection(collectionName).add(transaksiData);
    } catch (e) {
      print("Error creating transaksi: $e");
      throw Exception("Gagal membuat transaksi: $e");
    }
  }

  /// Update transaksi yang ada
  /// Menerima Map yang sudah memiliki 'timestamp' sebagai objek Timestamp Firestore jika diubah
  Future<void> updateTransaksi(
      String id, Map<String, dynamic> transaksiData) async {
    try {
      // Tidak lagi menggunakan FieldValue.serverTimestamp() di sini
      await _firestore.collection(collectionName).doc(id).update(transaksiData);
    } catch (e) {
      print("Error updating transaksi: $e");
      throw Exception("Gagal memperbarui transaksi: $e");
    }
  }

  /// Hapus transaksi dari Firestore
  Future<void> deleteTransaksi(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      print("Error deleting transaksi: $e");
      throw Exception("Gagal menghapus transaksi: $e");
    }
  }
}
