import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api.dart';
import 'firebase_messaging_service.dart';
import 'notification_router.dart';

final notificationInitializerProvider = Provider<NotificationInitializer>((ref) {
  final initializer = NotificationInitializer(dio: ref.read(dioProvider));
  ref.onDispose(() {
    unawaited(initializer.dispose());
  });
  return initializer;
});

class NotificationInitializer {
  NotificationInitializer({required this.dio});

  final Dio dio;
  Future<void>? _initialization;

  /// Idempotent: login and session restoration can both call this.
  Future<void> initialize() {
    return _initialization ??= _initializeOnce().catchError((Object error) {
      _initialization = null;
      throw error;
    });
  }

  Future<void> _initializeOnce() async {
    await FirebaseMessagingService.instance.initialize(
      onToken: (token) async {
        try {
          final response = await dio.post(
            '/api/v1/devices',
            data: {
              // A generic name avoids falsely identifying other phones as Samsung.
              'deviceName': 'MYCHAT Android device',
              'platform': 'ANDROID',
              'fcmToken': token,
            },
          );
          debugPrint('FCM device registration: ${response.statusCode}');
        } on DioException catch (error) {
          debugPrint('FCM registration failed: ${error.response?.statusCode}');
          rethrow;
        }
      },
      onMessage: (message) {
        debugPrint('Foreground notification: ${message.data}');
        // Message refresh / foreground presentation is separate work.
      },
      onNotificationTap: NotificationRouter.openMessage,
    );
  }

  Future<void> dispose() async {
    _initialization = null;
    await FirebaseMessagingService.instance.dispose();
  }
}
