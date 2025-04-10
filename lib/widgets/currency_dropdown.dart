import 'package:flutter/material.dart';

class CurrencyDropdown extends StatelessWidget {
  final String? selectedCurrency;
  final Function(String?) onCurrencyChanged;

  const CurrencyDropdown({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> currencies = ['USD', 'EUR', 'SGD', 'JPY', 'GBP'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Mata Uang', style: TextStyle(fontSize: 16)),
        DropdownButton<String>(
          isExpanded: true,
          value: selectedCurrency,
          items: currencies
              .map((currency) => DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  ))
              .toList(),
          onChanged: onCurrencyChanged,
          hint: const Text('Pilih mata uang'),
        ),
      ],
    );
  }
}
