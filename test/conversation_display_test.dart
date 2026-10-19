import 'package:flutter_test/flutter_test.dart';
import 'package:mychat/features/conversations/conversation_display.dart';

void main() {
  final direct = <String, dynamic>{
    'id': 11,
    'type': 'DIRECT',
    'name': null,
    'avatarUrl': null,
    'members': [
      {'userId': 8, 'name': 'rin1', 'avatarUrl': 'https://x.test/rin1.jpg'},
      {'userId': 7, 'name': 'rin5', 'avatarUrl': 'https://x.test/rin5.jpg'},
    ],
  };

  test('direct chat shows the other participant', () {
    final d = resolveConversationDisplay(direct, currentUserId: 7);
    expect(d.name, 'rin1');
    expect(d.avatarUrl, 'https://x.test/rin1.jpg');
    expect(d.isGroup, isFalse);
  });

  test('direct chat never uses the current user avatar', () {
    final d = resolveConversationDisplay(direct, currentUserId: 8);
    expect(d.name, 'rin5');
    expect(d.avatarUrl, 'https://x.test/rin5.jpg');
  });

  test('nested member with top-level avatar uses peer fields', () {
    final d = resolveConversationDisplay({
      'type': 'DIRECT',
      'members': [
        {'userId': 7, 'name': 'me'},
        {'userId': 8, 'name': 'rin1', 'avatarUrl': 'https://x.test/a.png',
         'user': {'id': 8, 'username': 'rin1'}},
      ],
    }, currentUserId: 7);
    expect(d.name, 'rin1');
    expect(d.avatarUrl, 'https://x.test/a.png');
  });

  test('missing avatar and name fall back safely', () {
    final d = resolveConversationDisplay({
      'type': 'DIRECT',
      'members': [
        {'userId': 7, 'name': 'me', 'avatarUrl': 'https://x.test/me.jpg'},
        {'userId': 9, 'username': 'bob'},
      ],
    }, currentUserId: 7);
    expect(d.name, 'bob');
    expect(d.avatarUrl, isNull);
  });

  test('missing members use a neutral title', () {
    expect(resolveConversationDisplay({'type': 'DIRECT'}, currentUserId: 1).name,
        'Conversation');
  });

  test('group uses group name and avatar', () {
    final d = resolveConversationDisplay({
      'type': 'GROUP', 'name': 'Team', 'avatarUrl': 'https://x.test/g.png',
      'members': [{'userId': 1, 'name': 'a'}],
    }, currentUserId: 1);
    expect(d.name, 'Team');
    expect(d.isGroup, isTrue);
    expect(d.avatarUrl, 'https://x.test/g.png');
  });

  test('initials', () {
    expect(initialsFor('rin1'), 'R');
    expect(initialsFor('Jane Doe'), 'JD');
    expect(initialsFor('  '), '?');
  });
}
