import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final Function(int) onItemTapped;
  final int selectedIndex;

  const NavigationButtons({
    super.key,
    required this.onItemTapped,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: () {
                onItemTapped(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedIndex == 0
                    ? const Color.fromARGB(255, 245, 244, 255)
                    : null,
              ),
              child: const Text('Home'),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: () {
                onItemTapped(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedIndex == 1
                    ? const Color.fromARGB(255, 245, 244, 255)
                    : null,
              ),
              child: const Text('Chat'),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: () {
                onItemTapped(2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedIndex == 2
                    ? const Color.fromARGB(255, 245, 244, 255)
                    : null,
              ),
              child: const Text('Grafik'),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: () {
                onItemTapped(3);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedIndex == 3
                    ? const Color.fromARGB(255, 245, 244, 255)
                    : null,
              ),
              child: const Text('Transaksi'),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: () {
                onItemTapped(4);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedIndex == 4
                    ? const Color.fromARGB(255, 245, 244, 255)
                    : null,
              ),
              child: const Text('dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}
