import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_router.dart';

/// Foreground Android banner. Background/terminated notifications remain FCM-owned.
class ForegroundNotificationService {
  ForegroundNotificationService._();
  static final instance = ForegroundNotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready || kIsWeb || defaultTargetPlatform != TargetPlatform.android)
      return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
          NotificationRouter.openData(data);
        } catch (error) {
          debugPrint('Invalid notification tap payload: $error');
        }
      },
    );
    const channel = AndroidNotificationChannel(
      'mychat_messages',
      'Messages',
      description: 'Incoming MYCHAT messages',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    _ready = true;
  }

  Future<void> show(RemoteMessage message) async {
    if (!_ready) return;
    final notification = message.notification;
    final title = notification?.title ?? 'New message';
    final body = notification?.body ?? 'You received a new message';
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mychat_messages',
        'Messages',
        channelDescription: 'Incoming MYCHAT messages',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }
}
