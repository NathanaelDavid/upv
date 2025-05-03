import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPublic {
  String id;
  String name;
  List<MessagePublic> messages;

  ChatPublic({required this.id, required this.name, required this.messages});
}

class MessagePublic {
  String id;
  String text;
  bool isUser;

  MessagePublic({required this.id, required this.text, required this.isUser});

  factory MessagePublic.fromFirestore(DocumentSnapshot doc, bool isAdmin) {
    final data = doc.data() as Map<String, dynamic>;
    return MessagePublic(
      id: doc.id,
      text: data['text'],
      isUser: (isAdmin && data['adminId'] != '') ||
          (!isAdmin && data['adminId'] == ''),
    );
  }
}
