import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaksi_models.dart';

class TransaksiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = "transaksi";

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
      throw Exception("Error fetching transaksi: $e");
    }
  }

  /// Tambah transaksi baru ke Firestore
  Future<void> createTransaksi(Map<String, dynamic> transaksi) async {
    try {
      transaksi['timestamp'] = FieldValue.serverTimestamp();
      await _firestore.collection(collectionName).add(transaksi);
    } catch (e) {
      throw Exception("Error creating transaksi: $e");
    }
  }

  /// Update transaksi yang ada
  Future<void> updateTransaksi(
      String id, Map<String, dynamic> transaksi) async {
    try {
      transaksi['timestamp'] = FieldValue.serverTimestamp();
      await _firestore.collection(collectionName).doc(id).update(transaksi);
    } catch (e) {
      throw Exception("Error updating transaksi: $e");
    }
  }

  /// Hapus transaksi dari Firestore
  Future<void> deleteTransaksi(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      throw Exception("Error deleting transaksi: $e");
    }
  }
}
