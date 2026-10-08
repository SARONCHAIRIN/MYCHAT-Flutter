import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/auth.dart';
import 'features/ui/screens.dart';

void main() => runApp(const ProviderScope(child: MyChatApp()));

class MyChatApp extends ConsumerWidget {
  const MyChatApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return MaterialApp(
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
