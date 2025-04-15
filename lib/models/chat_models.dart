class ChatPublic {
  String id;
  String nama;
  List<MessagePublic> daftarPesan;

  ChatPublic({
    required this.id,
    required this.nama,
    required this.daftarPesan
  });
}

class MessagePublic {
  String id;
  String pesan;
  bool isPelanggan;

  MessagePublic({
    required this.id,
    required this.pesan,
    required this.isPelanggan
  });
}