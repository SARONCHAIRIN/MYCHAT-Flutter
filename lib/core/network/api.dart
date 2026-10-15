import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiPaths {
  static const auth = '/api/v1/auth';
  static const users = '/api/v1/users';
  static const conversations = '/api/v1/conversations';
}

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://mychat-umla.onrender.com',
);

const secureStorage = FlutterSecureStorage();
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

class TokenStore {
  final FlutterSecureStorage storage;
  TokenStore({FlutterSecureStorage? storage})
    : storage = storage ?? secureStorage;
  Future<String?> get access => storage.read(key: 'access_token');
  Future<String?> get refresh => storage.read(key: 'refresh_token');
  Future<void> save(String access, String? refresh) async {
    await storage.write(key: 'access_token', value: access);
    if (refresh != null) {
      await storage.write(key: 'refresh_token', value: refresh);
    } else {
      await storage.delete(key: 'refresh_token');
    }
  }

  Future<void> clear() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }
}

final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.read(tokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final path = options.uri.path;

        final isPublicAuth =
            path == '${ApiPaths.auth}/login' ||
            path == '${ApiPaths.auth}/register';

        options.headers.remove('Authorization');
        if (!isPublicAuth) {
          final token = await tokens.access;

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        handler.next(options);
      },

    ),
  );

  return dio;
});

dynamic unwrap(dynamic body) =>
    body is Map && body.containsKey('data') ? body['data'] : body;
List<dynamic> listPayload(dynamic body) {
  final data = unwrap(body);
  if (data is List) return data;
  if (data is Map && data['content'] is List) return data['content'] as List;
  if (data is Map && data['items'] is List) return data['items'] as List;
  return [];
}

String apiError(Object error) {
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map) {
      return (body['message'] ??
              body['error'] ??
              error.message ??
              'Request failed')
          .toString();
    }
    return error.message ?? 'Network error';
  }
  return error.toString();
}
