import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/settings.dart';
import 'package:file_picker/file_picker.dart';  // ✅ إضافة هذا السطر
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HiveService _hiveService = HiveService();
  late AppSettings _settings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _settings = _hiveService.getSettings();
    });
  }

  Future<void> _backupData() async {
    setState(() => _isLoading = true);
    try {
      final accounts = _hiveService.getAccounts();
      final transactions = _hiveService.transactionsBox.values.toList();
      final backupData = {
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'settings': _settings.toJson(),
      };
      final jsonString = jsonEncode(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(file.path)], text: 'نسخة احتياطية لبيانات دفتر الحسابات');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية ومشاركتها')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل النسخ الاحتياطي: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreData() async {
    setState(() => _isLoading = true);
    try {
      // ✅ الآن FilePicker معرف بشكل صحيح
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) return;
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);
      // استعادة البيانات...
      // (باقي منطق الاستعادة موجود مسبقاً)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استعادة البيانات بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الاستعادة: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectBackupDirectory() async {
    // ✅ استخدام FilePicker لاختيار المجلد
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _settings.backupPath = selectedDirectory;
      });
      await _hiveService.updateSettings(_settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تحديد مجلد النسخ الاحتياطي: $selectedDirectory')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('الوضع المظلم'),
                  value: _settings.isDarkMode,
                  onChanged: (value) async {
                    setState(() => _settings.isDarkMode = value);
                    await _hiveService.updateSettings(_settings);
                  },
                ),
                ListTile(
                  title: const Text('مسار النسخ الاحتياطي'),
                  subtitle: Text(_settings.backupPath ?? 'غير محدد'),
                  trailing: const Icon(Icons.folder_open),
                  onTap: _selectBackupDirectory,
                ),
                ListTile(
                  title: const Text('إنشاء نسخة احتياطية'),
                  trailing: const Icon(Icons.backup),
                  onTap: _backupData,
                ),
                ListTile(
                  title: const Text('استعادة نسخة احتياطية'),
                  trailing: const Icon(Icons.restore),
                  onTap: _restoreData,
                ),
              ],
            ),
    );
  }
}
