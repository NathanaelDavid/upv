import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final Function(int) onItemTapped;
  final int selectedIndex;
  final List<String> menus;

  const NavigationButtons({
    super.key,
    required this.onItemTapped,
    required this.selectedIndex,
    required this.menus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          menus.length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: () {
                onItemTapped(index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedIndex == index
                    ? const Color.fromARGB(255, 245, 244, 255)
                    : null,
              ),
              child: Text(menus[index]),
            ),
          ),
        ),
      ),
    );
  }
}
