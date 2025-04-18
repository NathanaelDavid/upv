import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/chat_widget.dart';
import '../util/chat_service.dart';
import '../models/chat_models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  List<ChatPublic> _chats = [];
  ChatPublic? _selectedChat;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadChats();

    // Start polling every 10 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadChats();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChats() async {
    final chats = await _chatService.getChats();
    setState(() {
      _chats = chats;
      if (_selectedChat != null) {
        _selectedChat = chats.firstWhere(
          (chat) => chat.id == _selectedChat!.id,
          orElse: () => _selectedChat!,
        );
      }
    });
  }

  void _handleChatTap(ChatPublic chat) {
    setState(() {
      _selectedChat = chat;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Chat list
          Expanded(
            flex: 2,
            child: Container(
              color: const Color.fromARGB(255, 245, 244, 255),
              child: ListView.builder(
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  final isSelected = _selectedChat?.id == chat.id;
                  final lastMessage = chat.daftarPesan.isNotEmpty
                      ? chat.daftarPesan.last
                      : null;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.blue.withOpacity(0.2),
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(chat.nama),
                    subtitle: Text(
                      lastMessage?.pesan ?? 'Belum ada pesan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _handleChatTap(chat),
                  );
                },
              ),
            ),
          ),

          // Chat detail
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color.fromARGB(255, 245, 244, 255),
              child: _selectedChat == null
                  ? const Center(
                      child: Text(
                        'Pilih chat untuk memulai',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat dengan ${_selectedChat!.nama}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ChatWidget(
                            chat: _selectedChat!,
                            username: _selectedChat!.nama,
                            onSendMessage: (message) async {
                              // TODO: Tambahkan logika simpan ke backend di sini
                              print('Pesan baru: $message');

                              // Refresh ulang
                              await _loadChats();
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
