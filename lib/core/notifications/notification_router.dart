import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../features/messages/chat_screen.dart';

class NotificationRouter {
  NotificationRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static RemoteMessage? _pendingMessage;

  static String? _lastTapKey;
  static DateTime? _lastTapTime;

  static void openMessage(RemoteMessage message) {
    final data = message.data;

    debugPrint('Notification payload: $data');

    final type = data['type']?.toString();
    final conversationId = int.tryParse(
      data['conversationId']?.toString() ?? '',
    );

    if (type != 'message:new' || conversationId == null) {
      debugPrint('Invalid chat notification payload');
      return;
    }

    final tapKey =
        message.messageId ?? '${data['conversationId']}:${data['messageId']}';

    final now = DateTime.now();

    if (_lastTapKey == tapKey &&
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(seconds: 2)) {
      debugPrint('Duplicate notification tap ignored');
      return;
    }

    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      _pendingMessage = message;
      debugPrint('Navigator not ready; notification queued');
      return;
    }

    _lastTapKey = tapKey;
    _lastTapTime = now;
    _pendingMessage = null;

    debugPrint('Opening ChatScreen: $conversationId');

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: conversationId),
      ),
    );
  }

  static void openPendingMessage() {
    final message = _pendingMessage;

    if (message == null) return;

    _pendingMessage = null;
    openMessage(message);
  }
}
