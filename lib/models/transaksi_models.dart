import 'package:cloud_firestore/cloud_firestore.dart';

class TransaksiPublic {
  String id;
  Timestamp timestamp;
  String kodeMataUang;
  String kodeTransaksi; // "Jual" atau "Beli"
  double jumlahBarang;
  double harga;
  double totalNominal;

  TransaksiPublic({
    required this.id,
    required this.timestamp,
    required this.kodeMataUang,
    required this.kodeTransaksi,
    required this.jumlahBarang,
    required this.harga,
    required this.totalNominal,
  });

  /// Getter alias agar bisa dipakai di widget
  String get jenis => kodeTransaksi.toLowerCase(); // hasil: "jual" / "beli"
  double get jumlah => jumlahBarang;

  /// Factory method untuk mengonversi dari Firestore document snapshot
  factory TransaksiPublic.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransaksiPublic(
      id: doc.id,
      timestamp:
          data['timestamp'] ?? Timestamp.now(), // Default ke now jika null
      kodeMataUang: data['kode_mata_uang'] ?? '',
      kodeTransaksi: data['kode_transaksi'] ?? 'Beli', // Default jika null
      jumlahBarang: (data['jumlah_barang'] ?? 0.0).toDouble(),
      harga: (data['harga'] ?? 0.0).toDouble(),
      totalNominal: (data['total_nominal'] ?? 0.0).toDouble(),
    );
  }

  /// Convert ke format Firestore (Tidak secara eksplisit digunakan jika service menerima Map)
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'kode_mata_uang': kodeMataUang,
      'kode_transaksi': kodeTransaksi,
      'jumlah_barang': jumlahBarang,
      'harga': harga,
      'total_nominal': totalNominal,
    };
  }
}
