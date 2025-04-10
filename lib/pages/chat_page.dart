import 'package:flutter/material.dart';
import '../widgets/chat_widget.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Bagian kiri: Daftar chat
          Expanded(
            flex: 2,
            child: Container(
              color: Color.fromARGB(255, 245, 244, 255),
              child: ListView.builder(
                itemCount: 10, // Jumlah chat dalam daftar
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text('User $index'),
                    subtitle: Text('Pesan terakhir dari User $index'),
                    onTap: () {
                      // Logika untuk memilih chat
                      print('Chat dengan User $index dipilih');
                    },
                  );
                },
              ),
            ),
          ),

          // Bagian kanan: Isi chat yang sedang berlangsung
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.all(16.0),
              color: Color.fromARGB(255, 245, 244, 255),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat yang sedang berlangsung:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ChatWidget(
                      username:
                          'User yang Dipilih', // Ganti dengan data dinamis
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
