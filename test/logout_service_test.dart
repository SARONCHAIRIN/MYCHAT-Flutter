import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mychat/features/auth/logout_service.dart';

void main() {
  test('logout sends refresh token in JSON body', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'POST');
          expect(options.path, '/api/v1/auth/logout');
          expect(options.data, {'refreshToken': 'test-refresh'});
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ),
    );
    await LogoutService(dio).revoke(refreshToken: 'test-refresh');
  });

  test('logout omits body when refresh token is absent', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.data, isNull);
          handler.resolve(Response(requestOptions: options, statusCode: 204));
        },
      ),
    );
    await LogoutService(dio).revoke();
  });

  test('logout propagates backend errors to caller for handling', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 400),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );
    await expectLater(
      LogoutService(dio).revoke(refreshToken: 'x'),
      throwsA(isA<DioException>()),
    );
  });
}
