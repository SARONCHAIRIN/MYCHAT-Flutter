import 'package:flutter_test/flutter_test.dart';
import 'package:mychat/features/reactions/reaction_summary.dart';

void main() {
  final rows = <Map<String, dynamic>>[
    {'userId': 1, 'emoji': '👍'},
    {'userId': 2, 'emoji': '👍'},
    {'userId': 1, 'emoji': '❤️'},
  ];

  test('aggregates counts and marks own reactions', () {
    final s = summarizeReactions(rows, currentUserId: 1);
    final like = s.firstWhere((r) => r.emoji == '👍');
    expect(like.count, 2);
    expect(like.mine, isTrue);
    expect(s.firstWhere((r) => r.emoji == '❤️').count, 1);
  });

  test('duplicate rows are not double counted', () {
    final s = summarizeReactions([...rows, {'userId': 1, 'emoji': '👍'}], currentUserId: 2);
    expect(s.firstWhere((r) => r.emoji == '👍').count, 2);
  });

  test('toggle removes own reaction and adds otherwise', () {
    final s = summarizeReactions(rows, currentUserId: 1);
    expect(toggleAction(s, '👍'), ReactionAction.remove);
    expect(toggleAction(s, '🔥'), ReactionAction.add);
    expect(toggleAction(summarizeReactions(rows, currentUserId: 3), '👍'), ReactionAction.add);
  });
}
