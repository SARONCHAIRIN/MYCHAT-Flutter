import 'package:dio/dio.dart';
import '../../core/network/api.dart';

/// Network-only authentication contract; no Firebase or widget dependencies.
class AuthRepository {
  final Dio dio;
  Future<Map<String, dynamic>>? _refreshInFlight;
  AuthRepository(this.dio);

  Future<Map<String, dynamic>> me() async => Map<String, dynamic>.from(
    unwrap((await dio.get('${ApiPaths.auth}/me')).data) as Map,
  );

  Future<Map<String, dynamic>> login(String username, String password) async =>
      Map<String, dynamic>.from(
        unwrap(
              (await dio.post(
                '${ApiPaths.auth}/login',
                data: {'username': username, 'password': password},
              )).data,
            )
            as Map,
      );

  Future<void> register(
    String name,
    String username,
    String email,
    String password,
  ) async {
    await dio.post(
      '${ApiPaths.auth}/register',
      data: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  /// Concurrent refresh requests share one network call per repository instance.
  Future<Map<String, dynamic>> refresh(String refreshToken) {
    final active = _refreshInFlight;
    if (active != null) return active;
    final future = _performRefresh(refreshToken);
    _refreshInFlight = future;
    future.then(
      (_) {
        if (identical(_refreshInFlight, future)) _refreshInFlight = null;
      },
      onError: (Object _, StackTrace __) {
        if (identical(_refreshInFlight, future)) _refreshInFlight = null;
      },
    );
    return future;
  }

  Future<Map<String, dynamic>> _performRefresh(String refreshToken) async =>
      Map<String, dynamic>.from(
        unwrap(
              (await dio.post(
                '${ApiPaths.auth}/refresh',
                data: {'refreshToken': refreshToken},
              )).data,
            )
            as Map,
      );
}
