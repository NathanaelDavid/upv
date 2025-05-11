import 'package:cloud_firestore/cloud_firestore.dart';

class ReportPublic {
  String id;
  String date;
  int totalJumlahBarang;
  int totalNominal;
  int transaksiCount;

  ReportPublic(
      {required this.id,
      required this.date,
      required this.totalJumlahBarang,
      required this.totalNominal,
      required this.transaksiCount});

  factory ReportPublic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportPublic(
      id: doc.id,
      date: data['date'] ?? '',
      totalJumlahBarang: data['total_jumlah_barang'] ?? 0,
      totalNominal: data['total_nominal'] ?? 0,
      transaksiCount: data['transaksi_count'] ?? 0,
    );
  }
}
