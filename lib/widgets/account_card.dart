
import 'package:flutter/material.dart';
import 'package:daftar_alhesabat/models/account.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final bool isMultiSelectMode;
  final bool isSelected;
  final ValueChanged<String> onSelect;
  final VoidCallback onTap;

  const AccountCard({
    super.key,
    required this.account,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (isMultiSelectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelect(account.id),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (account.assistantName != null && account.assistantName!.isNotEmpty)
                      Text(
                        account.assistantName!,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'عليه:',
                              style: TextStyle(fontSize: 14, color: Colors.redAccent),
                            ),
                            Text(
                              '${account.balanceDue.toStringAsFixed(2)} ${account.currency}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'له:',
                              style: TextStyle(fontSize: 14, color: Colors.green),
                            ),
                            Text(
                              '${account.balanceFor.toStringAsFixed(2)} ${account.currency}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // TODO: Add number of unpaid transactions
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
