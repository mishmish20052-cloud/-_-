
import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  late String companyName;

  @HiveField(1)
  String? companyAddress;

  @HiveField(2)
  String? companyPhone;

  @HiveField(3)
  String? companyLogoPath;

  @HiveField(4)
  late String language; // 'ar' for Arabic

  @HiveField(5)
  late bool showDateInPrint;

  @HiveField(6)
  late bool showCompanyDetailsInPrint;

  @HiveField(7)
  late bool printAsDebitCredit;

  @HiveField(8)
  late String passwordHash; // Hashed password for backup option

  @HiveField(9)
  late bool fingerprintEnabled;

  @HiveField(10)
  late List<String> categories; // List of custom categories

  @HiveField(11)
  late List<Map<String, dynamic>> currencies; // [{name: 'دولار', symbol: '$', exchangeRate: 1.0}]

  @HiveField(12)
  String? backupFolderPath;

  @HiveField(13)
  late bool autoBackupEnabled;

  @HiveField(14)
  String? autoBackupTime; // e.g., "23:00"

  @HiveField(15)
  String? whatsappIntroMessage;

  @HiveField(16)
  String? whatsappOutroMessage;

  @HiveField(17)
  late bool sendWhatsappOnAddAmount;

  @HiveField(18)
  late bool showDateInWhatsappMessage;

  @HiveField(19)
  String? supportWhatsappNumber;

  @HiveField(20)
  late bool useBusinessWhatsapp;

  @HiveField(21)
  late bool showQuickConvertIcon;

  @HiveField(22)
  late bool enableAnnualClosingReport;

  @HiveField(23)
  late bool enableDailyTotalNotification;

  @HiveField(24)
  late bool disableReminderNotifications;

  @HiveField(25)
  late bool showTotalTransactionsInAccount;

  @HiveField(26)
  late bool showTransactionTimeInAccount;

  @HiveField(27)
  late bool showAmountAsTextOnAdd;

  @HiveField(28)
  late bool darkModeEnabled;

  @HiveField(29)
  late bool sortNamesAlphabetically;

  AppSettings({
    this.companyName = 'شركتي',
    this.companyAddress,
    this.companyPhone,
    this.companyLogoPath,
    this.language = 'ar',
    this.showDateInPrint = true,
    this.showCompanyDetailsInPrint = true,
    this.printAsDebitCredit = false,
    this.passwordHash = '',
    this.fingerprintEnabled = false,
    this.categories = const [
      'العملاء',
      'الموردين',
      'أقساط متوقفة',
      'أقساط منتهية',
      'عام',
      'جروب الإنترنت',
      'زيوت عطرية'
    ],
    this.currencies = const [
      {'name': 'محلي', 'symbol': 'ج.م', 'exchangeRate': 1.0},
      {'name': 'دولار', 'symbol': '$', 'exchangeRate': 30.0},
      {'name': 'سعودي', 'symbol': 'ر.س', 'exchangeRate': 8.0},
      {'name': 'جرام', 'symbol': 'جرام', 'exchangeRate': 1.0},
    ],
    this.backupFolderPath,
    this.autoBackupEnabled = false,
    this.autoBackupTime = '23:00',
    this.whatsappIntroMessage,
    this.whatsappOutroMessage,
    this.sendWhatsappOnAddAmount = true,
    this.showDateInWhatsappMessage = true,
    this.supportWhatsappNumber,
    this.useBusinessWhatsapp = false,
    this.showQuickConvertIcon = false,
    this.enableAnnualClosingReport = false,
    this.enableDailyTotalNotification = false,
    this.disableReminderNotifications = false,
    this.showTotalTransactionsInAccount = false,
    this.showTransactionTimeInAccount = false,
    this.showAmountAsTextOnAdd = false,
    this.darkModeEnabled = false,
    this.sortNamesAlphabetically = true,
  });

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'companyAddress': companyAddress,
        'companyPhone': companyPhone,
        'companyLogoPath': companyLogoPath,
        'language': language,
        'showDateInPrint': showDateInPrint,
        'showCompanyDetailsInPrint': showCompanyDetailsInPrint,
        'printAsDebitCredit': printAsDebitCredit,
        'passwordHash': passwordHash,
        'fingerprintEnabled': fingerprintEnabled,
        'categories': categories,
        'currencies': currencies,
        'backupFolderPath': backupFolderPath,
        'autoBackupEnabled': autoBackupEnabled,
        'autoBackupTime': autoBackupTime,
        'whatsappIntroMessage': whatsappIntroMessage,
        'whatsappOutroMessage': whatsappOutroMessage,
        'sendWhatsappOnAddAmount': sendWhatsappOnAddAmount,
        'showDateInWhatsappMessage': showDateInWhatsappMessage,
        'supportWhatsappNumber': supportWhatsappNumber,
        'useBusinessWhatsapp': useBusinessWhatsapp,
        'showQuickConvertIcon': showQuickConvertIcon,
        'enableAnnualClosingReport': enableAnnualClosingReport,
        'enableDailyTotalNotification': enableDailyTotalNotification,
        'disableReminderNotifications': disableReminderNotifications,
        'showTotalTransactionsInAccount': showTotalTransactionsInAccount,
        'showTransactionTimeInAccount': showTransactionTimeInAccount,
        'showAmountAsTextOnAdd': showAmountAsTextOnAdd,
        'darkModeEnabled': darkModeEnabled,
        'sortNamesAlphabetically': sortNamesAlphabetically,
      };

  static AppSettings fromJson(Map<String, dynamic> json) => AppSettings(
        companyName: json['companyName'] ?? 'شركتي',
        companyAddress: json['companyAddress'],
        companyPhone: json['companyPhone'],
        companyLogoPath: json['companyLogoPath'],
        language: json['language'] ?? 'ar',
        showDateInPrint: json['showDateInPrint'] ?? true,
        showCompanyDetailsInPrint: json['showCompanyDetailsInPrint'] ?? true,
        printAsDebitCredit: json['printAsDebitCredit'] ?? false,
        passwordHash: json['passwordHash'] ?? '',
        fingerprintEnabled: json['fingerprintEnabled'] ?? false,
        categories: List<String>.from(json['categories'] ?? []),
        currencies: List<Map<String, dynamic>>.from(json['currencies'] ?? []),
        backupFolderPath: json['backupFolderPath'],
        autoBackupEnabled: json['autoBackupEnabled'] ?? false,
        autoBackupTime: json['autoBackupTime'] ?? '23:00',
        whatsappIntroMessage: json['whatsappIntroMessage'],
        whatsappOutroMessage: json['whatsappOutroMessage'],
        sendWhatsappOnAddAmount: json['sendWhatsappOnAddAmount'] ?? true,
        showDateInWhatsappMessage: json['showDateInWhatsappMessage'] ?? true,
        supportWhatsappNumber: json['supportWhatsappNumber'],
        useBusinessWhatsapp: json['useBusinessWhatsapp'] ?? false,
        showQuickConvertIcon: json['showQuickConvertIcon'] ?? false,
        enableAnnualClosingReport: json['enableAnnualClosingReport'] ?? false,
        enableDailyTotalNotification: json['enableDailyTotalNotification'] ?? false,
        disableReminderNotifications: json['disableReminderNotifications'] ?? false,
        showTotalTransactionsInAccount: json['showTotalTransactionsInAccount'] ?? false,
        showTransactionTimeInAccount: json['showTransactionTimeInAccount'] ?? false,
        showAmountAsTextOnAdd: json['showAmountAsTextOnAdd'] ?? false,
        darkModeEnabled: json['darkModeEnabled'] ?? false,
        sortNamesAlphabetically: json['sortNamesAlphabetically'] ?? true,
      );
}
