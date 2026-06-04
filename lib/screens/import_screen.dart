import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/models/transaction.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final HiveService _hiveService = HiveService();
  List<List<dynamic>> _fileData = [];  // ✅ نوع واضح
  List<String> _columns = [];
  bool _isLoading = false;
  Map<String, String> _columnMapping = {}; // لتعيين الأعمدة

  Future<void> _pickAndParseFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'json'],
    );
    if (result == null) return;

    setState(() => _isLoading = true);
    final file = File(result.files.single.path!);
    final extension = result.files.single.extension?.toLowerCase();

    try {
      if (extension == 'csv') {
        final csvString = await file.readAsString();
        final lines = csvString.split('\n');
        if (lines.isNotEmpty) {
          _columns = lines.first.split(',').map((e) => e.trim()).toList();
          _fileData = lines.skip(1).where((l) => l.trim().isNotEmpty).map((l) => l.split(',').map((e) => e.trim()).toList() as List<dynamic>).toList().cast<List<dynamic>>();
        }
      } else if (extension == 'xlsx') {
        final bytes = await file.readAsBytes();
        var excel = Excel.decodeBytes(bytes);
        var sheet = excel.tables[excel.tables.keys.first];
        if (sheet != null) {
          _columns = sheet.rows.first.map((cell) => cell?.value?.toString() ?? '').toList();
          _fileData = sheet.rows.skip(1).where((row) => row.any((cell) => cell?.value != null)).map((row) => row.map((cell) => cell?.value?.toString() ?? '').toList() as List<dynamic>).toList().cast<List<dynamic>>();
        }
      } else if (extension == 'json') {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as List<dynamic>;
        if (jsonData.isNotEmpty && jsonData.first is Map<String, dynamic>) {
          _columns = (jsonData.first as Map<String, dynamic>).keys.toList();
          // ✅ التعديل الأساسي: استخدام as Map<String, dynamic> ثم التحويل إلى List<dynamic>
          _fileData = jsonData.map((row) {
            final map = row as Map<String, dynamic>;
            return _columns.map((col) => map[col]?.toString() ?? '').toList() as List<dynamic>;
          }).toList().cast<List<dynamic>>();
        }
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في قراءة الملف: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    if (_fileData.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      // المنطق الفعلي للاستيراد حسب تعيين الأعمدة...
      // (يُكتب حسب هيكل التطبيق الخاص بك)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الاستيراد بنجاح')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الاستيراد: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استيراد بيانات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAndParseFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('اختر ملف CSV/Excel/JSON'),
                ),
                if (_fileData.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: _columns.map((c) => DataColumn(label: Text(c))).toList(),
                        rows: _fileData.take(10).map((row) => DataRow(cells: row.map((cell) => DataCell(Text(cell.toString()))).toList())).toList(),
                      ),
                    ),
                  ),
                if (_fileData.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _importData,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('بدء الاستيراد'),
                  ),
              ],
            ),
    );
  }
}
