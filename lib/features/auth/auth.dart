import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api.dart';
import 'package:dio/dio.dart';

final authProvider =
    AsyncNotifierProvider<AuthController, Map<String, dynamic>?>(
      AuthController.new,
    );

class AuthController extends AsyncNotifier<Map<String, dynamic>?> {
  Dio get dio => ref.read(dioProvider);
  TokenStore get tokens => ref.read(tokenStoreProvider);
  @override
  Future<Map<String, dynamic>?> build() async {
    final token = await tokens.access;
    if (token == null) return null;
    try {
      return await me();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> me() async {
    final response = await dio.get('${ApiPaths.auth}/me');
    return Map<String, dynamic>.from(unwrap(response.data) as Map);
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await dio.post(
        '${ApiPaths.auth}/login',
        data: {'username': username, 'password': password},
      );
      final data = Map<String, dynamic>.from(unwrap(response.data) as Map);
      final access = (data['accessToken'] ?? data['access_token'] ?? '')
          .toString();
      if (access.isEmpty)
        throw StateError('Login response missing access token');
      await tokens.save(
        access,
        (data['refreshToken'] ?? data['refresh_token'])?.toString(),
      );
      return me();
    });
  }

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
    await login(username, password);
  }

  Future<void> refresh() async {
    final refreshToken = await tokens.refresh;
    if (refreshToken == null) throw StateError('Missing refresh token');
    final response = await dio.post(
      '${ApiPaths.auth}/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = Map<String, dynamic>.from(unwrap(response.data) as Map);
    final access = (data['accessToken'] ?? data['access_token'] ?? '')
        .toString();
    if (access.isEmpty)
      throw StateError('Refresh response missing access token');
    await tokens.save(
      access,
      (data['refreshToken'] ?? data['refresh_token'])?.toString() ??
          refreshToken,
    );
    state = await AsyncValue.guard(me);
  }

  Future<void> logout() async {
    try {
      await dio.post('${ApiPaths.auth}/logout');
    } finally {
      await tokens.clear();
      state = const AsyncData(null);
    }
  }
}
