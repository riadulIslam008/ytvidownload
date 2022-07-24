import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationApi {
  NotificationApi._();

  static final FlutterLocalNotificationsPlugin _localNotification =
      FlutterLocalNotificationsPlugin();

  static const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  static const InitializationSettings initializationSettings =
      InitializationSettings(android: androidInitializationSettings);

  static Future<void> initNotification() async {
    _localNotification.initialize(
      initializationSettings,
      onSelectNotification: (String? payload) async {
        if (payload != null) {
          debugPrint("Notification Payload $payload");
        }
      },
    );
  }

  static Future showNotification({
    int id = 0,
    required String title,
    String? payload,
    required int progress,
    required String icon,
  }) async {
    _localNotification.show(id, title, "Downloading ...",
        await notificationDetails(progress: progress, icon: icon),
        payload: payload);
  }

  static Future notificationDetails(
      {required int progress, required String icon}) async {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        "channelId",
        "channelName",
        channelDescription: "Download Progress",
        channelShowBadge: false,
        onlyAlertOnce: true,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        icon: icon,
        color: const Color((0xFFFFFFFF)),
      ),
      iOS: const IOSNotificationDetails(),
    );
  }

  static Future showDownloadInfoNotification({
    int id = 1,
    required String title,
    required String body,
    String? payload,
    required String icon,
  }) async {
    _localNotification.show(
        id, title, body, await downloadInfosNotificationDetail(icon: icon),
        payload: payload);
  }

  static Future downloadInfosNotificationDetail({required String icon}) async {
    _localNotification.cancel(0);
    return NotificationDetails(
      android: AndroidNotificationDetails("channelId", "channelName",
          channelDescription: "Download Progress",
          importance: Importance.max,
          channelShowBadge: false,
          priority: Priority.high,
          icon: icon),
      iOS: const IOSNotificationDetails(),
    );
  }
}
