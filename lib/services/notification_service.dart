import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Channel IDs
  static const _billChannel = 'barakah_bills';
  static const _budgetChannel = 'barakah_budget';
  static const _zakatChannel = 'barakah_zakat';
  static const _generalChannel = 'barakah_channel';
  static const _prayerChannel = 'barakah_prayer';
  static const _savingsChannel = 'barakah_savings';

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Request notification permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Core show/schedule methods ──

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = _generalChannel,
    String channelName = 'Barakah Notifications',
    String? channelDesc,
  }) async {
    await init();
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc ?? 'Notifications from Barakah app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channelId = _generalChannel,
    String channelName = 'Barakah Notifications',
  }) async {
    await init();
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Scheduled notifications from Barakah',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ── Bill Reminders ──

  Future<void> scheduleBillReminder({
    required int billId,
    required String billName,
    required double amount,
    required int dueDay,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) return;

    final now = DateTime.now();
    var dueDate = DateTime(now.year, now.month, dueDay.clamp(1, 28));
    if (dueDate.isBefore(now)) {
      dueDate = DateTime(now.year, now.month + 1, dueDay.clamp(1, 28));
    }

    // Remind 1 day before
    final reminderDate = dueDate.subtract(const Duration(days: 1));
    if (reminderDate.isAfter(now)) {
      await scheduleNotification(
        id: 10000 + billId,
        title: '🔔 Bill Due Tomorrow',
        body:
            '$billName (\$${amount.toStringAsFixed(2)}) is due tomorrow. Don\'t forget to pay!',
        scheduledDate: DateTime(
            reminderDate.year, reminderDate.month, reminderDate.day, 9),
        channelId: _billChannel,
        channelName: 'Bill Reminders',
      );
    }

    // Remind on due day
    await scheduleNotification(
      id: 20000 + billId,
      title: '⚠️ Bill Due Today',
      body: '$billName (\$${amount.toStringAsFixed(2)}) is due today!',
      scheduledDate:
          DateTime(dueDate.year, dueDate.month, dueDate.day, 8),
      channelId: _billChannel,
      channelName: 'Bill Reminders',
    );
  }

  Future<void> scheduleAllBillReminders(List<dynamic> bills) async {
    final enabled = await isEnabled();
    if (!enabled) return;

    for (final bill in bills) {
      final id = (bill['id'] as num?)?.toInt() ?? 0;
      final name = bill['name'] as String? ?? 'Bill';
      final amount = (bill['amount'] as num?)?.toDouble() ?? 0;
      final dueDay = (bill['dueDay'] as num?)?.toInt() ?? 1;
      final paid = bill['paidThisMonth'] as bool? ?? false;

      if (!paid) {
        await scheduleBillReminder(
          billId: id,
          billName: name,
          amount: amount,
          dueDay: dueDay,
        );
      }
    }
  }

  // ── Budget Alerts ──

  Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double budgetLimit,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) return;

    final percentage = (spent / budgetLimit * 100).toStringAsFixed(0);
    if (spent >= budgetLimit) {
      await showNotification(
        id: 30000 + category.hashCode.abs() % 10000,
        title: '🚨 Budget Exceeded!',
        body:
            'You\'ve spent \$${spent.toStringAsFixed(2)} on $category, exceeding your \$${budgetLimit.toStringAsFixed(2)} budget.',
        channelId: _budgetChannel,
        channelName: 'Budget Alerts',
      );
    } else if (spent >= budgetLimit * 0.8) {
      await showNotification(
        id: 30000 + category.hashCode.abs() % 10000,
        title: '⚠️ Budget Warning',
        body:
            '$percentage% of your $category budget used (\$${spent.toStringAsFixed(2)} of \$${budgetLimit.toStringAsFixed(2)}).',
        channelId: _budgetChannel,
        channelName: 'Budget Alerts',
      );
    }
  }

  // ── Zakat & Hawl ──

  Future<void> showZakatReminder(double zakatDue) async {
    final enabled = await isZakatEnabled();
    if (!enabled) return;

    await showNotification(
      id: 999,
      title: '🕌 Zakat Reminder',
      body:
          'Your estimated zakat due is \$${zakatDue.toStringAsFixed(2)}. Purify your wealth with zakat.',
      channelId: _zakatChannel,
      channelName: 'Zakat Reminders',
    );
  }

  Future<void> showHawlReminder({
    required String assetName,
    required int daysRemaining,
  }) async {
    final enabled = await isZakatEnabled();
    if (!enabled) return;

    if (daysRemaining <= 0) {
      await showNotification(
        id: 40000 + assetName.hashCode.abs() % 10000,
        title: '🕌 Hawl Complete!',
        body:
            'The hawl period for "$assetName" is complete. Zakat may now be due.',
        channelId: _zakatChannel,
        channelName: 'Zakat Reminders',
      );
    } else if (daysRemaining <= 30) {
      await showNotification(
        id: 40000 + assetName.hashCode.abs() % 10000,
        title: '⏰ Hawl Approaching',
        body:
            '$daysRemaining days remaining for "$assetName" hawl. Prepare for zakat.',
        channelId: _zakatChannel,
        channelName: 'Zakat Reminders',
      );
    }
  }

  // ── Prayer Reminders ──

  Future<void> showPrayerReminder(String prayerName, String time) async {
    final enabled = await isPrayerEnabled();
    if (!enabled) return;

    await showNotification(
      id: prayerName.hashCode.abs() % 10000,
      title: '🕌 Prayer Time: $prayerName',
      body: '$prayerName prayer is at $time. May Allah accept your prayers.',
      channelId: _prayerChannel,
      channelName: 'Prayer Reminders',
    );
  }

  // ── Savings Goals ──

  Future<void> showSavingsGoalProgress(String goalName, double progress) async {
    final enabled = await isEnabled();
    if (!enabled) return;

    String title;
    String body;

    if (progress >= 100) {
      title = '🎉 Goal Achieved!';
      body = 'Alhamdulillah! You\'ve reached your "$goalName" savings goal!';
    } else if (progress >= 75) {
      title = '🎯 Almost There!';
      body =
          '$goalName is ${progress.toStringAsFixed(1)}% complete. You\'re so close!';
    } else if (progress >= 50) {
      title = '💪 Halfway There!';
      body =
          '$goalName is ${progress.toStringAsFixed(1)}% complete. Keep going!';
    } else {
      title = '📈 Savings Update';
      body =
          '$goalName is ${progress.toStringAsFixed(1)}% complete. Every bit counts!';
    }

    await showNotification(
      id: 50000 + goalName.hashCode.abs() % 10000,
      title: title,
      body: body,
      channelId: _savingsChannel,
      channelName: 'Savings Goals',
    );
  }

  // ── Recurring Transaction ──

  Future<void> showRecurringTransactionAlert(
      String description, double amount) async {
    final enabled = await isEnabled();
    if (!enabled) return;

    await showNotification(
      id: description.hashCode.abs() % 10000,
      title: '📝 Recurring Transaction',
      body: '$description - \$${amount.toStringAsFixed(2)} has been recorded.',
    );
  }

  // ── Notification Preferences ──

  static const _prefKey = 'notifications_enabled';
  static const _prayerPrefKey = 'prayer_notifications';
  static const _zakatPrefKey = 'zakat_notifications';
  static const _billPrefKey = 'bill_notifications';
  static const _budgetPrefKey = 'budget_notifications';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
    if (!enabled) {
      await NotificationService()._plugin.cancelAll();
    }
  }

  static Future<bool> isPrayerEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prayerPrefKey) ?? true;
  }

  static Future<void> setPrayerEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prayerPrefKey, enabled);
  }

  static Future<bool> isZakatEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_zakatPrefKey) ?? true;
  }

  static Future<void> setZakatEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_zakatPrefKey, enabled);
  }

  static Future<bool> isBillEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_billPrefKey) ?? true;
  }

  static Future<void> setBillEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_billPrefKey, enabled);
  }

  static Future<bool> isBudgetEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_budgetPrefKey) ?? true;
  }

  static Future<void> setBudgetEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_budgetPrefKey, enabled);
  }
}
