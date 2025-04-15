import 'package:flutter/material.dart';
import '../models/chat_models.dart';

class ChatWidget extends StatefulWidget {
  final ChatPublic chat;
  final Function(String) onSendMessage;

  const ChatWidget({
    super.key, 
    required this.chat,
    required this.onSendMessage,
  });

  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String message) {
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.chat.daftarPesan.length,
            itemBuilder: (context, index) {
              final message = widget.chat.daftarPesan[index];
              final isAdmin = !message.isPelanggan;

              return Align(
                alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color.fromARGB(100, 48, 37, 201)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    message.pesan,
                    style: TextStyle(
                      color: isAdmin ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _sendMessage(_messageController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 227, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
