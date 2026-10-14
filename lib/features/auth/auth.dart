import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api.dart';
import 'auth_repository.dart';
import '../../core/notifications/notification_initializer.dart';
import '../../core/notifications/notification_router.dart';

import 'logout_service.dart';

final authProvider =
    AsyncNotifierProvider<AuthController, Map<String, dynamic>?>(
      AuthController.new,
    );

class AuthController extends AsyncNotifier<Map<String, dynamic>?> {
  Dio get dio => ref.read(dioProvider);
  TokenStore get tokens => ref.read(tokenStoreProvider);
  late final AuthRepository authRepository = AuthRepository(dio);
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
    return authRepository.me();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      // 1. Login API
      final data = await authRepository.login(username, password);

      final access = (data['accessToken'] ?? data['access_token'] ?? '')
          .toString();

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
    await authRepository.register(name, username, email, password);
    await login(username, password);
  }

  Future<void> refresh() async {
    final refreshToken = await tokens.refresh;
    if (refreshToken == null) throw StateError('Missing refresh token');
    final data = await authRepository.refresh(refreshToken);
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
    // Attempt server-side revocation BEFORE deleting the refresh token.
    // Local logout must still complete when the network/backend fails.
    try {
      final refreshToken = await tokens.refresh;
      await LogoutService(dio).revoke(refreshToken: refreshToken);
    } on DioException catch (error) {
      // Do not log credentials, request bodies, or server response payloads.
      debugPrint(
        'Logout revocation failed: HTTP ${error.response?.statusCode ?? "network"}',
      );
    } catch (error) {
      debugPrint('Logout revocation failed: ${error.runtimeType}');
    } finally {
      NotificationRouter.clearOnLogout();
      // Security-critical cleanup first, independent of notification failures.
      try {
        await tokens.clear();
      } finally {
        state = const AsyncData(null);
        try {
          await ref.read(notificationInitializerProvider).dispose();
        } catch (error) {
          debugPrint('Notification cleanup failed: ${error.runtimeType}');
        }
      }
    }
  }
}
