
import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String accountId;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late String type; // "due" or "for"

  @HiveField(4)
  late DateTime date;

  @HiveField(5)
  String? note;

  @HiveField(6)
  String? imagePath;

  @HiveField(7)
  bool isRecurring = false;

  @HiveField(8)
  String? recurringInterval; // "daily", "weekly", "monthly"

  Transaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.imagePath,
    this.isRecurring = false,
    this.recurringInterval,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'amount': amount,
        'type': type,
        'date': date.toIso8601String(),
        'note': note,
        'imagePath': imagePath,
        'isRecurring': isRecurring,
        'recurringInterval': recurringInterval,
      };

  static Transaction fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        accountId: json['accountId'],
        amount: json['amount'],
        type: json['type'],
        date: DateTime.parse(json['date']),
        note: json['note'],
        imagePath: json['imagePath'],
        isRecurring: json['isRecurring'] ?? false,
        recurringInterval: json['recurringInterval'],
      );
}
