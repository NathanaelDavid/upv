import 'package:cloud_firestore/cloud_firestore.dart';

class StockPublic {
  final String id;
  final String kodeMataUang;
  final double jumlahStok;
  final double hargaBeli;
  final double hargaJual;

  StockPublic({
    required this.id,
    required this.kodeMataUang,
    required this.jumlahStok,
    required this.hargaBeli,
    required this.hargaJual,
  });

  factory StockPublic.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockPublic(
      id: doc.id,
      kodeMataUang: data['kodeMataUang'] ?? '',
      jumlahStok: (data['jumlahStok'] as num).toDouble(),
      hargaBeli: (data['hargaBeli'] as num).toDouble(),
      hargaJual: (data['hargaJual'] as num).toDouble(),
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

  StockCreate({
    required this.kodeMataUang,
    required this.jumlahStok,
    required this.hargaBeli,
    required this.hargaJual,
  });

  Map<String, dynamic> toMap() {
    return {
      'kodeMataUang': kodeMataUang,
      'jumlahStok': jumlahStok,
      'hargaBeli': hargaBeli,
      'hargaJual': hargaJual,
    };
  }
}
