import 'package:flutter/material.dart';
import '../widgets/kurs_stok_widget.dart';
import '../widgets/input_stok_widget.dart';

class GrafikStokPage extends StatefulWidget {
  const GrafikStokPage({super.key});

  @override
  State<GrafikStokPage> createState() => _GrafikStokPageState();
}

class _GrafikStokPageState extends State<GrafikStokPage> {
  Key _kursWidgetKey = UniqueKey();

  void _refreshKursWidget() {
    setState(() {
      _kursWidgetKey = UniqueKey(); // Ganti key → rebuild KursStockWidget
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kurs Mata Uang'),
        centerTitle: true,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.blue[50],
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: InputStokWidget(
                    onStokChanged: _refreshKursWidget, // ⬅️ Callback
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: KursStockWidget(
                key: _kursWidgetKey, // ⬅️ Force rebuild on key change
              ),
            ),
          ),
        ],
      ),
    );
  }
}
