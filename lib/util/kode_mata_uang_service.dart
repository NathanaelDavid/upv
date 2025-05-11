import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upv/models/kode_mata_uang_models.dart';

class KodeMataUangService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'kode_mata_uang';

  Future<List<KodeMataUangPublic>> getAllKodeMataUangs() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final kodeMataUangs =
        snapshot.docs.map((doc) => KodeMataUangPublic.fromFirestore(doc)).toList();
    return kodeMataUangs;
  }
}
