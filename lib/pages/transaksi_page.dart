import 'package:flutter/material.dart';
import '../widgets/transaction_widget.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  _TransaksiPageState createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Expanded(
            // Menggunakan Expanded agar TransactionWidget mengisi sisa ruang
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TransactionWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
