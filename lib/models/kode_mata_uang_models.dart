import 'package:cloud_firestore/cloud_firestore.dart';

class KodeMataUangPublic {
  String id;
  String kode;

  KodeMataUangPublic({required this.id, required this.kode});

  factory KodeMataUangPublic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KodeMataUangPublic(
      id: doc.id,
      kode: data['kode'],
    );
  }
}
