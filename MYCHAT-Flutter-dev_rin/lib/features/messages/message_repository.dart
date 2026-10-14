import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api.dart';

typedef MessageJson = Map<String, dynamic>;
final messageRepositoryProvider = Provider(
  (ref) => MessageRepository(ref.read(dioProvider)),
);

class MessagePage {
  final List<MessageJson> messages;
  final String? nextCursor;
  const MessagePage(this.messages, this.nextCursor);
}

class MessageRepository {
  final Dio dio;
  MessageRepository(this.dio);
  String base(Object conversationId) => '/api/v1/conversations/$conversationId';
  Future<MessagePage> history(
    Object id, {
    String? before,
    int limit = 20,
  }) async {
    final response = await dio.get(
      '${base(id)}/messages',
      queryParameters: {'limit': limit, if (before != null) 'before': before},
    );
    final data = unwrap(response.data);
    final list = data is List
        ? data
        : data is Map
        ? (data['messages'] ?? data['content'] ?? data['items'] ?? <dynamic>[])
        : <dynamic>[];
    final items = (list as List)
        .map((e) => MessageJson.from(e as Map))
        .toList();
    final cursor = data is Map
        ? (data['nextCursor'] ?? data['next_cursor'])?.toString()
        : null;
    return MessagePage(items, cursor);
  }

  Future<MessageJson> send(Object id, String content, {Object? replyTo}) async {
    final res = await dio.post(
      '${base(id)}/messages',
      data: {
        'content': content,
        'type': 'TEXT',
        if (replyTo != null) 'replyToMessageId': replyTo,
      },
    );
    return MessageJson.from(unwrap(res.data) as Map);
  }

  Future<MessageJson> get(Object id) async => MessageJson.from(
    unwrap((await dio.get('/api/v1/messages/$id')).data) as Map,
  );
  Future<MessageJson> edit(Object id, String content) async => MessageJson.from(
    unwrap(
          (await dio.patch(
            '/api/v1/messages/$id',
            data: {'content': content},
          )).data,
        )
        as Map,
  );
  Future<void> delete(Object id) async {
    await dio.delete('/api/v1/messages/$id');
  }

  Future<List<MessageJson>> reactions(Object id) async => listPayload(
    (await dio.get('/api/v1/messages/$id/reactions')).data,
  ).map((e) => MessageJson.from(e as Map)).toList();
  Future<void> react(Object id, String emoji) async {
    await dio.post('/api/v1/messages/$id/reactions', data: {'emoji': emoji});
  }

  Future<void> unreact(Object id, String emoji) async {
    await dio.delete(
      '/api/v1/messages/$id/reactions/${Uri.encodeComponent(emoji)}',
    );
  }

  Future<void> delivered(Object id) async {
    await dio.post('/api/v1/messages/$id/delivered');
  }

  Future<void> read(Object id) async {
    await dio.post('/api/v1/messages/$id/read');
  }

  Future<MessageJson> upload(
    Object messageId,
    String path, {
    ProgressCallback? progress,
  }) async {
    final data = FormData.fromMap({
      'messageId': messageId.toString(),
      'file': await MultipartFile.fromFile(
        path,
        filename: path.split('/').last,
      ),
    });
    final response = await dio.post(
      '/api/v1/uploads',
      data: data,
      onSendProgress: progress,
    );
    return MessageJson.from(unwrap(response.data) as Map);
  }

  Future<void> pin(Object conversationId, Object messageId) async {
    await dio.post('${base(conversationId)}/pins/$messageId');
  }

  Future<void> unpin(Object conversationId, Object messageId) async {
    await dio.delete('${base(conversationId)}/pins/$messageId');
  }

  Future<List<MessageJson>> pins(Object conversationId) async => listPayload(
    (await dio.get('${base(conversationId)}/pins')).data,
  ).map((e) => MessageJson.from(e as Map)).toList();
}

String messageKey(MessageJson m) =>
    (m['id'] ?? m['messageId'] ?? '').toString();
List<MessageJson> mergeMessages(
  List<MessageJson> existing,
  List<MessageJson> incoming,
) {
  final byId = <String, MessageJson>{};
  for (final message in [...existing, ...incoming]) {
    final key = messageKey(message);
    if (key.isNotEmpty) {
      byId[key] = message;
    }
  }
  return byId.values.toList()..sort(
    (a, b) => (a['createdAt'] ?? a['created_at'] ?? '').toString().compareTo(
      (b['createdAt'] ?? b['created_at'] ?? '').toString(),
    ),
  );
}
