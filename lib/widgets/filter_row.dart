
import 'package:flutter/material.dart';

class FilterRow extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCurrencyFilterChanged;
  final ValueChanged<String?> onCategoryFilterChanged;
  final List<String> availableCurrencies;
  final List<String> availableCategories;

  const FilterRow({
    super.key,
    required this.onSearchChanged,
    required this.onCurrencyFilterChanged,
    required this.onCategoryFilterChanged,
    required this.availableCurrencies,
    required this.availableCategories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            labelText: 'بحث بالاسم أو الاسم المساعد',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'العملة',
                  border: OutlineInputBorder(),
                ),
                value: 'all',
                items: [const DropdownMenuItem(value: 'all', child: Text('كل العملات')), ...availableCurrencies.map((currency) => DropdownMenuItem(value: currency, child: Text(currency)))].toList(),
                onChanged: onCurrencyFilterChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'التصنيف',
                  border: OutlineInputBorder(),
                ),
                value: 'all',
                items: [const DropdownMenuItem(value: 'all', child: Text('كل التصنيفات')), ...availableCategories.map((category) => DropdownMenuItem(value: category, child: Text(category)))].toList(),
                onChanged: onCategoryFilterChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
