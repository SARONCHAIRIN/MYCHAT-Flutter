import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api.dart';
import 'package:flutter/foundation.dart';
typedef Json = Map<String, dynamic>;
Json asJson(dynamic value) => Json.from(unwrap(value) as Map);
final userRepositoryProvider = Provider(
  (ref) => UserRepository(ref.read(dioProvider)),
);
final conversationRepositoryProvider = Provider(
  (ref) => ConversationRepository(ref.read(dioProvider)),
);

class UserRepository {
  final Dio dio;
  UserRepository(this.dio);
  Future<Json> me() async =>
      asJson((await dio.get('${ApiPaths.users}/me')).data);
  Future<Json> byId(Object id) async =>
      asJson((await dio.get('${ApiPaths.users}/$id')).data);
  Future<Json> update(Json patch) async =>
      asJson((await dio.patch('${ApiPaths.users}/me', data: patch)).data);
  /// Upload the selected image to the backend (multipart field name: file).
  Future<dynamic> uploadAvatar(String filePath) async {
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(
      filePath,
      filename: filePath.split('/').last,
    ),
  });

  try {
    debugPrint('Starting avatar upload...');

    final response = await dio.patch(
      '/api/v1/users/me/avatar',
      data: formData,
    );

    debugPrint('Avatar status: ${response.statusCode}');
    debugPrint('Avatar response: ${response.data}');

    return response.data;
  } on DioException catch (e) {
    debugPrint('Avatar upload failed: ${e.response?.statusCode}');
    debugPrint('Response: ${e.response?.data}');
    rethrow;
  }
}
  Future<List<Json>> list({int page = 0, int size = 20}) async => listPayload(
    (await dio.get(
      ApiPaths.users,
      queryParameters: {'page': page, 'size': size},
    )).data,
  ).map((e) => Json.from(e as Map)).toList();
  Future<List<Json>> search(String q, {int page = 0, int size = 20}) async =>
      listPayload(
        (await dio.get(
          '${ApiPaths.users}/search',
          queryParameters: {'q': q, 'page': page, 'size': size},
        )).data,
      ).map((e) => Json.from(e as Map)).toList();
}

class ConversationRepository {
  final Dio dio;
  ConversationRepository(this.dio);
  Future<List<Json>> list() async => listPayload(
    (await dio.get(ApiPaths.conversations)).data,
  ).map((e) => Json.from(e as Map)).toList();
  Future<Json> byId(Object id) async =>
      asJson((await dio.get('${ApiPaths.conversations}/$id')).data);
  Future<Json> create(Json payload) async =>
      asJson((await dio.post(ApiPaths.conversations, data: payload)).data);
  Future<Json> update(Object id, Json payload) async => asJson(
    (await dio.patch('${ApiPaths.conversations}/$id', data: payload)).data,
  );
  Future<List<Json>> members(Object id) async => listPayload(
    (await dio.get('${ApiPaths.conversations}/$id/members')).data,
  ).map((e) => Json.from(e as Map)).toList();
  Future<Json> addMember(Object id, Json payload) async => asJson(
    (await dio.post(
      '${ApiPaths.conversations}/$id/members',
      data: payload,
    )).data,
  );
  Future<Json> changeMemberRole(Object id, Object userId, String role) async =>
      asJson((await dio.patch(
        '${ApiPaths.conversations}/$id/members/$userId/role',
        data: {'role': role},
      )).data);
  Future<void> removeMember(Object id, Object userId) async =>
      dio.delete('${ApiPaths.conversations}/$id/members/$userId');
}
