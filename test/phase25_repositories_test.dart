import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mychat/core/network/api.dart';
import 'package:mychat/features/data/repositories.dart';
import 'package:mychat/features/messages/message_repository.dart';

Dio mockDio(void Function(RequestOptions, RequestInterceptorHandler) handle) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: handle));
  return dio;
}

void main() {
  test('conversation list supports paginated content envelope', () async {
    final repo = ConversationRepository(
      mockDio((o, h) {
        expect(o.method, 'GET');
        expect(o.path, '/api/v1/conversations');
        h.resolve(
          Response(
            requestOptions: o,
            data: {
              'data': {
                'content': [
                  {'id': 1},
                  {'id': 2},
                ],
              },
            },
            statusCode: 200,
          ),
        );
      }),
    );
    expect((await repo.list()).map((e) => e['id']), [1, 2]);
  });

  test('conversation create passes payload', () async {
    final repo = ConversationRepository(
      mockDio((o, h) {
        expect(o.method, 'POST');
        expect(o.data, {'type': 'DIRECT', 'participantId': 9});
        h.resolve(
          Response(
            requestOptions: o,
            data: {
              'data': {'id': 7},
            },
            statusCode: 201,
          ),
        );
      }),
    );
    expect(
      (await repo.create({'type': 'DIRECT', 'participantId': 9}))['id'],
      7,
    );
  });

  test('user search passes query and pagination', () async {
    final repo = UserRepository(
      mockDio((o, h) {
        expect(o.path, '/api/v1/users/search');
        expect(o.queryParameters, {'q': 'alice', 'page': 2, 'size': 5});
        h.resolve(
          Response(
            requestOptions: o,
            data: {
              'data': [
                {'id': 8},
              ],
            },
            statusCode: 200,
          ),
        );
      }),
    );
    expect((await repo.search('alice', page: 2, size: 5)).single['id'], 8);
  });

  test('reaction add/remove use emoji routes', () async {
    var calls = 0;
    final repo = MessageRepository(
      mockDio((o, h) {
        calls++;
        if (calls == 1) {
          expect(o.method, 'POST');
          expect(o.path, '/api/v1/messages/7/reactions');
          expect(o.data, {'emoji': '👍'});
        } else {
          expect(o.method, 'DELETE');
          expect(o.path, contains('/api/v1/messages/7/reactions/'));
          expect(Uri.decodeComponent(o.path.split('/').last), '👍');
        }
        h.resolve(Response(requestOptions: o, statusCode: 204));
      }),
    );
    await repo.react(7, '👍');
    await repo.unreact(7, '👍');
    expect(calls, 2);
  });

  test('error mapping prefers server message', () {
    final o = RequestOptions(path: '/test');
    final e = DioException(
      requestOptions: o,
      response: Response(
        requestOptions: o,
        data: {'message': 'Validation failed'},
        statusCode: 422,
      ),
    );
    expect(apiError(e), 'Validation failed');
  });

  test('error mapping handles non-dio exceptions', () {
    expect(apiError(StateError('oops')), contains('oops'));
  });

  test('unwrap and listPayload support API envelope variants', () {
    expect(
      unwrap({
        'data': {'id': 3},
      }),
      {'id': 3},
    );
    expect(
      listPayload({
        'data': {
          'items': [
            {'id': 1},
          ],
        },
      }),
      hasLength(1),
    );
    expect(listPayload({'data': null}), isEmpty);
  });

  test('mergeMessages uses last incoming version', () {
    final merged = mergeMessages(
      [
        {'id': 5, 'content': 'old', 'createdAt': '2026-01-01'},
      ],
      [
        {'id': 5, 'content': 'new', 'createdAt': '2026-01-01'},
      ],
    );
    expect(merged.single['content'], 'new');
  });
}
