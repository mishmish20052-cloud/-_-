
import 'package:hive_flutter/hive_flutter.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/models/transaction.dart';
import 'package:daftar_alhesabat/models/settings.dart';

class HiveService {
  static late Box<Account> accountsBox;
  static late Box<Transaction> transactionsBox;
  static late Box<AppSettings> settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(TransactionAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    accountsBox = await Hive.openBox<Account>('accounts');
    transactionsBox = await Hive.openBox<Transaction>('transactions');
    settingsBox = await Hive.openBox<AppSettings>('settings');

    // Initialize default settings if not present
    if (settingsBox.isEmpty) {
      await settingsBox.add(AppSettings());
    }
  }

  // Account operations
  List<Account> getAccounts() => accountsBox.values.toList();
  Account? getAccount(String id) => accountsBox.values.firstWhere((account) => account.id == id);
  Future<void> addAccount(Account account) => accountsBox.put(account.id, account);
  Future<void> updateAccount(Account account) => accountsBox.put(account.id, account);
  Future<void> deleteAccount(String id) => accountsBox.delete(id);

  // Transaction operations
  List<Transaction> getTransactionsForAccount(String accountId) =>
      transactionsBox.values.where((transaction) => transaction.accountId == accountId).toList();
  Future<void> addTransaction(Transaction transaction) => transactionsBox.add(transaction);
  Future<void> updateTransaction(Transaction transaction) => transactionsBox.put(transaction.key, transaction);
  Future<void> deleteTransaction(int key) => transactionsBox.delete(key);

  // Settings operations
  AppSettings getSettings() => settingsBox.getAt(0)!; // Assuming only one settings object
  Future<void> updateSettings(AppSettings settings) => settingsBox.putAt(0, settings);
}
