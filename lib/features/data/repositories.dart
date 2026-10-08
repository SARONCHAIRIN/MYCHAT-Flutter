import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api.dart';

typedef Json = Map<String, dynamic>;
Json asJson(dynamic value) => Json.from(unwrap(value) as Map);
final userRepositoryProvider = Provider((ref) => UserRepository(ref.read(dioProvider)));
final conversationRepositoryProvider = Provider((ref) => ConversationRepository(ref.read(dioProvider)));
class UserRepository {
  final Dio dio;
  UserRepository(this.dio);
  Future<Json> me() async => asJson((await dio.get('${ApiPaths.users}/me')).data);
  Future<Json> byId(Object id) async => asJson((await dio.get('${ApiPaths.users}/$id')).data);
  Future<Json> update(Json patch) async => asJson((await dio.patch('${ApiPaths.users}/me', data: patch)).data);
  Future<Json> avatar(String filePath) async => asJson((await dio.patch('${ApiPaths.users}/me/avatar',
    data: FormData.fromMap({'file': await MultipartFile.fromFile(filePath)}))).data);
  Future<List<Json>> list({int page = 0, int size = 20}) async => listPayload(
    (await dio.get(ApiPaths.users, queryParameters: {'page': page, 'size': size})).data
  ).map((e) => Json.from(e as Map)).toList();
  Future<List<Json>> search(String q, {int page = 0, int size = 20}) async => listPayload(
    (await dio.get('${ApiPaths.users}/search', queryParameters: {'q': q, 'page': page, 'size': size})).data
  ).map((e) => Json.from(e as Map)).toList();
}
class ConversationRepository {
  final Dio dio;
  ConversationRepository(this.dio);
  Future<List<Json>> list() async => listPayload((await dio.get(ApiPaths.conversations)).data)
    .map((e) => Json.from(e as Map)).toList();
  Future<Json> byId(Object id) async => asJson((await dio.get('${ApiPaths.conversations}/$id')).data);
  Future<Json> create(Json payload) async => asJson((await dio.post(ApiPaths.conversations, data: payload)).data);
  Future<Json> update(Object id, Json payload) async => asJson(
    (await dio.patch('${ApiPaths.conversations}/$id', data: payload)).data);
  Future<List<Json>> members(Object id) async => listPayload(
    (await dio.get('${ApiPaths.conversations}/$id/members')).data)
    .map((e) => Json.from(e as Map)).toList();
  Future<Json> addMember(Object id, Json payload) async => asJson(
    (await dio.post('${ApiPaths.conversations}/$id/members', data: payload)).data);
  Future<void> removeMember(Object id, Object userId) async =>
    dio.delete('${ApiPaths.conversations}/$id/members/$userId');
}
