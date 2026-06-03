
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/models/transaction.dart';
import 'package:daftar_alhesabat/models/settings.dart';

class BackupService {
  final HiveService _hiveService = HiveService();

  // Manual Backup: Save all data to a JSON file
  Future<String?> createManualBackup() async {
    try {
      final accounts = _hiveService.accountsBox.values.toList();
      final transactions = _hiveService.transactionsBox.values.toList();
      final settings = _hiveService.getSettings();

      final Map<String, dynamic> backupData = {
        'accounts': accounts.map((e) => e.toJson()).toList(), // Assuming toJson() method exists in models
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'settings': settings.toJson(),
      };

      String jsonString = jsonEncode(backupData);

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        return null; // User cancelled the picker
      }

      final file = File('$selectedDirectory/daftar_alhesabat_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json');
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      print('Error creating manual backup: $e');
      return null;
    }
  }

  // Automatic Daily Backup
  Future<void> createAutoBackup() async {
    try {
      final settings = _hiveService.getSettings();
      if (!settings.autoBackupEnabled || settings.backupFolderPath == null) {
        return;
      }

      final accounts = _hiveService.accountsBox.values.toList();
      final transactions = _hiveService.transactionsBox.values.toList();

      final Map<String, dynamic> backupData = {
        'accounts': accounts.map((e) => e.toJson()).toList(),
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'settings': settings.toJson(),
      };

      String jsonString = jsonEncode(backupData);

      final directory = Directory(settings.backupFolderPath!);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File('${settings.backupFolderPath}/daftar_alhesabat_auto_backup.json');
      await file.writeAsString(jsonString);
      print('Auto backup created at: ${file.path}');
    } catch (e) {
      print('Error creating auto backup: $e');
    }
  }

  // Restore data from a JSON file
  Future<bool> restoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return false; // User cancelled the picker
      }

      final file = File(result.files.single.path!);
      String jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // Clear current data
      await _hiveService.accountsBox.clear();
      await _hiveService.transactionsBox.clear();

      // Restore accounts
      for (var accJson in backupData['accounts']) {
        await _hiveService.addAccount(Account.fromJson(accJson)); // Assuming fromJson() method exists
      }

      // Restore transactions
      for (var transJson in backupData['transactions']) {
        await _hiveService.addTransaction(Transaction.fromJson(transJson));
      }

      // Restore settings (assuming only one settings object)
      if (backupData.containsKey('settings')) {
        await _hiveService.updateSettings(AppSettings.fromJson(backupData['settings']));
      }

      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }
}

// TODO: Add toJson and fromJson methods to Account, Transaction, and AppSettings models
// Example for Account:
// extension AccountExtension on Account {
//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'name': name,
//         'assistantName': assistantName,
//         'currency': currency,
//         'category': category,
//         'balanceDue': balanceDue,
//         'balanceFor': balanceFor,
//       };
//
//   static Account fromJson(Map<String, dynamic> json) => Account(
//         id: json['id'],
//         name: json['name'],
//         assistantName: json['assistantName'],
//         currency: json['currency'],
//         category: json['category'],
//         balanceDue: json['balanceDue'],
//         balanceFor: json['balanceFor'],
//       );
// }
