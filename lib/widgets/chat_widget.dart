import 'package:flutter/material.dart';
import 'package:upv/models/chat_models.dart';

class ChatWidget extends StatefulWidget {
  final ChatPublic chat;
  final Function(String) onSendMessage;
  final String username;

  const ChatWidget({
    super.key,
    required this.chat,
    required this.onSendMessage,
    required this.username,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();

  void _send() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    widget.onSendMessage(text);
    setState(() {
      widget.chat.daftarPesan.add(
        MessagePublic(
            id: UniqueKey().toString(), pesan: text, isPelanggan: true),
      );
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.nama),
        backgroundColor: const Color.fromARGB(255, 48, 37, 201),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: widget.chat.daftarPesan.length,
              itemBuilder: (context, index) {
                final msg = widget.chat.daftarPesan[index];
                return Align(
                  alignment: msg.isPelanggan
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color:
                          msg.isPelanggan ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(msg.pesan),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
