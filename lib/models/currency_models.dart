import 'package:cloud_firestore/cloud_firestore.dart';

class CurrencyPublic {
  String id;
  String kode;

  CurrencyPublic({required this.id, required this.kode});

  factory CurrencyPublic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CurrencyPublic(
      id: doc.id,
      kode: data['kode'],
    );
  }
}