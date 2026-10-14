import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Background FCM message received: ${message.messageId}');
}

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  Future<String?> initialize({
    required Future<void> Function(String token) onToken,
    void Function(RemoteMessage message)? onMessage,
    void Function(RemoteMessage message)? onNotificationTap,
  }) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    // 1. Get and register FCM token
    final token = await _messaging.getToken();

    if (token != null && token.isNotEmpty) {
      try {
        await onToken(token);
        debugPrint('FCM device registration completed');
      } catch (error) {
        debugPrint('FCM device registration failed: $error');
      }
    }

    // 2. Handle token refresh
    await _tokenSubscription?.cancel();

    _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) async {
      try {
        await onToken(newToken);
      } catch (error) {
        debugPrint('FCM token refresh failed: $error');
      }
    });

    // 3. Foreground messages
    await _messageSubscription?.cancel();

    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground FCM received: ${message.messageId}');

      onMessage?.call(message);
    });

    // 4. Notification tapped from background
    await _openedSubscription?.cancel();

    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      debugPrint('Notification tapped: ${message.messageId}');

      onNotificationTap?.call(message);
    });

    // 5. Notification tapped from terminated state
    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('Initial notification: ${initialMessage.messageId}');

      onNotificationTap?.call(initialMessage);
    }

    return token;
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();

    _tokenSubscription = null;
    _messageSubscription = null;
    _openedSubscription = null;
  }
}
