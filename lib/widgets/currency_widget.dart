import 'package:flutter/material.dart';

class CurrencyWidget extends StatelessWidget {
  final List<Map<String, dynamic>> currencies = [
    {'currency': 'USD', 'buy': 15900, 'sell': 15950},
    {'currency': 'EUR', 'buy': 16500, 'sell': 16550},
    {'currency': 'JPY', 'buy': 100, 'sell': 105},
    {'currency': 'MYR', 'buy': 3500, 'sell': 3500},
  ];

  CurrencyWidget({super.key}); // Data ini bisa berasal dari database

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kurs Mata Uang',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.0), // Spasi antara judul dan tabel
        DataTable(
          columns: [
            DataColumn(
              label: Text(
                'Currency',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Beli',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Jual',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: currencies.map((currency) {
            return DataRow(
              cells: [
                DataCell(Text(currency['currency'])),
                DataCell(Text('${currency['buy']}')),
                DataCell(Text('${currency['sell']}')),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
