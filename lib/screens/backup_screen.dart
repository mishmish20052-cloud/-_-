
import 'package:flutter/material.dart';
import 'package:daftar_alhesabat/services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  String? _backupPath;

  Future<void> _createManualBackup() async {
    final path = await _backupService.createManualBackup();
    if (path != null) {
      setState(() {
        _backupPath = path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء نسخة احتياطية في: $_backupPath')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل إنشاء النسخة الاحتياطية أو تم الإلغاء')),
      );
    }
  }

  Future<void> _restoreBackup() async {
    final success = await _backupService.restoreBackup();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم استعادة النسخة الاحتياطية بنجاح')),
      );
      // Optionally, reload data in other screens or navigate to home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل استعادة النسخة الاحتياطية أو تم الإلغاء')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي والاستعادة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _createManualBackup,
              icon: const Icon(Icons.backup),
              label: const Text('إنشاء نسخة احتياطية يدوية'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _restoreBackup,
              icon: const Icon(Icons.restore),
              label: const Text('استعادة نسخة احتياطية'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            if (_backupPath != null)
              Text(
                'آخر نسخة احتياطية تم إنشاؤها في: $_backupPath',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const Spacer(),
            const Text(
              'ملاحظة: لا حاجة لجوجل درايف في الإصدار الأول، لكن تم ترك هيكل جاهز للإضافة مستقبلاً.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
