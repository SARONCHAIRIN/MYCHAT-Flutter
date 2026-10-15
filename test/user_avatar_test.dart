import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mychat/core/widgets/user_avatar.dart';

void main() {
  test('share links and invalid values are not treated as images', () {
    expect(validAvatarUrl('https://share.google/RmBC7WOgRXF6ljdbv'), isNull);
    expect(validAvatarUrl(''), isNull);
    expect(validAvatarUrl(null), isNull);
    expect(validAvatarUrl('ftp://x.test/a.png'), isNull);
    expect(validAvatarUrl('https://x.test/a.png'), 'https://x.test/a.png');
  });

  testWidgets('shows initials when there is no usable URL', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: UserAvatar(label: 'rin1', url: 'https://share.google/x')));
    expect(find.text('R'), findsOneWidget);
  });
}
