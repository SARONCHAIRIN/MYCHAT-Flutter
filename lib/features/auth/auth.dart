import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api.dart';
import '../../core/notifications/notification_initializer.dart';
import '../../core/notifications/notification_router.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    // 1. Login API
    final response = await dio.post(
      '${ApiPaths.auth}/login',
      data: {
        'username': username,
        'password': password,
      },
    );

    final data = Map<String, dynamic>.from(
      unwrap(response.data) as Map,
    );

    final access =
        (data['accessToken'] ?? data['access_token'] ?? '').toString();

    if (access.isEmpty) {
      throw StateError('Login response missing access token');
    }

    // 2. Save authentication tokens
    await tokens.save(
      access,
      (data['refreshToken'] ?? data['refresh_token'])?.toString(),
    );

    try {
      await ref.read(notificationInitializerProvider).initialize();
    } catch (error) {
      debugPrint('Notification initialization failed: $error');
    }
    // 4. Get current user profile
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
    final response = await dio.post(
      '${ApiPaths.auth}/logout',
    );

    debugPrint('Logout status: ${response.statusCode}');
  } on DioException catch (error) {
    debugPrint(
      'Logout API status: ${error.response?.statusCode}',
    );

    final data = error.response?.data;

    if (data is Map) {
      debugPrint('Logout error code: ${data['code']}');
      debugPrint('Logout error message: ${data['message']}');
    }
  } catch (error) {
    debugPrint('Logout error: ${error.runtimeType}');
  } finally {
    NotificationRouter.clearOnLogout();

    try {
      await ref.read(notificationInitializerProvider).dispose();
    } catch (error) {
      debugPrint(
        'Notification cleanup failed: ${error.runtimeType}',
      );
    }

    try {
      await tokens.clear();
    } finally {
      state = const AsyncData(null);
    }
  }
}


}
