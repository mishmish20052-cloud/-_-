import 'package:flutter/material.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/models/transaction.dart';
import 'package:intl/intl.dart';

class AccountScreen extends StatefulWidget {
  final String accountId;
  const AccountScreen({super.key, required this.accountId});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final HiveService _hiveService = HiveService();
  late Account _account;
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final account = _hiveService.getAccountById(widget.accountId);
    if (account != null) {
      setState(() {
        _account = account;
        _transactions = _hiveService.getTransactionsForAccount(widget.accountId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_account == null) {
      return const Scaffold(
        appBar: AppBar(title: Text('الحساب')),
        body: Center(child: Text('الحساب غير موجود')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_account.name)),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('العميل: ${_account.name}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('عليه: ${_account.balanceDue.toStringAsFixed(2)} ${_account.currency}'),
                  Text('له: ${_account.balanceFor.toStringAsFixed(2)} ${_account.currency}'),
                  const SizedBox(height: 8),
                  Text('التصنيف: ${_account.category}'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _transactions.isEmpty
                ? const Center(child: Text('لا توجد معاملات'))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      return ListTile(
                        title: Text('${t.type == 'due' ? 'عليه' : 'له'} ${t.amount.toStringAsFixed(2)}'),
                        subtitle: Text(DateFormat('yyyy-MM-dd').format(t.date)),
                        trailing: Text(t.note ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(accountId: widget.accountId),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }
}
