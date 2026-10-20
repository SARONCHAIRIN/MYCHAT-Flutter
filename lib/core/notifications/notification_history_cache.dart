import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api.dart';

/// Device-local fallback for FCM messages when the API has no history.
/// Keyed by JWT subject so different accounts do not share notifications.
class NotificationHistoryCache {
  static Future<String?> _key() async {
    final access = await TokenStore().access;
    if (access == null) return null;
    try {
      final parts = access.split('.');
      if (parts.length != 3) return null;
      final claims = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final sub = claims['sub']?.toString();
      return sub == null || sub.isEmpty ? null : 'mychat_push_history_$sub';
    } catch (_) { return null; }
  }

  static Future<List<Map<String, dynamic>>> read() async {
    final key = await _key();
    if (key == null) return [];
    try {
      final raw = await secureStorage.read(key: key);
      final list = jsonDecode(raw ?? '[]');
      return list is List ? list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
    } catch (_) { return []; }
  }

  static Future<void> save(RemoteMessage message) async {
    final key = await _key();
    if (key == null) return;
    final data = message.data;
    final id = message.messageId ?? '${data['messageId'] ?? DateTime.now().microsecondsSinceEpoch}';
    final item = <String, dynamic>{
      'id': 'push-$id',
      'messageId': data['messageId'],
      'conversationId': data['conversationId'],
      'title': message.notification?.title ?? data['senderName'] ?? 'New message',
      'body': message.notification?.body ?? data['body'] ?? data['content'] ?? '',
      'senderAvatarUrl': data['senderAvatarUrl'] ?? data['senderAvatar'] ?? data['avatarUrl'],
      'createdAt': message.sentTime?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
      'isRead': false,
      'localOnly': true,
    };
    final old = await read();
    old.removeWhere((n) => n['id'] == item['id']);
    old.insert(0, item);
    await secureStorage.write(key: key, value: jsonEncode(old.take(100).toList()));
  }

  static Future<void> markRead(Object id) async {
    final key = await _key();
    if (key == null) return;
    final items = await read();
    for (final item in items) { if (item['id'] == id) item['isRead'] = true; }
    await secureStorage.write(key: key, value: jsonEncode(items));
  }

  static Future<void> markAllRead() async {
    final key = await _key();
    if (key == null) return;
    final items = await read();
    for (final item in items) { item['isRead'] = true; }
    await secureStorage.write(key: key, value: jsonEncode(items));
  }

  static Future<void> delete(Object id) async {
    final key = await _key();
    if (key == null) return;
    final items = await read();
    items.removeWhere((n) => n['id'] == id);
    await secureStorage.write(key: key, value: jsonEncode(items));
  }
}
