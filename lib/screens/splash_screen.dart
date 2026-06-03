
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:daftar_alhesabat/screens/login_screen.dart';
import 'package:daftar_alhesabat/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    bool canCheckBiometrics = await auth.canCheckBiometrics;
    bool hasPassword = await storage.read(key: 'app_password') != null;

    if (canCheckBiometrics) {
      _authenticateWithBiometrics();
    } else if (hasPassword) {
      // Navigate to password login if biometrics not available but password exists
      _navigateToLoginScreen();
    } else {
      // No biometrics, no password set yet, navigate to home directly or setup password
      _navigateToHomeScreen();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'يرجى المصادقة للوصول إلى التطبيق',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        _navigateToHomeScreen();
      } else {
        // Fallback to password if biometrics fail
        _navigateToLoginScreen();
      }
    } catch (e) {
      print('Error during biometric authentication: $e');
      _navigateToLoginScreen(); // Fallback to password on error
    }
  }

  void _navigateToLoginScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToHomeScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جاري التحقق من الأمان...', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
