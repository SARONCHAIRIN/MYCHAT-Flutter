import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mychat/features/ui/screens.dart';

void main() {
  Widget app() => const ProviderScope(child: MaterialApp(home: AuthScreen()));

  testWidgets('login validates empty username and short password', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
  });

  testWidgets('register validates name, username, email and password', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('Create account'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pump();
    expect(find.text('Required'), findsNWidgets(2));
    expect(find.text('Invalid email'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
  });

  testWidgets('password visibility toggle changes obscureText', (tester) async {
    await tester.pumpWidget(app());
    TextField password() => tester.widget<TextField>(
      find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(TextField),
      ),
    );
    expect(password().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(password().obscureText, isFalse);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(password().obscureText, isTrue);
  });

  testWidgets('can switch between login and registration without network', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('MYCHAT Login'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Register'), findsOneWidget);
    await tester.tap(find.text('Already have an account? Login'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
  });
}
