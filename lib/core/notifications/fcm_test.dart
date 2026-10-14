import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

Future<String?> testGetFcmToken() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // 1. Request notification permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("=====================================");
    debugPrint('FCM Permission: ${settings.authorizationStatus}');

    // 2. Get FCM token
    final token = await messaging.getToken();

    if (token == null) {
      debugPrint('FCM TOKEN: NULL');
      return null;
    }

    debugPrint('FCM TOKEN SUCCESS');
    debugPrint('FCM Token length: ${token.length}');

    // Only enable this temporarily for testing.
    if (kDebugMode) {
      debugPrint('FCM TOKEN: $token');
    }

    return token;
  } catch (error) {
    debugPrint('FCM ERROR: $error');
    return null;
  }
}
