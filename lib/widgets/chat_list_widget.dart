import 'package:flutter/material.dart';
import 'package:upv/widgets/chat_widget.dart';
import 'package:upv/util/chat_service.dart';
import 'package:upv/models/chat_models.dart';

class ChatListWidget extends StatefulWidget {
  const ChatListWidget({super.key});

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  final ChatService _chatService = ChatService();
  List<ChatPublic> _chats = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final chats = await _chatService.getChats();
    setState(() {
      _chats = chats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Chat'),
        backgroundColor: const Color.fromARGB(255, 48, 37, 201),
      ),
      body: _chats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(chat.nama),
                  subtitle: Text(chat.daftarPesan.isNotEmpty
                      ? chat.daftarPesan.last.pesan
                      : 'Belum ada pesan'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatWidget(
                          chat: chat,
                          username: chat.nama,
                          onSendMessage: (pesan) {
                            // Tambahkan logika simpan pesan baru di sini
                            print('Pesan dikirim: $pesan');
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
