import 'package:cloud_firestore/cloud_firestore.dart';

class StockPublic {
  final String id;
  final String kodeMataUang;
  final double jumlahStok;
  final double hargaBeli;
  final double hargaJual;
  final Timestamp tanggal;

  StockPublic({
    required this.id,
    required this.kodeMataUang,
    required this.jumlahStok,
    required this.hargaBeli,
    required this.hargaJual,
    required this.tanggal,
  });

  factory StockPublic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockPublic(
      id: doc.id,
      kodeMataUang: data['kodeMataUang'] ?? '',
      jumlahStok: (data['jumlahStok'] as num?)?.toDouble() ?? 0.0,
      hargaBeli: (data['hargaBeli'] as num?)?.toDouble() ?? 0.0,
      hargaJual: (data['hargaJual'] as num?)?.toDouble() ?? 0.0,
      tanggal: data['tanggal'] ?? Timestamp.now(),
    );
  }
}

class StocksPublic {
  final List<StockPublic> data;
  StocksPublic({required this.data});
}

class StockCreate {
  final String kodeMataUang;
  final double jumlahStok;
  final double hargaBeli;
  final double hargaJual;
  final Timestamp tanggal;

  StockCreate({
    required this.kodeMataUang,
    required this.jumlahStok,
    required this.hargaBeli,
    required this.hargaJual,
    required this.tanggal,
  });

  Map<String, dynamic> toMap() {
    return {
      'kodeMataUang': kodeMataUang,
      'jumlahStok': jumlahStok,
      'hargaBeli': hargaBeli,
      'hargaJual': hargaJual,
      'tanggal': tanggal,
    };
  }
}
