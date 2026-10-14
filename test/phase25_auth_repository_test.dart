import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mychat/features/auth/auth_repository.dart';

Dio fakeDio(
  FutureOr<void> Function(RequestOptions, RequestInterceptorHandler) handler,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, next) async {
        await handler(options, next);
      },
    ),
  );
  return dio;
}

void main() {
  test('login sends username/password and unwraps API envelope', () async {
    final repo = AuthRepository(
      fakeDio((options, next) {
        expect(options.path, '/api/v1/auth/login');
        expect(options.method, 'POST');
        expect(options.data, {'username': 'alice', 'password': 'pw'});
        next.resolve(
          Response(
            requestOptions: options,
            data: {
              'data': {'accessToken': 'access', 'refreshToken': 'refresh'},
            },
            statusCode: 200,
          ),
        );
      }),
    );
    expect((await repo.login('alice', 'pw'))['accessToken'], 'access');
  });

  test('register sends exact contract payload', () async {
    final repo = AuthRepository(
      fakeDio((options, next) {
        expect(options.path, '/api/v1/auth/register');
        expect(options.data, {
          'name': 'Alice',
          'username': 'alice',
          'email': 'a@example.invalid',
          'password': 'pw',
        });
        next.resolve(Response(requestOptions: options, statusCode: 201));
      }),
    );
    await repo.register('Alice', 'alice', 'a@example.invalid', 'pw');
  });

  test('me maps user object', () async {
    final repo = AuthRepository(
      fakeDio((options, next) {
        expect(options.path, '/api/v1/auth/me');
        next.resolve(
          Response(
            requestOptions: options,
            data: {
              'data': {'id': 42},
            },
            statusCode: 200,
          ),
        );
      }),
    );
    expect((await repo.me())['id'], 42);
  });

  test(
    'refresh shares in-flight network call and retries after success',
    () async {
      var calls = 0;
      final pending = <RequestInterceptorHandler>[];
      final optionsSeen = <RequestOptions>[];
      final repo = AuthRepository(
        fakeDio((options, next) {
          calls++;
          expect(options.path, '/api/v1/auth/refresh');
          expect(options.data, {'refreshToken': 'old'});
          pending.add(next);
          optionsSeen.add(options);
        }),
      );
      final a = repo.refresh('old');
      final b = repo.refresh('old');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls, 1);
      pending
          .removeAt(0)
          .resolve(
            Response(
              requestOptions: optionsSeen.removeAt(0),
              statusCode: 200,
              data: {
                'data': {'accessToken': 'new'},
              },
            ),
          );
      expect((await a)['accessToken'], 'new');
      expect((await b)['accessToken'], 'new');
      await Future<void>.delayed(Duration.zero);
      final c = repo.refresh('old');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls, 2);
      pending
          .removeAt(0)
          .resolve(
            Response(
              requestOptions: optionsSeen.removeAt(0),
              statusCode: 200,
              data: {
                'data': {'accessToken': 'newer'},
              },
            ),
          );
      expect((await c)['accessToken'], 'newer');
    },
  );

  test('refresh failure is propagated and future request can retry', () async {
    var calls = 0;
    final repo = AuthRepository(
      fakeDio((options, next) {
        calls++;
        if (calls == 1) {
          next.reject(
            DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 401),
              type: DioExceptionType.badResponse,
            ),
          );
        } else {
          next.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': {'accessToken': 'ok'},
              },
            ),
          );
        }
      }),
    );
    await expectLater(repo.refresh('old'), throwsA(isA<DioException>()));
    expect((await repo.refresh('old'))['accessToken'], 'ok');
    expect(calls, 2);
  });
}
