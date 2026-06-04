import 'package:hive/hive.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/models/transaction.dart';
import 'package:daftar_alhesabat/models/settings.dart';

class HiveService {
  late Box<Account> _accountsBox;
  late Box<Transaction> _transactionsBox;
  late Box<AppSettings> _settingsBox;

  // Getters للوصول إلى الصناديق من خارج الكلاس
  Box<Account> get accountsBox => _accountsBox;
  Box<Transaction> get transactionsBox => _transactionsBox;
  Box<AppSettings> get settingsBox => _settingsBox;

  Future<void> init() async {
    _accountsBox = await Hive.openBox<Account>('accounts');
    _transactionsBox = await Hive.openBox<Transaction>('transactions');
    _settingsBox = await Hive.openBox<AppSettings>('settings');
  }

  // إغلاق جميع الصناديق عند إنهاء التطبيق
  Future<void> close() async {
    await _accountsBox.close();
    await _transactionsBox.close();
    await _settingsBox.close();
  }

  // ─────────────────────────────────────────
  // ACCOUNTS
  // ─────────────────────────────────────────

  List<Account> getAccounts() {
    final list = _accountsBox.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> addAccount(Account account) async {
    await _accountsBox.put(account.id, account);
  }

  Future<void> updateAccount(Account account) async {
    await _accountsBox.put(account.id, account);
  }

  Future<void> deleteAccount(String id) async {
    await _accountsBox.delete(id);
    // حذف جميع المعاملات المرتبطة بهذا الحساب مرة واحدة (أداء أفضل)
    final idsToDelete = _transactionsBox.values
        .where((t) => t.accountId == id)
        .map((t) => t.id)
        .toList();
    if (idsToDelete.isNotEmpty) {
      await _transactionsBox.deleteAll(idsToDelete);
    }
  }

  Account? getAccountById(String id) {
    return _accountsBox.get(id);
  }

  // ─────────────────────────────────────────
  // TRANSACTIONS
  // ─────────────────────────────────────────

  List<Transaction> getTransactions() {
    return _transactionsBox.values.toList();
  }

  List<Transaction> getTransactionsForAccount(String accountId) {
    return _transactionsBox.values
        .where((t) => t.accountId == accountId)
        .toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    // التأكد من وجود الحساب المرتبط
    final account = _accountsBox.get(transaction.accountId);
    if (account == null) {
      throw Exception('Account with id ${transaction.accountId} not found');
    }
    await _transactionsBox.put(transaction.id, transaction);
    _applyTransactionToBalance(account, transaction, revert: false);
    await _accountsBox.put(account.id, account);
  }

  Future<void> updateTransaction(Transaction newTransaction) async {
    // جلب المعاملة القديمة
    final oldTransaction = _transactionsBox.get(newTransaction.id);
    if (oldTransaction == null) {
      throw Exception('Transaction with id ${newTransaction.id} not found');
    }

    final oldAccountId = oldTransaction.accountId;
    final newAccountId = newTransaction.accountId;

    // حالة 1: تغير الحساب
    if (oldAccountId != newAccountId) {
      // عكس التأثير من الحساب القديم
      final oldAccount = _accountsBox.get(oldAccountId);
      if (oldAccount != null) {
        _applyTransactionToBalance(oldAccount, oldTransaction, revert: true);
        await _accountsBox.put(oldAccount.id, oldAccount);
      }
      // تطبيق التأثير على الحساب الجديد
      final newAccount = _accountsBox.get(newAccountId);
      if (newAccount == null) {
        throw Exception('New account with id $newAccountId not found');
      }
      _applyTransactionToBalance(newAccount, newTransaction, revert: false);
      await _accountsBox.put(newAccount.id, newAccount);
    }
    // حالة 2: نفس الحساب
    else {
      final account = _accountsBox.get(oldAccountId);
      if (account == null) {
        throw Exception('Account with id $oldAccountId not found');
      }
      // عكس التأثير القديم ثم تطبيق الجديد
      _applyTransactionToBalance(account, oldTransaction, revert: true);
      _applyTransactionToBalance(account, newTransaction, revert: false);
      await _accountsBox.put(account.id, account);
    }

    // حفظ المعاملة الجديدة
    await _transactionsBox.put(newTransaction.id, newTransaction);
  }

  Future<void> deleteTransaction(String id) async {
    final transaction = _transactionsBox.get(id);
    if (transaction == null) return;

    final account = _accountsBox.get(transaction.accountId);
    if (account != null) {
      _applyTransactionToBalance(account, transaction, revert: true);
      await _accountsBox.put(account.id, account);
    }
    await _transactionsBox.delete(id);
  }

  // دالة مساعدة لتطبيق أو عكس تأثير معاملة على حساب
  void _applyTransactionToBalance(Account account, Transaction transaction, {required bool revert}) {
    final multiplier = revert ? -1 : 1;
    if (transaction.type == 'due') {
      account.balanceDue += transaction.amount * multiplier;
    } else {
      // type == 'for'
      account.balanceFor += transaction.amount * multiplier;
    }
  }

  // ─────────────────────────────────────────
  // SETTINGS
  // ─────────────────────────────────────────

  AppSettings getSettings() {
    return _settingsBox.get('settings') ?? AppSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _settingsBox.put('settings', settings);
  }

  // ─────────────────────────────────────────
  // BACKUP HELPERS
  // ─────────────────────────────────────────

  Future<void> clearAllData() async {
    await _accountsBox.clear();
    await _transactionsBox.clear();
    // إذا أردت مسح الإعدادات أيضاً، قم بإلغاء تعليق السطر التالي:
    // await _settingsBox.clear();
  }
}
