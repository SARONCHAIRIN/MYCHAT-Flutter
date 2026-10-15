import '../../core/theme/stitch_theme.dart';
import '../settings/settings.dart';
import '../notifications/notifications.dart';
import '../messages/chat_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth.dart';
import '../data/repositories.dart';
import '../../core/network/api.dart';


class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      username = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool register = false, obscure = true, busy = false;
  @override
  void dispose() {
    name.dispose();
    username.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                if (register) Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => setState(() => register = false), icon: const Icon(Icons.arrow_back))),
                const SizedBox(height: 32),
                Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xffe5eeff), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.forum_rounded, color: StitchTheme.primaryContainer, size: 42))),
                const SizedBox(height: 26),
                Text(register ? 'Create your account' : 'Welcome back', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: StitchTheme.ink)),
                const SizedBox(height: 8),
                Text(register ? 'Join MYCHAT and start connecting with your teams and close circles.' : 'Sign in to continue your conversations.', textAlign: TextAlign.center, style: const TextStyle(color: StitchTheme.muted)),
                const SizedBox(height: 32),
                if (register) ...[
                  const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  TextFormField(controller: name, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), hintText: 'Your full name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                  const SizedBox(height: 17),
                ],
                const Text('Username', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                TextFormField(controller: username, decoration: const InputDecoration(prefixIcon: Icon(Icons.alternate_email), hintText: 'Your username'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 17),
                if (register) ...[
                  const Text('Email', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline), hintText: 'you@example.com'), validator: (v) => v != null && v.contains('@') ? null : 'Invalid email'),
                  const SizedBox(height: 17),
                ],
                const Text('Password', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                TextFormField(controller: password, obscureText: obscure, decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline), hintText: 'Enter your password', suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => v == null || v.length < 6 ? 'At least 6 characters' : null),
                const SizedBox(height: 25),
                FilledButton(
                  onPressed: busy ? null : () async {
                    if (!form.currentState!.validate()) return;
                    setState(() => busy = true);
                    try {
                      final auth = ref.read(authProvider.notifier);
                      if (register) {
                        await auth.register(name.text.trim(), username.text.trim(), email.text.trim(), password.text);
                      } else {
                        await auth.login(username.text.trim(), password.text);
                      }
                      final result = ref.read(authProvider);
                      if (result.hasError) throw result.error!;
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
                  child: Text(busy ? 'Please wait…' : register ? 'Create Account' : 'Sign In', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(register ? 'Already have an account?' : "Don't have an account?"),
                  TextButton(onPressed: () => setState(() => register = !register), child: Text(register ? 'Sign in' : 'Create account')),
                ]),
                const SizedBox(height: 22),
                const Center(child: Text('♢  End-to-end encrypted protocol', style: TextStyle(color: StitchTheme.muted, fontSize: 12))),
              ],
            ),
          ),
        ),
      ),
    ),
  );

}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(children: [
        const Icon(Icons.forum_rounded, color: StitchTheme.primaryContainer),
        const SizedBox(width: 9),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MYCHAT', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          Text(['Chats', 'People', 'Alerts', 'Profile'][selected], style: const TextStyle(fontSize: 11, color: StitchTheme.muted)),
        ]),
      ]),
      actions: [
        IconButton(tooltip: 'Search people', icon: const Icon(Icons.search), onPressed: () => setState(() => selected = 1)),
        IconButton(tooltip: 'Settings', icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      ],
    ),
    body: IndexedStack(index: selected, children: const [ConversationsScreen(), PeopleScreen(), NotificationsScreen(), ProfileScreen()]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) => setState(() => selected = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Chats'),
        NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'People'),
        NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: 'Alerts'),
        NavigationDestination(icon: Icon(Icons.account_circle_outlined), selectedIcon: Icon(Icons.account_circle), label: 'Profile'),
      ],
    ),
  );

}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final name = TextEditingController(), bio = TextEditingController();
  late Future<Json> future;
  @override
  void initState() {
    super.initState();
    future = ref.read(userRepositoryProvider).me();
  }

  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My profile')),
    body: FutureBuilder<Json>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData)
          return Center(
            child: snap.hasError
                ? Text('Failed: ${apiError(snap.error!)}')
                : const CircularProgressIndicator(),
          );
        final user = snap.data!;
        if (name.text.isEmpty) name.text = (user['name'] ?? '').toString();
        if (bio.text.isEmpty) bio.text = (user['bio'] ?? '').toString();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Username: ${user['username'] ?? ''}'),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: bio,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(userRepositoryProvider).update({
                    'name': name.text,
                    'bio': bio.text,
                  });
                  if (context.mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Saved')));
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(apiError(e))));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});
  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  final search = TextEditingController();
  Timer? debounce;
  int generation = 0, page = 0;
  bool loading = false;
  String? error;
  List<Json> users = [];
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> load({bool next = false}) async {
    final id = ++generation;
    if (!next) page = 0;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repo = ref.read(userRepositoryProvider);
      final result = search.text.trim().isEmpty
          ? await repo.list(page: page)
          : await repo.search(search.text.trim(), page: page);
      if (!mounted || id != generation) {
        return;
      }
      setState(() {
        users = next ? [...users, ...result] : result;
        if (next) page++;
      });
    } catch (e) {
      if (mounted && id == generation) {
        setState(() => error = apiError(e));
      }
    } finally {
      if (mounted && id == generation) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Padding(padding: EdgeInsets.fromLTRB(18, 20, 18, 6), child: Align(alignment: Alignment.centerLeft, child: Text('People', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: StitchTheme.ink)))),
      const Padding(padding: EdgeInsets.fromLTRB(18, 0, 18, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Discover colleagues & direct contacts', style: TextStyle(color: StitchTheme.muted)))),
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search by name or @username...',
          ),
          onChanged: (_) {
            debounce?.cancel();
            debounce = Timer(const Duration(milliseconds: 400), load);
          },
        ),
      ),
      if (error != null)
        TextButton(onPressed: load, child: Text('$error — Retry')),
      Expanded(
        child: ListView(
          children: [
            for (final u in users)
              Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), color: Colors.white, elevation: 0, child: ListTile(
                leading: CircleAvatar(backgroundColor: StitchTheme.primary.withValues(alpha: 0.1), child: Text(((u['name'] ?? u['username'] ?? 'U').toString().isNotEmpty ? (u['name'] ?? u['username'] ?? 'U').toString()[0] : 'U').toUpperCase(), style: const TextStyle(color: StitchTheme.primary, fontWeight: FontWeight.bold))),
                title: Text((u['name'] ?? u['username'] ?? 'User').toString()),
                subtitle: Text('@${u['username'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Chip(label: Text('View', style: TextStyle(fontSize: 12))),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(userId: u['id']),
                  ),
                ),
              )),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (!loading && users.isEmpty && error == null)
              const ListTile(title: Text('No users found')),
            if (!loading && users.isNotEmpty)
              TextButton(
                onPressed: () {
                  page++;
                  load(next: true);
                },
                child: const Text('Load more'),
              ),
          ],
        ),
      ),
    ],
  );
}

