
import 'package:flutter/material.dart';
import 'package:daftar_alhesabat/screens/home_screen.dart';
import 'package:daftar_alhesabat/screens/reports_screen.dart';
import 'package:daftar_alhesabat/screens/settings_screen.dart';
import 'package:daftar_alhesabat/screens/backup_screen.dart';
import 'package:daftar_alhesabat/screens/import_screen.dart';
import 'package:daftar_alhesabat/screens/http_server_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final HiveService hiveService = HiveService();
    final settings = hiveService.getSettings();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // if (settings.companyLogoPath != null && settings.companyLogoPath!.isNotEmpty)
                //   Image.file(File(settings.companyLogoPath!), height: 60),
                // else
                  const Icon(Icons.account_balance_wallet, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  settings.companyName,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('الرئيسية'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('التقارير'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('النسخ الاحتياطي والاستعادة'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('استيراد البيانات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ImportScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.computer),
            title: const Text('استعراض من الكمبيوتر'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HttpServerScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('مشاركة التطبيق'),
            onTap: () {
              Share.share('تطبيق دفتر الحسابات - لإدارة حساباتك بسهولة! حمل التطبيق الآن: [رابط التطبيق هنا]');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('تواصل ودعم'),
            onTap: () async {
              Navigator.pop(context);
              final whatsappNumber = settings.supportWhatsappNumber ?? '+1234567890'; // Default or from settings
              final url = 'whatsapp://send?phone=${whatsappNumber.replaceAll('+', '')}';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              } else {
                final webUrl = 'https://wa.me/${whatsappNumber.replaceAll('+', '')}';
                if (await canLaunchUrl(Uri.parse(webUrl))) {
                  await launchUrl(Uri.parse(webUrl));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا يمكن فتح واتساب. تأكد من تثبيته.')),
                  );
                }
              }
            },
          ),
          // TODO: Add update check button
        ],
      ),
    );
  }
}
