import 'package:flutter/material.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final String accountId;
  const AddTransactionScreen({super.key, required this.accountId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final HiveService _hiveService = HiveService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'due'; // due = عليه, for = له
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        accountId: widget.accountId,
        amount: double.parse(_amountController.text),
        type: _type,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
      await _hiveService.addTransaction(transaction);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة معاملة')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'الرجاء إدخال المبلغ';
                  if (double.tryParse(value) == null) return 'أدخل رقماً صحيحاً';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'due', label: Text('عليه')),
                  ButtonSegment(value: 'for', label: Text('له')),
                ],
                selected: {_type},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('التاريخ'),
                subtitle: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
