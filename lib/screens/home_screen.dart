import 'package:flutter/material.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/screens/account_screen.dart';
import 'package:daftar_alhesabat/screens/add_transaction_screen.dart';
import 'package:daftar_alhesabat/screens/reports_screen.dart';
import 'package:daftar_alhesabat/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveService _hiveService = HiveService();
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    setState(() {
      _accounts = _hiveService.getAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الحسابات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => _loadAccounts());
            },
          ),
          IconButton(
            // ✅ التعديل هنا: Icons.whatsapp -> Icons.message
            icon: const Icon(Icons.message),
            onPressed: () {
              // يمكنك إضافة وظيفة مشاركة أو دعم واتساب هنا
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ميزة الدعم عبر واتساب قريباً')),
              );
            },
          ),
        ],
      ),
      body: _accounts.isEmpty
          ? const Center(child: Text('لا توجد حسابات. أضف حساباً جديداً'))
          : ListView.builder(
              itemCount: _accounts.length,
              itemBuilder: (context, index) {
                final account = _accounts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(account.name),
                    subtitle: Text('عليه: ${account.balanceDue.toStringAsFixed(2)}   له: ${account.balanceFor.toStringAsFixed(2)}'),
                    trailing: Text(account.currency),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AccountScreen(accountId: account.id),
                        ),
                      ).then((_) => _loadAccounts());
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          ).then((_) => _loadAccounts());
        },
      ),
    );
  }
}
