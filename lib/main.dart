import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'core/theme/stitch_theme.dart';
import 'core/preferences/app_preferences.dart';
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
    final preferences = ref.watch(appPreferencesProvider);

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
      theme: StitchTheme.light(),
      darkTheme: StitchTheme.dark(),
      themeMode: preferences.themeMode,
      locale: Locale(preferences.languageCode),
      home: auth.when(
        loading: () => const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum_rounded, size: 80, color: StitchTheme.primaryContainer),
                SizedBox(height: 20),
                Text('MYCHAT', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text('Fast. Secure. Real-time messaging.', style: TextStyle(color: StitchTheme.muted)),
                SizedBox(height: 24),
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Restoring your session...', style: TextStyle(fontSize: 12, color: StitchTheme.muted)),
              ],
            ),
          ),
        ),
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
