
import 'package:url_launcher/url_launcher.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/models/transaction.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';

class WhatsappService {
  final HiveService _hiveService = HiveService();

  Future<void> sendTransactionMessage({
    required Account account,
    required Transaction transaction,
  }) async {
    final settings = _hiveService.getSettings();
    String message = '';

    // Add intro message if available
    if (settings.whatsappIntroMessage != null && settings.whatsappIntroMessage!.isNotEmpty) {
      message += '${settings.whatsappIntroMessage}\n\n';
    }

    // Account name and assistant name
    message += 'العميل: ${account.name}';
    if (account.assistantName != null && account.assistantName!.isNotEmpty) {
      message += ' (${account.assistantName})';
    }
    message += '\n';

    // Transaction details
    message += 'المبلغ: ${transaction.amount} ${account.currency}\n';
    message += 'النوع: ${transaction.type == "due" ? "عليه" : "له"}\n';
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      message += 'ملاحظة: ${transaction.note}\n';
    }
    if (settings.showDateInWhatsappMessage) {
      message += 'التاريخ: ${transaction.date.toLocal().toString().split(' ')[0]}\n';
    }

    // Add outro message if available
    if (settings.whatsappOutroMessage != null && settings.whatsappOutroMessage!.isNotEmpty) {
      message += '\n${settings.whatsappOutroMessage}';
    }

    // Assuming account.companyPhone or a specific contact number is stored in Account model or Settings
    // For now, we'll use a placeholder or assume the user will input the number.
    // In a real app, you'd likely have a phone number field for each account.
    String? phoneNumber = account.companyPhone; // Placeholder, needs to be added to Account model or retrieved from settings
    if (settings.supportWhatsappNumber != null && settings.supportWhatsappNumber!.isNotEmpty) {
      phoneNumber = settings.supportWhatsappNumber; // Use support number if no account specific number
    }

    if (phoneNumber == null || phoneNumber.isEmpty) {
      // Fallback or error handling if no phone number is found
      print('No phone number available to send WhatsApp message.');
      return;
    }

    final url = 'whatsapp://send?phone=${phoneNumber.replaceAll('+', '')}&text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print('Could not launch WhatsApp. Make sure it is installed.');
      // Optionally, launch web WhatsApp
      final webUrl = 'https://wa.me/${phoneNumber.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl));
      } else {
        print('Could not launch web WhatsApp.');
      }
    }
  }

  Future<void> sendAccountStatementMessage({
    required Account account,
    required List<Transaction> transactions,
  }) async {
    final settings = _hiveService.getSettings();
    String message = '';

    if (settings.whatsappIntroMessage != null && settings.whatsappIntroMessage!.isNotEmpty) {
      message += '${settings.whatsappIntroMessage}\n\n';
    }

    message += 'كشف حساب العميل: ${account.name}';
    if (account.assistantName != null && account.assistantName!.isNotEmpty) {
      message += ' (${account.assistantName})';
    }
    message += '\n\n';

    for (var transaction in transactions) {
      message += '- ${transaction.date.toLocal().toString().split(' ')[0]} | ';
      message += '${transaction.type == "due" ? "عليه" : "له"}: ';
      message += '${transaction.amount} ${account.currency}';
      if (transaction.note != null && transaction.note!.isNotEmpty) {
        message += ' (${transaction.note})';
      }
      message += '\n';
    }

    message += '\nالرصيد الحالي (عليه): ${account.balanceDue} ${account.currency}\n';
    message += 'الرصيد الحالي (له): ${account.balanceFor} ${account.currency}\n';

    if (settings.whatsappOutroMessage != null && settings.whatsappOutroMessage!.isNotEmpty) {
      message += '\n${settings.whatsappOutroMessage}';
    }

    String? phoneNumber = account.companyPhone; // Placeholder
    if (settings.supportWhatsappNumber != null && settings.supportWhatsappNumber!.isNotEmpty) {
      phoneNumber = settings.supportWhatsappNumber;
    }

    if (phoneNumber == null || phoneNumber.isEmpty) {
      print('No phone number available to send WhatsApp message.');
      return;
    }

    final url = 'whatsapp://send?phone=${phoneNumber.replaceAll('+', '')}&text=${Uri.encodeComponent(message)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      final webUrl = 'https://wa.me/${phoneNumber.replaceAll('+', '')}?text=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl));
      } else {
        print('Could not launch web WhatsApp.');
      }
    }
  }
}
