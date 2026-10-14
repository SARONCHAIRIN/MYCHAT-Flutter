import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'features/auth/auth.dart';
import 'features/ui/screens.dart';
import 'core/notifications/firebase_messaging_service.dart';
import 'core/notifications/notification_router.dart';
import 'core/notifications/notification_initializer.dart';

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
      _syncNotificationAuth(ref, next);
    });
    // Covers sessions already restored before the listener was registered.
    // The initializer itself is idempotent, so repeated builds are safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) _syncNotificationAuth(ref, auth);
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

  void _syncNotificationAuth(
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>?> auth,
  ) {
    if (!auth.hasValue) return;
    final signedIn = auth.value != null;
    NotificationRouter.setAuthenticated(signedIn);
    if (signedIn) {
      // Also initialize FCM when a persisted session is restored.
      ref.read(notificationInitializerProvider).initialize().catchError((
        Object error,
      ) {
        debugPrint('FCM initialization failed: $error');
      });
    }
  }
}
