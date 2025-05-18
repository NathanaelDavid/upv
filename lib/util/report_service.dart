import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upv/models/report_models.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'reports';

  Future<List<ReportPublic>> getReports(
      String code, String type, String startDate, String endDate) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .doc(code)
        .collection(type)
        .where("date", isGreaterThanOrEqualTo: startDate)
        .where("date", isLessThan: endDate)
        .orderBy("date", descending: false)
        .get();

    final reports =
        snapshot.docs.map((doc) => ReportPublic.fromFirestore(doc)).toList();
    return reports;
  }
}