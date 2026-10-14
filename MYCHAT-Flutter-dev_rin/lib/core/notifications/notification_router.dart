import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../features/messages/chat_screen.dart';

/// Routes FCM taps only after the authenticated home is mounted.
class NotificationRouter {
  NotificationRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Map<String, dynamic>? _pendingData;
  static String? _pendingTapId;
  static bool _authenticated = false;
  static String? _lastTapKey;
  static DateTime? _lastTapTime;

  /// Clear navigation from a previous account when explicitly logging out.
  static void clearOnLogout() {
    _authenticated = false;
    _pendingData = null;
    _pendingTapId = null;
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
    openData(message.data, tapId: message.messageId);
  }

  static void openData(Map<String, dynamic> data, {String? tapId}) {
    final conversationId = int.tryParse(
      data['conversationId']?.toString() ?? '',
    );
    if (data['type']?.toString() != 'message:new' ||
        conversationId == null) {
      debugPrint('Ignoring non-chat notification: $data');
      return;
    }

    if (!_authenticated || navigatorKey.currentState == null) {
      _pendingData = Map<String, dynamic>.from(data);
      _pendingTapId = tapId;
      debugPrint('Notification queued until authenticated home is ready');
      return;
    }

    final tapKey =
        tapId ?? '$conversationId:${data['messageId']}';
    final now = DateTime.now();
    if (_lastTapKey == tapKey &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(seconds: 3)) {
      debugPrint('Duplicate notification tap ignored');
      return;
    }

    _lastTapKey = tapKey;
    _lastTapTime = now;
    _pendingData = null;
    _pendingTapId = null;
    debugPrint('Opening ChatScreen: $conversationId');
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: conversationId),
      ),
    );
  }

  static void openPendingMessage() {
    if (!_authenticated || navigatorKey.currentState == null) return;
    final data = _pendingData;
    if (data == null) return;
    final tapId = _pendingTapId;
    _pendingData = null;
    _pendingTapId = null;
    openData(data, tapId: tapId);
  }
}
