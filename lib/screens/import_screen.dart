
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/models/transaction.dart';
import 'package:uuid/uuid.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final HiveService _hiveService = HiveService();
  String? _filePath;
  List<String> _fileHeaders = [];
  List<List<dynamic>> _fileData = [];
  String? _selectedNameColumn;
  String? _selectedAmountColumn;
  String? _selectedDateColumn;
  String? _selectedTypeColumn;
  String? _selectedCurrencyColumn;
  String? _selectedCategoryColumn;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path!;
        _fileHeaders = [];
        _fileData = [];
        _selectedNameColumn = null;
        _selectedAmountColumn = null;
        _selectedDateColumn = null;
        _selectedTypeColumn = null;
        _selectedCurrencyColumn = null;
        _selectedCategoryColumn = null;
      });
      await _loadFileContent(_filePath!);
    }
  }

  Future<void> _loadFileContent(String path) async {
    final file = File(path);
    final String content = await file.readAsString();

    if (path.endsWith('.csv')) {
      _fileData = const CsvToListConverter().convert(content);
      if (_fileData.isNotEmpty) {
        setState(() {
          _fileHeaders = _fileData[0].map((e) => e.toString()).toList();
          _fileData = _fileData.sublist(1); // Remove header row from data
        });
      }
    } else if (path.endsWith('.json')) {
      final List<dynamic> jsonData = jsonDecode(content);
      if (jsonData.isNotEmpty) {
        // Assuming JSON is a list of objects, each object is a row
        _fileHeaders = jsonData[0].keys.map((e) => e.toString()).toList();
        _fileData = jsonData.map((row) => row.values.toList()).toList();
      }
    }
  }

  Future<void> _importData() async {
    if (_filePath == null || _fileHeaders.isEmpty || _fileData.isEmpty) {
      _showSnackBar('الرجاء اختيار ملف وتحميل بياناته أولاً.');
      return;
    }
    if (_selectedNameColumn == null || _selectedAmountColumn == null || _selectedDateColumn == null || _selectedTypeColumn == null) {
      _showSnackBar('الرجاء مطابقة جميع الأعمدة المطلوبة (الاسم، المبلغ، التاريخ، النوع).');
      return;
    }

    int nameIndex = _fileHeaders.indexOf(_selectedNameColumn!);
    int amountIndex = _fileHeaders.indexOf(_selectedAmountColumn!);
    int dateIndex = _fileHeaders.indexOf(_selectedDateColumn!);
    int typeIndex = _fileHeaders.indexOf(_selectedTypeColumn!);
    int currencyIndex = _selectedCurrencyColumn != null ? _fileHeaders.indexOf(_selectedCurrencyColumn!) : -1;
    int categoryIndex = _selectedCategoryColumn != null ? _fileHeaders.indexOf(_selectedCategoryColumn!) : -1;

    if (nameIndex == -1 || amountIndex == -1 || dateIndex == -1 || typeIndex == -1) {
      _showSnackBar('أحد الأعمدة المختارة غير موجود في الملف.');
      return;
    }

    int importedAccounts = 0;
    int importedTransactions = 0;

    for (var row in _fileData) {
      try {
        final String name = row[nameIndex].toString();
        final double amount = double.tryParse(row[amountIndex].toString()) ?? 0.0;
        final DateTime date = DateTime.tryParse(row[dateIndex].toString()) ?? DateTime.now();
        final String type = row[typeIndex].toString().toLowerCase(); // 'due' or 'for'
        final String currency = currencyIndex != -1 ? row[currencyIndex].toString() : _hiveService.getSettings().currencies.first['name'] as String; // Default currency
        final String category = categoryIndex != -1 ? row[categoryIndex].toString() : _hiveService.getSettings().categories.first; // Default category

        // Find or create account
        Account? account = _hiveService.getAccounts().firstWhere(
          (acc) => acc.name == name && acc.currency == currency, // Avoid duplicates based on name and currency
          orElse: () => Account(
            id: const Uuid().v4(),
            name: name,
            currency: currency,
            category: category,
            balanceDue: 0.0,
            balanceFor: 0.0,
          ),
        );

        if (account.id.isEmpty) { // If it's a new account
          await _hiveService.addAccount(account);
          importedAccounts++;
        }

        // Create transaction
        final newTransaction = Transaction(
          id: const Uuid().v4(),
          accountId: account.id,
          amount: amount,
          type: type,
          date: date,
        );
        await _hiveService.addTransaction(newTransaction);
        importedTransactions++;

        // Update account balances
        if (type == 'due') {
          account.balanceDue += amount;
        } else {
          account.balanceFor += amount;
        }
        await _hiveService.updateAccount(account);

      } catch (e) {
        print('Error importing row: $row - $e');
      }
    }

    _showSnackBar('تم استيراد $importedAccounts حسابات و $importedTransactions معاملة بنجاح.');
    setState(() {
      _filePath = null;
      _fileHeaders = [];
      _fileData = [];
      _selectedNameColumn = null;
      _selectedAmountColumn = null;
      _selectedDateColumn = null;
      _selectedTypeColumn = null;
      _selectedCurrencyColumn = null;
      _selectedCategoryColumn = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استيراد البيانات'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('اختيار ملف CSV أو JSON'),
            ),
            if (_filePath != null) ...[
              const SizedBox(height: 20),
              Text('الملف المحدد: $_filePath'),
              const SizedBox(height: 20),
              const Text('مطابقة الأعمدة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildColumnDropdown('الاسم', _fileHeaders, _selectedNameColumn, (value) => setState(() => _selectedNameColumn = value)),
              _buildColumnDropdown('المبلغ', _fileHeaders, _selectedAmountColumn, (value) => setState(() => _selectedAmountColumn = value)),
              _buildColumnDropdown('التاريخ', _fileHeaders, _selectedDateColumn, (value) => setState(() => _selectedDateColumn = value)),
              _buildColumnDropdown('النوع (عليه/له)', _fileHeaders, _selectedTypeColumn, (value) => setState(() => _selectedTypeColumn = value)),
              _buildColumnDropdown('العملة (اختياري)', _fileHeaders, _selectedCurrencyColumn, (value) => setState(() => _selectedCurrencyColumn = value)),
              _buildColumnDropdown('التصنيف (اختياري)', _fileHeaders, _selectedCategoryColumn, (value) => setState(() => _selectedCategoryColumn = value)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _importData,
                icon: const Icon(Icons.download),
                label: const Text('بدء الاستيراد'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColumnDropdown(String label, List<String> headers, String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        value: selectedValue,
        items: headers.map((header) {
          return DropdownMenuItem(value: header, child: Text(header));
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (label.contains('(اختياري)')) return null;
          if (value == null || value.isEmpty) {
            return 'الرجاء اختيار عمود $label';
          }
          return null;
        },
      ),
    );
  }
}
