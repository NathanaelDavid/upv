import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upv/models/chat_models.dart';
import 'package:upv/util/auth_service.dart';

class ChatService {
  final String? userRole;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatService(this.userRole);

  Future<List<ChatPublic>> getChats() async {
    bool isAdmin = userRole == 'admin' || userRole == 'owner';

    if (isAdmin) {
      return getAdminChats();
    } else {
      return getUserChats();
    }
  }

  Future<List<ChatPublic>> getAdminChats() async {
    QuerySnapshot chatsSnapshot = await _firestore
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .get();

    List<ChatPublic> chats = await Future.wait(
      chatsSnapshot.docs.map((doc) async {
        QuerySnapshot messagesSnapshot = await _firestore
            .collection('chats')
            .doc(doc.id)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .get();

        List<MessagePublic> messages = messagesSnapshot.docs
            .map((doc) => MessagePublic.fromFirestore(doc, true))
            .toList();

        return ChatPublic(
          id: doc.id,
          name: doc['name'],
          messages: messages,
        );
      }),
    );

    return chats;
  }

  Future<List<ChatPublic>> getUserChats() async {
    String? uid = _authService.getCurrentUser()?.uid;
    List<MessagePublic> messages = [];

    DocumentSnapshot chatDoc =
        await _firestore.collection('chats').doc(uid).get();

    if (chatDoc.exists) {
      QuerySnapshot messagesSnapshot = await _firestore
          .collection('chats')
          .doc(uid)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      messages = messagesSnapshot.docs
          .map((doc) => MessagePublic.fromFirestore(doc, false))
          .toList();
    } else {
      String name = await _getUserName(uid!);

      await _firestore.collection('chats').doc(uid).set({
        'name': name,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    return [ChatPublic(id: uid!, name: 'Admin', messages: messages)];
  }

  Future sendMessage(String chatId, String message) async {
    String? uid = _authService.getCurrentUser()?.uid;
    String adminId = '';
    FieldValue timestamp = FieldValue.serverTimestamp();

    if (userRole == 'admin' || userRole == 'owner') {
      adminId = uid!;
    }

    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({'timestamp': timestamp});

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': message,
      'adminId': adminId,
      'timestamp': timestamp,
    });
  }

  Future<String> _getUserName(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot userDoc =
        await firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      var data = userDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('email')) {
        return data['email'];
      }
    }

    return '';
  }
}