class PublicProfileScreen extends ConsumerWidget {
  final Object? userId;
  const PublicProfileScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: FutureBuilder<Json>(
      future: ref.read(userRepositoryProvider).byId(userId ?? ''),
      builder: (context, snap) => snap.hasData
          ? ListTile(
              title: Text('${snap.data!['name'] ?? ''}'),
              subtitle: Text('${snap.data!['username'] ?? ''}'),
            )
          : Center(
              child: Text(snap.hasError ? apiError(snap.error!) : 'Loading…'),
            ),
    ),
  );
}

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});
  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  late Future<List<Json>> future;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    future = ref.read(conversationRepositoryProvider).list();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async {
      setState(refresh);
      await future;
    },
    child: FutureBuilder<List<Json>>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData)
          return ListView(
            children: [
              ListTile(
                title: Text(
                  snap.hasError
                      ? apiError(snap.error!)
                      : 'Loading conversations…',
                ),
                onTap: () => setState(refresh),
              ),
            ],
          );
        if (snap.data!.isEmpty)
          return ListView(
            children: const [ListTile(title: Text('No conversations yet'))],
          );
        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(18, 22, 18, 6), child: Text('Chats', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: StitchTheme.ink))),
            const Padding(padding: EdgeInsets.fromLTRB(18, 0, 18, 15), child: Text('Your conversations', style: TextStyle(color: StitchTheme.muted))),
            for (final c in snap.data!)
              Card(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), color: Colors.white, elevation: 0, child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xffe0e7ff), child: Icon(Icons.forum_outlined, color: StitchTheme.primary)),
                trailing: const Icon(Icons.chevron_right_rounded),
                title: Text(
                  (c['name'] ?? c['title'] ?? 'Conversation').toString(),
                ),
                subtitle: Text((c['lastMessage'] ?? c['last_message'] ?? c['description'] ?? 'Tap to open conversation').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(conversationId: c['id'] ?? ''),
                  ),
                ),
              )),
          ],
        );
      },
    ),
  );
}

class ConversationDetailsScreen extends ConsumerWidget {
  final Object? id;
  const ConversationDetailsScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Conversation')),
    body: FutureBuilder<Json>(
      future: ref.read(conversationRepositoryProvider).byId(id ?? ''),
      builder: (context, snap) {
        if (!snap.hasData)
          return Center(
            child: Text(snap.hasError ? apiError(snap.error!) : 'Loading…'),
          );
        return Column(
          children: [
            ListTile(
              title: Text((snap.data!['name'] ?? 'Conversation').toString()),
            ),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(conversationId: id ?? ''),
                ),
              ),
              child: const Text('Open messages'),
            ),
            Expanded(
              child: FutureBuilder<List<Json>>(
                future: ref
                    .read(conversationRepositoryProvider)
                    .members(id ?? ''),
                builder: (context, members) => members.hasData
                    ? ListView(
                        children: [
                          for (final m in members.data!)
                            ListTile(
                              title: Text(
                                (m['name'] ??
                                        m['username'] ??
                                        m['userId'] ??
                                        'Member')
                                    .toString(),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: Text(
                          members.hasError
                              ? apiError(members.error!)
                              : 'Loading members…',
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
