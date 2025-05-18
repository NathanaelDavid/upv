import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upv/models/currency_models.dart';

class CurrencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'currencies';

  Future<List<CurrencyPublic>> getAllCurrencies() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final currencies =
        snapshot.docs.map((doc) => CurrencyPublic.fromFirestore(doc)).toList();
    return currencies;
  }
}