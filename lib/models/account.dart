
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

part 'account.g.dart';

@HiveType(typeId: 0)
class Account extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? assistantName;

  @HiveField(3)
  late String currency;

  @HiveField(4)
  late String category;

  @HiveField(5)
  late double balanceDue; // المبلغ المستحق على العميل

  @HiveField(6)
  late double balanceFor; // المبلغ المستحق للعميل

  Account({
    required this.id,
    required this.name,
    this.assistantName,
    required this.currency,
    required this.category,
    this.balanceDue = 0.0,
    this.balanceFor = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'assistantName': assistantName,
        'currency': currency,
        'category': category,
        'balanceDue': balanceDue,
        'balanceFor': balanceFor,
      };

  static Account fromJson(Map<String, dynamic> json) => Account(
        id: json['id'],
        name: json['name'],
        assistantName: json['assistantName'],
        currency: json['currency'],
        category: json['category'],
        balanceDue: json['balanceDue'],
        balanceFor: json['balanceFor'],
      );
}
