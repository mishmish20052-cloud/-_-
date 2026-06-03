
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:daftar_alhesabat/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isFirstTimeSetup = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPasswordStatus();
  }

  Future<void> _checkPasswordStatus() async {
    String? storedPassword = await _storage.read(key: 'app_password');
    if (storedPassword == null) {
      setState(() {
        _isFirstTimeSetup = true;
      });
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _errorMessage = null;
    });

    if (_isFirstTimeSetup) {
      if (_passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'الرجاء إدخال كلمة مرور لتعيينها.';
        });
        return;
      }
      await _storage.write(key: 'app_password', value: _passwordController.text); // In a real app, hash this password
      _navigateToHomeScreen();
    } else {
      String? storedPassword = await _storage.read(key: 'app_password');
      if (storedPassword == _passwordController.text) {
        _navigateToHomeScreen();
      } else {
        setState(() {
          _errorMessage = 'كلمة المرور غير صحيحة.';
        });
      }
    }
  }

  void _navigateToHomeScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isFirstTimeSetup ? 'تعيين كلمة مرور' : 'تسجيل الدخول'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _isFirstTimeSetup
                    ? 'الرجاء تعيين كلمة مرور جديدة لتأمين التطبيق.'
                    : 'الرجاء إدخال كلمة المرور للمتابعة.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(_isFirstTimeSetup ? 'تعيين وحفظ' : 'تسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
