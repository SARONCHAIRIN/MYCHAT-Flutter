import 'package:flutter_test/flutter_test.dart';
import 'package:mychat/features/messages/message_repository.dart';

void main() {
  group('mergeMessages', () {
    test('deduplicates by id and retains latest version', () {
      final result = mergeMessages(
        [
          {'id': 1, 'content': 'old', 'createdAt': '2026-01-01T00:00:00Z'},
        ],
        [
          {'id': 1, 'content': 'edited', 'createdAt': '2026-01-01T00:00:00Z'},
        ],
      );
      expect(result, hasLength(1));
      expect(result.single['content'], 'edited');
    });

    test('sorts chronologically regardless of page order', () {
      final result = mergeMessages([], [
        {'id': 2, 'createdAt': '2026-01-02T00:00:00Z'},
        {'id': 1, 'createdAt': '2026-01-01T00:00:00Z'},
      ]);
      expect(result.map((e) => e['id']).toList(), [1, 2]);
    });

    test('accepts snake_case timestamps', () {
      final result = mergeMessages([], [
        {'messageId': 3, 'created_at': '2026-01-03T00:00:00Z'},
        {'messageId': 2, 'created_at': '2026-01-02T00:00:00Z'},
      ]);
      expect(result.map((e) => e['messageId']).toList(), [2, 3]);
    });
  });
}
