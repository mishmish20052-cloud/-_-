
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/widgets/account_card.dart';
import 'package:daftar_alhesabat/widgets/filter_row.dart';
import 'package:daftar_alhesabat/widgets/custom_drawer.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveService _hiveService = HiveService();
  List<Account> _accounts = [];
  List<Account> _filteredAccounts = [];
  String _searchQuery = '';
  String? _selectedCurrencyFilter;
  String? _selectedCategoryFilter;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedAccountIds = {};

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    setState(() {
      _accounts = _hiveService.getAccounts();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredAccounts = _accounts.where((account) {
      final matchesSearch = _searchQuery.isEmpty ||
          account.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (account.assistantName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesCurrency = _selectedCurrencyFilter == null ||
          _selectedCurrencyFilter == 'all' ||
          account.currency == _selectedCurrencyFilter;
      final matchesCategory = _selectedCategoryFilter == null ||
          _selectedCategoryFilter == 'all' ||
          account.category == _selectedCategoryFilter;
      return matchesSearch && matchesCurrency && matchesCategory;
    }).toList();

    // Sort alphabetically if enabled
    final settings = _hiveService.getSettings();
    if (settings.sortNamesAlphabetically) {
      _filteredAccounts.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onCurrencyFilterChanged(String? currency) {
    setState(() {
      _selectedCurrencyFilter = currency;
      _applyFilters();
    });
  }

  void _onCategoryFilterChanged(String? category) {
    setState(() {
      _selectedCategoryFilter = category;
      _applyFilters();
    });
  }

  void _addAccount() {
    showDialog(
      context: context,
      builder: (context) => AddAccountDialog(onAccountAdded: _loadAccounts),
    );
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedAccountIds.clear();
      }
    });
  }

  void _toggleAccountSelection(String accountId) {
    setState(() {
      if (_selectedAccountIds.contains(accountId)) {
        _selectedAccountIds.remove(accountId);
      } else {
        _selectedAccountIds.add(accountId);
      }
    });
  }

  void _deleteSelectedAccounts() async {
    // Implement deletion logic
    for (var id in _selectedAccountIds) {
      await _hiveService.deleteAccount(id);
    }
    _selectedAccountIds.clear();
    _isMultiSelectMode = false;
    _loadAccounts();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف العملاء المحددين بنجاح')),
    );
  }

  void _changeCategoryForSelectedAccounts() {
    // Implement change category logic
    // This would typically involve another dialog to select a new category
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تغيير تصنيف العملاء المحددين (غير مطبق بعد)')),
    );
  }

  void _sendWhatsappToSelectedAccounts() {
    // Implement send WhatsApp logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('إرسال رسالة واتساب للعملاء المحددين (غير مطبق بعد)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals for displayed accounts
    double totalDue = _filteredAccounts.fold(0.0, (sum, account) => sum + account.balanceDue);
    double totalFor = _filteredAccounts.fold(0.0, (sum, account) => sum + account.balanceFor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر الحسابات'),
        actions: [
          if (_isMultiSelectMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedAccounts,
              tooltip: 'حذف العملاء المحددين',
            ),
          if (_isMultiSelectMode)
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: _changeCategoryForSelectedAccounts,
              tooltip: 'تغيير تصنيف العملاء المحددين',
            ),
          if (_isMultiSelectMode)
            IconButton(
              icon: const Icon(Icons.whatsapp),
              onPressed: _sendWhatsappToSelectedAccounts,
              tooltip: 'إرسال واتساب للعملاء المحددين',
            ),
          IconButton(
            icon: Icon(_isMultiSelectMode ? Icons.cancel : Icons.select_all),
            onPressed: _toggleMultiSelectMode,
            tooltip: _isMultiSelectMode ? 'إلغاء التحديد' : 'تحديد متعدد',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilterRow(
              onSearchChanged: _onSearchChanged,
              onCurrencyFilterChanged: _onCurrencyFilterChanged,
              onCategoryFilterChanged: _onCategoryFilterChanged,
              availableCurrencies: _hiveService.getSettings().currencies.map((e) => e['name'] as String).toList(),
              availableCategories: _hiveService.getSettings().categories,
            ),
          ),
          Expanded(
            child: _filteredAccounts.isEmpty
                ? const Center(child: Text('لا يوجد عملاء لعرضهم.'))
                : ListView.builder(
                    itemCount: _filteredAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _filteredAccounts[index];
                      return AccountCard(
                        account: account,
                        isMultiSelectMode: _isMultiSelectMode,
                        isSelected: _selectedAccountIds.contains(account.id),
                        onSelect: _toggleAccountSelection,
                        onTap: () {
                          if (_isMultiSelectMode) {
                            _toggleAccountSelection(account.id);
                          } else {
                            // Navigate to account details screen
                            // Navigator.of(context).push(MaterialPageRoute(builder: (context) => AccountDetailsScreen(account: account)));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تفاصيل العميل ${account.name} (غير مطبق بعد)')),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('إجمالي عليك:', style: TextStyle(fontSize: 16)),
                    Text('${totalDue.toStringAsFixed(2)} ${_hiveService.getSettings().currencies.firstWhere((e) => e['name'] == _selectedCurrencyFilter || _selectedCurrencyFilter == 'all', orElse: () => {'symbol': ''})['symbol']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                Column(
                  children: [
                    const Text('إجمالي لك:', style: TextStyle(fontSize: 16)),
                    Text('${totalFor.toStringAsFixed(2)} ${_hiveService.getSettings().currencies.firstWhere((e) => e['name'] == _selectedCurrencyFilter || _selectedCurrencyFilter == 'all', orElse: () => {'symbol': ''})['symbol']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Placeholder for AddAccountDialog
class AddAccountDialog extends StatefulWidget {
  final VoidCallback onAccountAdded;
  const AddAccountDialog({super.key, required this.onAccountAdded});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _assistantNameController = TextEditingController();
  String? _selectedCurrency;
  String? _selectedCategory;
  final HiveService _hiveService = HiveService();

  @override
  void initState() {
    super.initState();
    _selectedCurrency = _hiveService.getSettings().currencies.first['name'] as String?;
    _selectedCategory = _hiveService.getSettings().categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _assistantNameController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      final newAccount = Account(
        id: const Uuid().v4(),
        name: _nameController.text,
        assistantName: _assistantNameController.text.isEmpty ? null : _assistantNameController.text,
        currency: _selectedCurrency!,
        category: _selectedCategory!,
        balanceDue: 0.0,
        balanceFor: 0.0,
      );
      await _hiveService.addAccount(newAccount);
      widget.onAccountAdded();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _hiveService.getSettings();
    return AlertDialog(
      title: const Text('إضافة عميل جديد'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الاسم';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _assistantNameController,
                decoration: const InputDecoration(labelText: 'الاسم المساعد (اختياري)'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(labelText: 'العملة'),
                items: settings.currencies.map((currency) {
                  return DropdownMenuItem(value: currency['name'] as String, child: Text(currency['name'] as String));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار عملة';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                items: settings.categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء اختيار تصنيف';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _saveAccount,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
