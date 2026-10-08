import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'features/auth/auth.dart';
import 'features/ui/screens.dart';
import 'core/notifications/firebase_messaging_service.dart';
import 'core/notifications/notification_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: MyChatApp()));
}

class MyChatApp extends ConsumerWidget {
  const MyChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationRouter.openPendingMessage();
          });
        }
      });
    });

    return MaterialApp(
      navigatorKey: NotificationRouter.navigatorKey,
      title: 'MYCHAT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xff172b44),
        useMaterial3: true,
      ),
      home: auth.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => const AuthScreen(),
        data: (user) => user == null ? const AuthScreen() : const HomeScreen(),
      ),
    );
  }
}
