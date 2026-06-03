
import 'package:flutter/material.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/models/transaction.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/services/whatsapp_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddMoneyScreen extends StatefulWidget {
  final Account account;
  final VoidCallback onTransactionAdded;

  const AddMoneyScreen({super.key, required this.account, required this.onTransactionAdded});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final HiveService _hiveService = HiveService();
  final WhatsappService _whatsappService = WhatsappService();
  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'due'; // 'due' or 'for'
  String? _imagePath;
  bool _isRecurring = false;
  String? _recurringInterval; // 'daily', 'weekly', 'monthly'

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final String targetPath = '${(await getTemporaryDirectory()).path}/${Uuid().v4()}.jpg';
      final XFile? compressedImage = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 88,
        minWidth: 1000,
        minHeight: 1000,
      );
      setState(() {
        _imagePath = compressedImage?.path;
      });
    }
  }

  Future<void> _saveTransaction({bool sendWhatsapp = false}) async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);

      final newTransaction = Transaction(
        id: const Uuid().v4(),
        accountId: widget.account.id,
        amount: amount,
        type: _transactionType,
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        imagePath: _imagePath,
        isRecurring: _isRecurring,
        recurringInterval: _isRecurring ? _recurringInterval : null,
      );

      await _hiveService.addTransaction(newTransaction);

      // Update account balance
      if (_transactionType == 'due') {
        widget.account.balanceDue += amount;
      } else {
        widget.account.balanceFor += amount;
      }
      await _hiveService.updateAccount(widget.account);

      widget.onTransactionAdded();

      if (sendWhatsapp && _hiveService.getSettings().sendWhatsappOnAddAmount) {
        await _whatsappService.sendTransactionMessage(
          account: widget.account,
          transaction: newTransaction,
        );
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة المبلغ بنجاح')),);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _hiveService.getSettings();
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة مبلغ لـ ${widget.account.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ (${widget.account.currency})',
                  suffixIcon: settings.showAmountAsTextOnAdd ? IconButton(icon: const Icon(Icons.abc), onPressed: () { /* TODO: Show amount as text */ },) : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال المبلغ';
                  }
                  if (double.tryParse(value) == null) {
                    return 'الرجاء إدخال رقم صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('عليه'),
                      value: 'due',
                      groupValue: _transactionType,
                      onChanged: (value) {
                        setState(() {
                          _transactionType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('له'),
                      value: 'for',
                      groupValue: _transactionType,
                      onChanged: (value) {
                        setState(() {
                          _transactionType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(_imagePath == null ? 'إرفاق صورة (اختياري)' : 'تم إرفاق صورة'),
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: 8),
                Image.file(File(_imagePath!), height: 100),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value!;
                        if (!value) _recurringInterval = null;
                      });
                    },
                  ),
                  const Text('تفعيل التكرار التلقائي'),
                ],
              ),
              if (_isRecurring) ...[
                DropdownButtonFormField<String>(
                  value: _recurringInterval,
                  decoration: const InputDecoration(labelText: 'الفاصل الزمني للتكرار'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('يومي')),
                    DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                    DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _recurringInterval = value;
                    });
                  },
                  validator: (value) {
                    if (_isRecurring && (value == null || value.isEmpty)) {
                      return 'الرجاء اختيار فاصل زمني';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // TODO: Add optional end date for recurring transactions
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _saveTransaction(sendWhatsapp: true),
                    icon: const Icon(Icons.whatsapp),
                    label: const Text('حفظ وإرسال واتساب'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveTransaction(sendWhatsapp: false),
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ فقط'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
