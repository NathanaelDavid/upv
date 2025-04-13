import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upv/models/chat_models.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ChatPublic>> getChats() async {
    // TODO: Perbaharui koneksi dengan database
    return [
      ChatPublic(
        id: 'chat1',
        nama: 'Andi Pratama',
        daftarPesan: [
          MessagePublic(
              id: 'msg1',
              pesan: 'Halo, berapa kurs USD hari ini?',
              isPelanggan: true),
          MessagePublic(
              id: 'msg2',
              pesan: 'Halo Andi, kurs USD hari ini Rp15.500.',
              isPelanggan: false),
          MessagePublic(
              id: 'msg3', pesan: 'Kalau Euro berapa ya?', isPelanggan: true),
          MessagePublic(
              id: 'msg4',
              pesan: 'Euro Rp16.800 per hari ini.',
              isPelanggan: false),
          MessagePublic(
              id: 'msg5',
              pesan: 'Oke, saya mau tukar 100 USD.',
              isPelanggan: true),
          MessagePublic(
              id: 'msg6',
              pesan: 'Siap, silakan datang ke kantor cabang kami.',
              isPelanggan: false),
        ],
      ),
      ChatPublic(
        id: 'chat2',
        nama: 'Siti Lestari',
        daftarPesan: [
          MessagePublic(
              id: 'msg1',
              pesan: 'Selamat pagi, apakah bisa tukar Yen?',
              isPelanggan: true),
          MessagePublic(
              id: 'msg2',
              pesan: 'Pagi Siti, tentu bisa. Kurs Yen saat ini Rp120.',
              isPelanggan: false),
          MessagePublic(
              id: 'msg3',
              pesan: 'Kalau tukar 10.000 Yen jadi berapa?',
              isPelanggan: true),
          MessagePublic(
              id: 'msg4', pesan: 'Itu setara Rp1.200.000.', isPelanggan: false),
          MessagePublic(
              id: 'msg5', pesan: 'Ada biaya tambahan?', isPelanggan: true),
          MessagePublic(
              id: 'msg6',
              pesan:
                  'Tidak ada biaya tambahan untuk transaksi di atas Rp1 juta.',
              isPelanggan: false),
          MessagePublic(
              id: 'msg7',
              pesan: 'Bagus, saya akan datang sore ini.',
              isPelanggan: true),
        ],
      ),
      ChatPublic(
        id: 'chat3',
        nama: 'Budi Santoso',
        daftarPesan: [
          MessagePublic(
              id: 'msg1',
              pesan: 'Permisi, saya ingin tahu kurs Ringgit.',
              isPelanggan: true),
          MessagePublic(
              id: 'msg2',
              pesan: 'Halo Budi, kurs Ringgit sekarang Rp3.500.',
              isPelanggan: false),
          MessagePublic(
              id: 'msg3',
              pesan: 'Kalau saya tukar 500 Ringgit?',
              isPelanggan: true),
          MessagePublic(
              id: 'msg4', pesan: 'Itu jadi Rp1.750.000.', isPelanggan: false),
          MessagePublic(
              id: 'msg5',
              pesan: 'Bisa bayar pakai transfer?',
              isPelanggan: true),
          MessagePublic(
              id: 'msg6',
              pesan: 'Bisa, kami menerima transfer bank.',
              isPelanggan: false),
          MessagePublic(
              id: 'msg7', pesan: 'Terima kasih infonya!', isPelanggan: true),
        ],
      ),
      ChatPublic(
        id: 'chat4',
        nama: 'Dewi Anjani',
        daftarPesan: [
          MessagePublic(
              id: 'msg1',
              pesan: 'Halo, saya butuh tukar 200 SGD.',
              isPelanggan: true),
          MessagePublic(
              id: 'msg2',
              pesan: 'Halo Dewi, kurs SGD hari ini Rp11.400.',
              isPelanggan: false),
          MessagePublic(
              id: 'msg3', pesan: 'Jadi totalnya berapa?', isPelanggan: true),
          MessagePublic(
              id: 'msg4', pesan: 'Totalnya Rp2.280.000.', isPelanggan: false),
          MessagePublic(
              id: 'msg5',
              pesan: 'Oke, saya konfirmasi besok ya.',
              isPelanggan: true),
        ],
      ),
      ChatPublic(
        id: 'chat5',
        nama: 'Rizky Hidayat',
        daftarPesan: [
          MessagePublic(
              id: 'msg1',
              pesan: 'Saya ingin tahu kurs AUD.',
              isPelanggan: true),
          MessagePublic(
              id: 'msg2',
              pesan: 'Hai Rizky, AUD hari ini di Rp10.200.',
              isPelanggan: false),
          MessagePublic(
              id: 'msg3',
              pesan: 'Kalau saya tukar 300 AUD?',
              isPelanggan: true),
          MessagePublic(
              id: 'msg4', pesan: 'Jadi Rp3.060.000.', isPelanggan: false),
          MessagePublic(
              id: 'msg5',
              pesan: 'Bisa ambil uangnya langsung?',
              isPelanggan: true),
          MessagePublic(
              id: 'msg6',
              pesan: 'Bisa, kami siap hari ini.',
              isPelanggan: false),
          MessagePublic(
              id: 'msg7',
              pesan: 'Terima kasih. Saya akan ke sana siang.',
              isPelanggan: true),
          MessagePublic(
              id: 'msg8',
              pesan: 'Sama-sama, kami tunggu kedatangannya.',
              isPelanggan: false),
        ],
      ),
    ];
  }
}
