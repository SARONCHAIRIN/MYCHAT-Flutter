
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api.dart';
import 'firebase_messaging_service.dart';
import 'notification_router.dart';


final notificationInitializerProvider =
    Provider<NotificationInitializer>((ref) {
  return NotificationInitializer(
    dio: ref.read(dioProvider),
  );
});

class NotificationInitializer {
  NotificationInitializer({required this.dio});

  final Dio dio;

  Future<void> initialize() async {
    await FirebaseMessagingService.instance.initialize(
      // 1. Register FCM token to MYCHAT Backend
      onToken: (token) async {
        try {
          final response = await dio.post(
            '/api/v1/devices',
            data: {
              'deviceName': 'Samsung SM A556E',
              'platform': 'ANDROID',
              'fcmToken': token,
            },
          );

          debugPrint(
            'FCM REGISTER STATUS: ${response.statusCode}',
          );

          debugPrint(
            'FCM DEVICE REGISTERED SUCCESSFULLY',
          );
        } on DioException catch (error) {
          debugPrint(
            'FCM REGISTER ERROR: ${error.response?.statusCode}',
          );

          debugPrint(
            'FCM REGISTER RESPONSE: ${error.response?.data}',
          );

          rethrow;
        }
      },

      // 2. Receive message while app is open
      onMessage: (message) {
        debugPrint(
          'Foreground notification: ${message.data}',
        );

        // TODO: Refresh conversation/message query.
      },

      // 3. Open chat when notification is tapped
      onNotificationTap: (message) {
        debugPrint(
          'Notification tapped: ${message.data}',
        );

        NotificationRouter.openMessage(message);
      },
    );
  }
}
