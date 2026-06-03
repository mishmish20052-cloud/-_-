import 'package:hive/hive.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/models/transaction.dart';

class HiveService {
  late Box<Account> _accountsBox;
  late Box<Transaction> _transactionsBox;

  // Getters للوصول إلى الصناديق من خارج الكلاس
  Box<Account> get accountsBox => _accountsBox;
  Box<Transaction> get transactionsBox => _transactionsBox;

  Future<void> init() async {
    // تأكد من تسجيل المحولات (adapters) إذا لزم الأمر
    // Hive.registerAdapter(AccountAdapter());
    // Hive.registerAdapter(TransactionAdapter());
    
    _accountsBox = await Hive.openBox<Account>('accounts');
    _transactionsBox = await Hive.openBox<Transaction>('transactions');
  }

  // باقي دوال HiveService (مثل getAccounts, getTransactionsForAccount, etc.)
  List<Account> getAccounts() {
    return _accountsBox.values.toList();
  }

  List<Transaction> getTransactionsForAccount(String accountId) {
    return _transactionsBox.values
        .where((t) => t.accountId == accountId)
        .toList();
  }
  
  // أضف أي دوال أخرى تستخدمها في مشروعك
}
