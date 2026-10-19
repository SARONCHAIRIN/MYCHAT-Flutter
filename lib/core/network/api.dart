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

/// Shares refresh across concurrent 401s and retries the original request once.
final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.read(tokenStoreProvider);
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Accept': 'application/json'},
  ));
  Future<String?>? refreshInFlight;

  Future<String?> refreshAccessToken() async {
    final pending = refreshInFlight;
    if (pending != null) return pending;
    final future = () async {
      final refresh = await tokens.refresh;
      if (refresh == null || refresh.isEmpty) return null;
      // Use a separate Dio client to avoid recursive auth interceptors.
      final client = Dio(BaseOptions(baseUrl: apiBaseUrl));
      try {
        final response = await client.post('${ApiPaths.auth}/refresh',
          data: {'refreshToken': refresh});
        final payload = unwrap(response.data);
        if (payload is! Map) return null;
        final access = (payload['accessToken'] ?? payload['access_token'] ?? '').toString();
        if (access.isEmpty) return null;
        final rotated = (payload['refreshToken'] ?? payload['refresh_token'])?.toString();
        await tokens.save(access, rotated ?? refresh);
        return access;
      } on DioException {
        // A failed refresh must not wipe valid credentials on a transient outage.
        return null;
      } finally {
        client.close();
      }
    }();
    refreshInFlight = future;
    try { return await future; } finally { refreshInFlight = null; }
  }

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final path = options.uri.path;
      final isPublic = path == '${ApiPaths.auth}/login' ||
          path == '${ApiPaths.auth}/register' ||
          path == '${ApiPaths.auth}/refresh';
      if (!isPublic) {
        final access = await tokens.access;
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      final request = error.requestOptions;
      final path = request.uri.path;
      if (error.response?.statusCode != 401 ||
          request.extra['authRetried'] == true ||
          path.startsWith(ApiPaths.auth)) {
        return handler.next(error);
      }
      try {
        // Another request may already have refreshed the access token.
        final current = await tokens.access;
        final oldHeader = request.headers['Authorization']?.toString();
        final access = current != null && current.isNotEmpty &&
                oldHeader != 'Bearer $current'
            ? current : await refreshAccessToken();
        if (access == null) return handler.next(error);
        request.extra['authRetried'] = true;
        request.headers['Authorization'] = 'Bearer $access';
        final result = await dio.fetch<dynamic>(request);
        return handler.resolve(result);
      } catch (_) {
        return handler.next(error);
      }
    },
  ));
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
