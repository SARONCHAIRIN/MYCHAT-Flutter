import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mychat/features/messages/message_repository.dart';

void main() {
  test('history sends pagination parameters and parses response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.path, '/api/v1/conversations/42/messages');
      expect(options.queryParameters['limit'], 10);
      expect(options.queryParameters['before'], 'cursor-a');
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'data': {'messages': [{'id': 1, 'content': 'hello'}], 'nextCursor': 'cursor-b'}},
      ));
    }));
    final page = await MessageRepository(dio).history(42, before: 'cursor-a', limit: 10);
    expect(page.messages.single['content'], 'hello');
    expect(page.nextCursor, 'cursor-b');
  });

  test('send uses correct conversation route and payload', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.method, 'POST');
      expect(options.path, '/api/v1/conversations/42/messages');
      expect(options.data, {'content': 'hello', 'type': 'TEXT', 'replyToMessageId': 7});
      handler.resolve(Response(requestOptions: options, statusCode: 201, data: {'data': {'id': 8, 'content': 'hello'}}));
    }));
    final result = await MessageRepository(dio).send(42, 'hello', replyTo: 7);
    expect(result['id'], 8);
  });
}
