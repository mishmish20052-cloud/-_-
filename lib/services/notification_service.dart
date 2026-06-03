
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/transaction.dart';
import 'package:intl/intl.dart';

const String dailyReminderTask = "dailyReminderTask";

class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(
      int id, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminders',
      'تذكيرات يومية',
      channelDescription: 'تذكيرات بالأقساط المتكررة المستحقة',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: 'item x');
  }

  static void registerDailyReminderTask(String time) {
    Workmanager().registerPeriodicTask(
      dailyReminderTask,
      dailyReminderTask,
      frequency: const Duration(days: 1),
      initialDelay: _calculateInitialDelay(time),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
      ),
    );
  }

  static void cancelDailyReminderTask() {
    Workmanager().cancelByUniqueName(dailyReminderTask);
  }

  static Duration _calculateInitialDelay(String time) {
    final now = DateTime.now();
    final format = DateFormat("HH:mm");
    final scheduledTime = format.parse(time);

    var scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    return scheduledDateTime.difference(now);
  }

  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      if (task == dailyReminderTask) {
        await HiveService.init(); // Ensure Hive is initialized in background
        final hiveService = HiveService();
        final settings = hiveService.getSettings();

        if (settings.disableReminderNotifications) {
          return Future.value(true);
        }

        final today = DateTime.now();
        final recurringTransactions = hiveService.transactionsBox.values
            .where((t) => t.isRecurring && t.date.day == today.day && t.date.month == today.month && t.date.year == today.year)
            .toList();

        if (recurringTransactions.isNotEmpty) {
          String body = 'لديك أقساط مستحقة اليوم:\n';
          for (var transaction in recurringTransactions) {
            final account = hiveService.getAccount(transaction.accountId);
            if (account != null) {
              body += '- ${account.name}: ${transaction.amount} ${account.currency} (${transaction.type == "due" ? "عليك" : "لك"})\n';
            }
          }
          await NotificationService.showNotification(
              0, 'تذكير بالأقساط اليومية', body);
        }
      }
      return Future.value(true);
    });
  }
}
