import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings: settings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  // แปลงรหัสเอกสาร Firestore ให้เป็น ID ตัวเลขที่คงที่
  int _notificationBaseId(String documentId) {
    var hash = 0;

    for (final codeUnit in documentId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x07FFFFFF;
    }

    // เว้น ID 0 และจำกัดค่าให้อยู่ในช่วงที่ใช้งานได้
    return hash == 0 ? 1 : hash;
  }

  Future<void> scheduleTravelReminders({
    required String documentId,
    required String placeName,
    required String visitDate,
  }) async {
    await initialize();

    // ยกเลิกกำหนดการเก่าก่อนตั้งใหม่
    await cancelTravelReminders(documentId);

    final parsedDate = DateTime.tryParse(visitDate);
    if (parsedDate == null) {
      throw FormatException('รูปแบบวันเดินทางไม่ถูกต้อง: $visitDate');
    }

    final tripDate = tz.TZDateTime(
      tz.local,
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      9,
    );

    final baseId = _notificationBaseId(documentId);

    for (final daysBefore in [2, 1]) {
      final reminderDate = tripDate.subtract(
        Duration(days: daysBefore),
      );

      if (!reminderDate.isAfter(tz.TZDateTime.now(tz.local))) {
        continue;
      }

      final notificationId = baseId * 10 + daysBefore;

      final message = daysBefore == 1
          ? 'พรุ่งนี้คุณจะได้เดินทางไปเที่ยวที่ $placeName แล้ว!'
          : 'อีก 2 วัน คุณจะได้เดินทางไปเที่ยวที่ $placeName แล้ว!';

      const androidDetails = AndroidNotificationDetails(
        'travel_reminders',
        'การแจ้งเตือนการเดินทาง',
        channelDescription: 'แจ้งเตือนก่อนถึงวันเดินทาง',
        importance: Importance.max,
        priority: Priority.high,
      );

      const details = NotificationDetails(
        android: androidDetails,
      );

      await _notifications.zonedSchedule(
        id: notificationId,
        title: 'ใกล้ถึงวันเดินทางแล้ว 🧳',
        body: message,
        scheduledDate: reminderDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelTravelReminders(String documentId) async {
    await initialize();

    final baseId = _notificationBaseId(documentId);

    await _notifications.cancel(id: baseId * 10 + 2);
    await _notifications.cancel(id: baseId * 10 + 1);
  }
}