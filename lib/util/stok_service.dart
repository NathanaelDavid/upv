import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models_stok.dart';

class StokService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<StocksPublic> getAllStocks() async {
    try {
      final snapshot = await _firestore.collection('stocks').get();
      final stocks = snapshot.docs.map((doc) {
        return StockPublic.fromFirestore(doc);
      }).toList();
      return StocksPublic(data: stocks);
    } catch (e) {
      throw Exception("Error fetching stocks: $e");
    }
  }

  Future<void> createStock(StockCreate stock) async {
    try {
      await _firestore.collection('stocks').add(stock.toMap());
    } catch (e) {
      throw Exception("Error creating stock: $e");
    }
  }

  Future<void> updateStock(String id, StockCreate stock) async {
    try {
      await _firestore.collection('stocks').doc(id).update(stock.toMap());
    } catch (e) {
      throw Exception("Error updating stock: $e");
    }
  }

  Future<void> deleteStock(String id) async {
    try {
      await _firestore.collection('stocks').doc(id).delete();
    } catch (e) {
      throw Exception("Error deleting stock: $e");
    }
  }
}
