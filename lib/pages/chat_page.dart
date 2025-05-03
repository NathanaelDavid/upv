import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/chat_widget.dart';
import '../util/chat_service.dart';
import '../models/chat_models.dart';

class ChatPage extends StatefulWidget {
  final String? userRole;

  const ChatPage({super.key, required this.userRole});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatService _chatService;
  List<ChatPublic> _chats = [];
  ChatPublic? _selectedChat;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();

    _chatService = ChatService(widget.userRole);

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

  Future<void> _sendMessage(String message) async {
    if (_selectedChat != null) {
      await _chatService.sendMessage(_selectedChat!.id, message);
      await _loadChats();
    }
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
                  final lastMessage =
                      chat.messages.isNotEmpty ? chat.messages.last : null;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.blue.withOpacity(0.2),
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(chat.name),
                    subtitle: Text(
                      lastMessage?.text ?? 'Belum ada pesan',
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
                          'Chat dengan ${_selectedChat!.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ChatWidget(
                            chat: _selectedChat!,
                            username: _selectedChat!.name,
                            onSendMessage: (message) async {
                              await _sendMessage(message);
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
