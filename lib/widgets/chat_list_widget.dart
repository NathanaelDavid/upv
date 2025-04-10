import 'package:flutter/material.dart';

import 'chat_widget.dart';

class ChatListWidget extends StatelessWidget {
  const ChatListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Chat'),
        backgroundColor: const Color.fromARGB(255, 48, 37, 201),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text('Nama $index'),
            subtitle: Text('Pesan terakhir dari pengguna...'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatWidget(username: 'Nama $index'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
