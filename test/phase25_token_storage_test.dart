import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mychat/core/network/api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('save reads both tokens and clear removes both', () async {
    final store = TokenStore(storage: const FlutterSecureStorage());
    await store.save('access1', 'refresh1');
    expect(await store.access, 'access1');
    expect(await store.refresh, 'refresh1');
    await store.clear();
    expect(await store.access, isNull);
    expect(await store.refresh, isNull);
  });

  test('new login without refresh removes previous refresh token', () async {
    final store = TokenStore(storage: const FlutterSecureStorage());
    await store.save('access1', 'refresh1');
    await store.save('access2', null);
    expect(await store.access, 'access2');
    expect(await store.refresh, isNull);
  });
}
