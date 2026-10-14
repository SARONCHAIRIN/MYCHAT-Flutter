import 'package:dio/dio.dart';

class DeviceRegistrationRepository {
  final Dio dio;

  DeviceRegistrationRepository(this.dio);

  Future<void> register({
    required String token,
    required String platform,
  }) async {
    final response = await dio.post(
      '/api/v1/devices', // Verify with backend Swagger
      data: {
        'token': token,
        'platform': platform,
      },
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'FCM registration failed: ${response.statusCode}',
      );
    }
  }
}