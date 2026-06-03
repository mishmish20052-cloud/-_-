
import 'package:flutter/material.dart';
import 'package:daftar_alhesabat/services/http_server.dart';

class HttpServerScreen extends StatefulWidget {
  const HttpServerScreen({super.key});

  @override
  State<HttpServerScreen> createState() => _HttpServerScreenState();
}

class _HttpServerScreenState extends State<HttpServerScreen> {
  final HttpServerService _httpServerService = HttpServerService();
  String? _serverUrl;
  bool _isServerRunning = false;

  Future<void> _startServer() async {
    final url = await _httpServerService.startServer();
    if (url != null) {
      setState(() {
        _serverUrl = url;
        _isServerRunning = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم بدء الخادم على: $_serverUrl')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل بدء الخادم. تأكد من اتصالك بالشبكة.')),
      );
    }
  }

  Future<void> _stopServer() async {
    await _httpServerService.stopServer();
    setState(() {
      _serverUrl = null;
      _isServerRunning = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إيقاف الخادم.')),
    );
  }

  @override
  void dispose() {
    _httpServerService.stopServer(); // Ensure server is stopped when screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استعراض البيانات من الكمبيوتر'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isServerRunning ? null : _startServer,
              icon: const Icon(Icons.play_arrow),
              label: const Text('بدء الخادم'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: _isServerRunning ? Colors.grey : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isServerRunning ? _stopServer : null,
              icon: const Icon(Icons.stop),
              label: const Text('إيقاف الخادم'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: _isServerRunning ? Colors.red : Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            if (_isServerRunning && _serverUrl != null) ...[
              const Text(
                'الخادم يعمل على العنوان التالي:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              SelectableText(
                _serverUrl!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              const Text(
                'افتح هذا الرابط في متصفح الويب على جهاز الكمبيوتر الخاص بك لعرض البيانات.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ] else ...[
              const Text(
                'الخادم غير قيد التشغيل حالياً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
            const Spacer(),
            const Text(
              'ملاحظة: الواجهة مضمنة في كود Dart كـ String، وترسل عبر الخادم.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
