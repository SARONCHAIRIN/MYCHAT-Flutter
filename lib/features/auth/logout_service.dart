import 'package:dio/dio.dart';
import '../../core/network/api.dart';

/// Backend revocation request. The server must confirm the expected DTO.
/// MYCHAT refresh uses `refreshToken`, so we use the same field for logout.
class LogoutService {
  final Dio dio;
  const LogoutService(this.dio);

  Future<void> revoke({String? refreshToken}) async {
    await dio.post(
      '${ApiPaths.auth}/logout',
      // Send JSON only when a refresh token is present.
      data: refreshToken == null || refreshToken.isEmpty
          ? null
          : <String, String>{'refreshToken': refreshToken},
    );
  }
}
