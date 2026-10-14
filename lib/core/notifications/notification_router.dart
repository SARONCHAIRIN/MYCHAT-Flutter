import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../features/messages/chat_screen.dart';

/// Routes FCM taps only after the authenticated home is mounted.
class NotificationRouter {
  NotificationRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static RemoteMessage? _pendingMessage;
  static bool _authenticated = false;
  static String? _lastTapKey;
  static DateTime? _lastTapTime;

  /// Clear navigation from a previous account when explicitly logging out.
  static void clearOnLogout() {
    _authenticated = false;
    _pendingMessage = null;
    _lastTapKey = null;
    _lastTapTime = null;
  }

  static void setAuthenticated(bool value) {
    _authenticated = value;
    if (!value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openPendingMessage();
    });
  }

  static void openMessage(RemoteMessage message) {
    final data = message.data;
    final conversationId = int.tryParse(
      data['conversationId']?.toString() ?? '',
    );
    if (data['type']?.toString() != 'message:new' ||
        conversationId == null) {
      debugPrint('Ignoring non-chat notification: $data');
      return;
    }

    if (!_authenticated || navigatorKey.currentState == null) {
      _pendingMessage = message;
      debugPrint('Notification queued until authenticated home is ready');
      return;
    }

    final tapKey =
        message.messageId ?? '$conversationId:${data['messageId']}';
    final now = DateTime.now();
    if (_lastTapKey == tapKey &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(seconds: 3)) {
      debugPrint('Duplicate notification tap ignored');
      return;
    }

    _lastTapKey = tapKey;
    _lastTapTime = now;
    _pendingMessage = null;
    debugPrint('Opening ChatScreen: $conversationId');
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: conversationId),
      ),
    );
  }

  static void openPendingMessage() {
    if (!_authenticated || navigatorKey.currentState == null) return;
    final message = _pendingMessage;
    if (message == null) return;
    _pendingMessage = null;
    openMessage(message);
  }
}
