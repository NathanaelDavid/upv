import 'package:flutter/material.dart';

class GrafikListWidget extends StatelessWidget {
  final List<String> grafikItems = [
    'USD',
    'IDR',
    'EUR',
    'SGD',
    'CNY'
  ]; // Nama grafik
  final Function(String) onItemSelected; // Callback untuk item yang dipilih

  GrafikListWidget(
      {super.key,
      required this.onItemSelected}); // Konstruktor menerima callback

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey),
        ),
      ),
      child: ListView.builder(
        itemCount: grafikItems.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading:
                  Icon(Icons.show_chart, size: 40, color: Colors.blue[300]),
              title: Text(
                grafikItems[index],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                // Memanggil callback ketika item dipilih
                onItemSelected(grafikItems[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
