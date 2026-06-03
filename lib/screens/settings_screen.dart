
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HiveService _hiveService = HiveService();
  late AppSettings _settings;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _currencyNameController = TextEditingController();
  final TextEditingController _currencySymbolController = TextEditingController();
  final TextEditingController _currencyExchangeRateController = TextEditingController();
  final TextEditingController _whatsappIntroController = TextEditingController();
  final TextEditingController _whatsappOutroController = TextEditingController();
  final TextEditingController _supportWhatsappNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _settings = _hiveService.getSettings();
    _companyNameController.text = _settings.companyName;
    _companyAddressController.text = _settings.companyAddress ?? '';
    _companyPhoneController.text = _settings.companyPhone ?? '';
    _whatsappIntroController.text = _settings.whatsappIntroMessage ?? '';
    _whatsappOutroController.text = _settings.whatsappOutroMessage ?? '';
    _supportWhatsappNumberController.text = _settings.supportWhatsappNumber ?? '';
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _categoryController.dispose();
    _currencyNameController.dispose();
    _currencySymbolController.dispose();
    _currencyExchangeRateController.dispose();
    _whatsappIntroController.dispose();
    _whatsappOutroController.dispose();
    _supportWhatsappNumberController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _settings.companyName = _companyNameController.text;
      _settings.companyAddress = _companyAddressController.text.isEmpty ? null : _companyAddressController.text;
      _settings.companyPhone = _companyPhoneController.text.isEmpty ? null : _companyPhoneController.text;
      _settings.whatsappIntroMessage = _whatsappIntroController.text.isEmpty ? null : _whatsappIntroController.text;
      _settings.whatsappOutroMessage = _whatsappOutroController.text.isEmpty ? null : _whatsappOutroController.text;
      _settings.supportWhatsappNumber = _supportWhatsappNumberController.text.isEmpty ? null : _supportWhatsappNumberController.text;

      await _hiveService.updateSettings(_settings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال كلمة مرور جديدة')),
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمتا المرور غير متطابقتين')),
      );
      return;
    }
    // In a real app, hash the password before storing
    await const FlutterSecureStorage().write(key: 'app_password', value: _newPasswordController.text);
    _settings.passwordHash = _newPasswordController.text; // Placeholder for hashed password
    await _hiveService.updateSettings(_settings);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
    );
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  Future<void> _pickCompanyLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final String newPath = '${appDir.path}/company_logo.png';
      await File(image.path).copy(newPath);
      setState(() {
        _settings.companyLogoPath = newPath;
      });
      _saveSettings();
    }
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تصنيف جديد'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(labelText: 'اسم التصنيف'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_categoryController.text.isNotEmpty) {
                setState(() {
                  _settings.categories.add(_categoryController.text);
                  _categoryController.clear();
                });
                _saveSettings();
                Navigator.of(context).pop();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _editCategory(int index) {
    _categoryController.text = _settings.categories[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل التصنيف'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(labelText: 'اسم التصنيف'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_categoryController.text.isNotEmpty) {
                setState(() {
                  _settings.categories[index] = _categoryController.text;
                  _categoryController.clear();
                });
                _saveSettings();
                Navigator.of(context).pop();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(int index) {
    setState(() {
      _settings.categories.removeAt(index);
    });
    _saveSettings();
  }

  void _addCurrency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عملة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currencyNameController,
              decoration: const InputDecoration(labelText: 'اسم العملة'),
            ),
            TextField(
              controller: _currencySymbolController,
              decoration: const InputDecoration(labelText: 'رمز العملة'),
            ),
            TextField(
              controller: _currencyExchangeRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر الصرف (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currencyNameController.text.isNotEmpty && _currencySymbolController.text.isNotEmpty) {
                setState(() {
                  _settings.currencies.add({
                    'name': _currencyNameController.text,
                    'symbol': _currencySymbolController.text,
                    'exchangeRate': double.tryParse(_currencyExchangeRateController.text) ?? 1.0,
                  });
                  _currencyNameController.clear();
                  _currencySymbolController.clear();
                  _currencyExchangeRateController.clear();
                });
                _saveSettings();
                Navigator.of(context).pop();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _editCurrency(int index) {
    _currencyNameController.text = _settings.currencies[index]['name'] as String;
    _currencySymbolController.text = _settings.currencies[index]['symbol'] as String;
    _currencyExchangeRateController.text = (_settings.currencies[index]['exchangeRate'] as double).toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل العملة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currencyNameController,
              decoration: const InputDecoration(labelText: 'اسم العملة'),
            ),
            TextField(
              controller: _currencySymbolController,
              decoration: const InputDecoration(labelText: 'رمز العملة'),
            ),
            TextField(
              controller: _currencyExchangeRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سعر الصرف (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currencyNameController.text.isNotEmpty && _currencySymbolController.text.isNotEmpty) {
                setState(() {
                  _settings.currencies[index] = {
                    'name': _currencyNameController.text,
                    'symbol': _currencySymbolController.text,
                    'exchangeRate': double.tryParse(_currencyExchangeRateController.text) ?? 1.0,
                  };
                  _currencyNameController.clear();
                  _currencySymbolController.clear();
                  _currencyExchangeRateController.clear();
                });
                _saveSettings();
                Navigator.of(context).pop();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteCurrency(int index) {
    setState(() {
      _settings.currencies.removeAt(index);
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('البيانات الشخصية'),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(labelText: 'اسم الشركة'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال اسم الشركة';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _companyAddressController,
              decoration: const InputDecoration(labelText: 'العنوان'),
            ),
            TextFormField(
              controller: _companyPhoneController,
              decoration: const InputDecoration(labelText: 'الهاتف'),
              keyboardType: TextInputType.phone,
            ),
            ListTile(
              title: const Text('شعار الشركة'),
              subtitle: Text(_settings.companyLogoPath ?? 'لم يتم اختيار شعار'),
              trailing: const Icon(Icons.image),
              onTap: _pickCompanyLogo,
            ),
            // Language setting (Arabic only for now)
            ListTile(
              title: const Text('اللغة'),
              subtitle: const Text('العربية (لا يمكن التغيير حالياً)'),
              trailing: const Icon(Icons.language),
            ),
            const Divider(),

            _buildSectionTitle('خيارات الطباعة'),
            SwitchListTile(
              title: const Text('إظهار التاريخ في الطباعة'),
              value: _settings.showDateInPrint,
              onChanged: (value) {
                setState(() => _settings.showDateInPrint = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('إظهار بيانات الشركة في الطباعة'),
              value: _settings.showCompanyDetailsInPrint,
              onChanged: (value) {
                setState(() => _settings.showCompanyDetailsInPrint = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('طباعة كشف الحساب بتنسيق مدين/دائن'),
              value: _settings.printAsDebitCredit,
              onChanged: (value) {
                setState(() => _settings.printAsDebitCredit = value);
                _saveSettings();
              },
            ),
            const Divider(),

            _buildSectionTitle('خيارات الأمان'),
            ListTile(
              title: const Text('تغيير كلمة المرور'),
              trailing: const Icon(Icons.lock),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تغيير كلمة المرور'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
                        ),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: _changePassword,
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                );
              },
            ),
            SwitchListTile(
              title: const Text('تمكين بصمة الأصبع/الوجه'),
              value: _settings.fingerprintEnabled,
              onChanged: (value) async {
                final LocalAuthentication auth = LocalAuthentication();
                if (value) {
                  bool canCheckBiometrics = await auth.canCheckBiometrics;
                  if (canCheckBiometrics) {
                    bool authenticated = await auth.authenticate(
                      localizedReason: 'يرجى المصادقة لتمكين بصمة الأصبع/الوجه',
                      options: const AuthenticationOptions(stickyAuth: true),
                    );
                    if (authenticated) {
                      setState(() => _settings.fingerprintEnabled = value);
                      _saveSettings();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('فشل المصادقة البيومترية')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جهازك لا يدعم المصادقة البيومترية')),
                    );
                  }
                } else {
                  setState(() => _settings.fingerprintEnabled = value);
                  _saveSettings();
                }
              },
            ),
            const Divider(),

            _buildSectionTitle('التصنيفات'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _settings.categories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_settings.categories[index]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editCategory(index)),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteCategory(index)),
                    ],
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add), label: const Text('إضافة تصنيف جديد'),
              ),
            ),
            const Divider(),

            _buildSectionTitle('العملات'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _settings.currencies.length,
              itemBuilder: (context, index) {
                final currency = _settings.currencies[index];
                return ListTile(
                  title: Text('${currency['name']} (${currency['symbol']})'),
                  subtitle: Text('سعر الصرف: ${currency['exchangeRate']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editCurrency(index)),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteCurrency(index)),
                    ],
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addCurrency,
                icon: const Icon(Icons.add), label: const Text('إضافة عملة جديدة'),
              ),
            ),
            const Divider(),

            _buildSectionTitle('خيارات حفظ البيانات'),
            ListTile(
              title: const Text('مجلد النسخ الاحتياطي'),
              subtitle: Text(_settings.backupFolderPath ?? 'لم يتم تحديد مجلد'),
              trailing: const Icon(Icons.folder),
              onTap: () async {
                String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                if (selectedDirectory != null) {
                  setState(() => _settings.backupFolderPath = selectedDirectory);
                  _saveSettings();
                }
              },
            ),
            SwitchListTile(
              title: const Text('تفعيل الحفظ التلقائي اليومي'),
              value: _settings.autoBackupEnabled,
              onChanged: (value) {
                setState(() => _settings.autoBackupEnabled = value);
                _saveSettings();
                // TODO: Register/cancel workmanager task
              },
            ),
            ListTile(
              title: const Text('وقت الحفظ اليومي التلقائي'),
              subtitle: Text(_settings.autoBackupTime ?? 'غير محدد'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(DateTime.parse('2023-01-01 ${_settings.autoBackupTime ?? '23:00'}:00')),
                );
                if (picked != null) {
                  setState(() => _settings.autoBackupTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                  _saveSettings();
                  // TODO: Re-register workmanager task with new time
                }
              },
            ),
            const Divider(),

            _buildSectionTitle('خيارات الإشعارات'),
            TextFormField(
              controller: _whatsappIntroController,
              decoration: const InputDecoration(labelText: 'نص مقدمة رسالة الواتساب (اختياري)'),
              maxLines: 2,
            ),
            TextFormField(
              controller: _whatsappOutroController,
              decoration: const InputDecoration(labelText: 'نص خاتمة رسالة الواتساب (اختياري)'),
              maxLines: 2,
            ),
            SwitchListTile(
              title: const Text('إرسال واتساب عند إضافة مبلغ'),
              value: _settings.sendWhatsappOnAddAmount,
              onChanged: (value) {
                setState(() => _settings.sendWhatsappOnAddAmount = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('إظهار التاريخ في رسالة الواتساب'),
              value: _settings.showDateInWhatsappMessage,
              onChanged: (value) {
                setState(() => _settings.showDateInWhatsappMessage = value);
                _saveSettings();
              },
            ),
            TextFormField(
              controller: _supportWhatsappNumberController,
              decoration: const InputDecoration(labelText: 'رقم واتساب الدعم الفني (اختياري)'),
              keyboardType: TextInputType.phone,
            ),
            SwitchListTile(
              title: const Text('استخدام واتساب للأعمال'),
              value: _settings.useBusinessWhatsapp,
              onChanged: (value) {
                setState(() => _settings.useBusinessWhatsapp = value);
                _saveSettings();
              },
            ),
            const Divider(),

            _buildSectionTitle('خيارات أخرى'),
            SwitchListTile(
              title: const Text('إظهار أيقونة تحويل سريع في الرئيسية'),
              value: _settings.showQuickConvertIcon,
              onChanged: (value) {
                setState(() => _settings.showQuickConvertIcon = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('تفعيل الإغلاق السنوي (تقارير فقط)'),
              value: _settings.enableAnnualClosingReport,
              onChanged: (value) {
                setState(() => _settings.enableAnnualClosingReport = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('تفعيل إشعار إجمالي المبالغ اليومي'),
              value: _settings.enableDailyTotalNotification,
              onChanged: (value) {
                setState(() => _settings.enableDailyTotalNotification = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('إيقاف التذكير بالتنبيهات'),
              value: _settings.disableReminderNotifications,
              onChanged: (value) {
                setState(() => _settings.disableReminderNotifications = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('إظهار إجمالي العمليات أسفل الحساب'),
              value: _settings.showTotalTransactionsInAccount,
              onChanged: (value) {
                setState(() => _settings.showTotalTransactionsInAccount = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('إظهار وقت العملية في شاشة الحساب'),
              value: _settings.showTransactionTimeInAccount,
              onChanged: (value) {
                setState(() => _settings.showTransactionTimeInAccount = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('إظهار المبلغ كتابة عند الإضافة'),
              value: _settings.showAmountAsTextOnAdd,
              onChanged: (value) {
                setState(() => _settings.showAmountAsTextOnAdd = value);
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('الوضع الليلي (Dark Mode)'),
              value: _settings.darkModeEnabled,
              onChanged: (value) {
                setState(() => _settings.darkModeEnabled = value);
                _saveSettings();
                // TODO: Apply theme change immediately
              },
            ),
            SwitchListTile(
              title: const Text('ترتيب الأسماء أبجدياً'),
              value: _settings.sortNamesAlphabetically,
              onChanged: (value) {
                setState(() => _settings.sortNamesAlphabetically = value);
                _saveSettings();
                // TODO: Re-sort accounts in home screen
              },
            ),
            const Divider(),

            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('حفظ جميع الإعدادات'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
