import 'package:flutter/material.dart';

class NavigationButtons extends StatelessWidget {
  final Function(int) onItemTapped;
  final int selectedIndex;
  final List<String> menus;
  final double buttonFontSize; // Tambahkan parameter untuk ukuran font
  final EdgeInsets buttonPadding; // Tambahkan parameter untuk padding tombol

  const NavigationButtons({
    super.key,
    required this.onItemTapped,
    required this.selectedIndex,
    required this.menus,
    this.buttonFontSize = 15.0, // Nilai default jika tidak disediakan
    this.buttonPadding = const EdgeInsets.symmetric(
        horizontal: 12.0, vertical: 8.0), // Nilai default
  });

  @override
  Widget build(BuildContext context) {
    const Color appPrimaryColor = Color.fromARGB(255, 48, 37, 201);
    const Color unselectedButtonBgColor = Color.fromARGB(255, 245, 244, 255);
    const Color unselectedButtonTextColor = appPrimaryColor;
    const Color selectedButtonTextColor = Colors.white;

    if (menus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center, // Mengubah alignment ke center
      children: List.generate(
        menus.length,
        (index) {
          final bool isSelected = selectedIndex == index;
          return ElevatedButton(
            onPressed: () {
              onItemTapped(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isSelected ? appPrimaryColor : unselectedButtonBgColor,
              foregroundColor: isSelected
                  ? selectedButtonTextColor
                  : unselectedButtonTextColor,
              padding: buttonPadding, // Menggunakan parameter buttonPadding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: isSelected ? 4.0 : 2.0,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ).copyWith(
              overlayColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.pressed)) {
                    return isSelected
                        ? Colors.white.withOpacity(0.12)
                        : appPrimaryColor.withOpacity(0.12);
                  }
                  return null;
                },
              ),
            ),
            child: Text(
              menus[index],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize:
                    buttonFontSize, // Menggunakan parameter buttonFontSize
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }
}
