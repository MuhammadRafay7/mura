import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class MuraNotificationService {
  static final MuraNotificationService _instance =
      MuraNotificationService._internal();
  factory MuraNotificationService() => _instance;
  MuraNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> showInstantAlert(
      {required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'mura_security',
      'Security',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(
        android: androidDetails, iOS: DarwinNotificationDetails());
    await _notificationsPlugin.show(0, title, body, platformDetails);
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
}
