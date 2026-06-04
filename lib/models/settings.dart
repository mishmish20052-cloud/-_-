// lib/models/settings.dart

import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 2)
class AppSettings {
  @HiveField(0)
  String companyName;

  @HiveField(1)
  String companyAddress;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String email;

  @HiveField(4)
  String currency;

  @HiveField(5)
  List<String> categories;

  @HiveField(6)
  String backupPath; // المتغير الجديد

  @HiveField(7)
  bool isDarkMode; // المتغير الجديد

  @HiveField(8)
  bool enableNotifications;

  AppSettings({
    this.companyName = '',
    this.companyAddress = '',
    this.phone = '',
    this.email = '',
    this.currency = 'د.ع', // دينار عراقي كقيمة افتراضية
    this.categories = const [],
    this.backupPath = '', // قيمة افتراضية فارغة
    this.isDarkMode = false, // القيمة الافتراضية: الوضع العادي
    this.enableNotifications = true,
  });

  // دالة لتحويل البيانات من Json
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      companyName: json['companyName'] ?? '',
      companyAddress: json['companyAddress'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      currency: json['currency'] ?? 'د.ع',
      categories: List<String>.from(json['categories'] ?? []),
      backupPath: json['backupPath'] ?? '',
      isDarkMode: json['isDarkMode'] ?? false,
      enableNotifications: json['enableNotifications'] ?? true,
    );
  }

  // دالة لتحويل البيانات إلى Json
  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'companyAddress': companyAddress,
      'phone': phone,
      'email': email,
      'currency': currency,
      'categories': categories,
      'backupPath': backupPath,
      'isDarkMode': isDarkMode,
      'enableNotifications': enableNotifications,
    };
  }
}
