import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mychat/features/ui/screens.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('offline auth UI validation on a device', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: AuthScreen())));
    expect(find.text('MYCHAT Login'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Register'), findsOneWidget);
  });
}
