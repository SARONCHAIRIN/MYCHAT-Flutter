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
  final name = TextEditingController(), username = TextEditingController(),
      email = TextEditingController(), password = TextEditingController();
  bool register = false, obscure = true, busy = false;
  @override
  void dispose() { name.dispose(); username.dispose(); email.dispose(); password.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(register ? 'Create account' : 'MYCHAT Login')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
      child: Form(key: form, child: ListView(padding: const EdgeInsets.all(24), children: [
        if (register) TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        TextFormField(controller: username, decoration: const InputDecoration(labelText: 'Username'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        if (register) TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: (v) => v != null && v.contains('@') ? null : 'Invalid email'),
        TextFormField(controller: password, obscureText: obscure,
          decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(
            onPressed: () => setState(() => obscure = !obscure),
            icon: Icon(obscure ? Icons.visibility : Icons.visibility_off))),
          validator: (v) => v == null || v.length < 6 ? 'At least 6 characters' : null),
        const SizedBox(height: 20),
        FilledButton(onPressed: busy ? null : () async {
          if (!form.currentState!.validate()) return;
          setState(() => busy = true);
          try {
            final auth = ref.read(authProvider.notifier);
            if (register) { await auth.register(name.text.trim(), username.text.trim(), email.text.trim(), password.text); }
            else { await auth.login(username.text.trim(), password.text); }
            final result = ref.read(authProvider);
            if (result.hasError) throw result.error!;
          } catch (e) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
          } finally { if (mounted) setState(() => busy = false); }
        }, child: Text(busy ? 'Please wait…' : register ? 'Register' : 'Login')),
        TextButton(onPressed: () => setState(() => register = !register),
          child: Text(register ? 'Already have an account? Login' : 'Create account')),
      ])))),
  );
}
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('MYCHAT'), actions: [
      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
        icon: const Icon(Icons.person)),
      IconButton(onPressed: () => ref.read(authProvider.notifier).logout(), icon: const Icon(Icons.logout)),
    ]),
    body: const DefaultTabController(length: 2, child: Column(children: [
      TabBar(tabs: [Tab(text: 'Chats'), Tab(text: 'People')]),
      Expanded(child: TabBarView(children: [ConversationsScreen(), PeopleScreen()])),
    ])),
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
  void initState() { super.initState(); future = ref.read(userRepositoryProvider).me(); }
  @override
  void dispose() { name.dispose(); bio.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('My profile')),
    body: FutureBuilder<Json>(future: future, builder: (context, snap) {
      if (!snap.hasData) return Center(child: snap.hasError
        ? Text('Failed: ${apiError(snap.error!)}') : const CircularProgressIndicator());
      final user = snap.data!;
      if (name.text.isEmpty) name.text = (user['name'] ?? '').toString();
      if (bio.text.isEmpty) bio.text = (user['bio'] ?? '').toString();
      return ListView(padding: const EdgeInsets.all(20), children: [
        Text('Username: ${user['username'] ?? ''}'),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: bio, decoration: const InputDecoration(labelText: 'Bio')),
        FilledButton(onPressed: () async {
          try {
            await ref.read(userRepositoryProvider).update({'name': name.text, 'bio': bio.text});
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
          } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e)))); }
        }, child: const Text('Save')),
      ]);
    }));
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
  void initState() { super.initState(); Future.microtask(load); }
  @override
  void dispose() { debounce?.cancel(); search.dispose(); super.dispose(); }
  Future<void> load({bool next = false}) async {
    final id = ++generation;
    if (!next) page = 0;
    setState(() { loading = true; error = null; });
    try {
      final repo = ref.read(userRepositoryProvider);
      final result = search.text.trim().isEmpty
        ? await repo.list(page: page) : await repo.search(search.text.trim(), page: page);
      if (!mounted || id != generation) { return; }
      setState(() { users = next ? [...users, ...result] : result; if (next) page++; });
    } catch (e) { if (mounted && id == generation) { setState(() => error = apiError(e)); } }
    finally { if (mounted && id == generation) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.all(12), child: TextField(controller: search,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search people'),
      onChanged: (_) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 400), load); })),
    if (error != null) TextButton(onPressed: load, child: Text('$error — Retry')),
    Expanded(child: ListView(children: [
      for (final u in users) ListTile(title: Text((u['name'] ?? u['username'] ?? 'User').toString()),
        subtitle: Text((u['username'] ?? '').toString()),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: u['id'])))),
      if (loading) const Center(child: CircularProgressIndicator()),
      if (!loading && users.isEmpty && error == null) const ListTile(title: Text('No users found')),
      if (!loading && users.isNotEmpty) TextButton(onPressed: () { page++; load(next: true); }, child: const Text('Load more')),
    ])),
  ]);
}
class PublicProfileScreen extends ConsumerWidget {
  final Object? userId;
  const PublicProfileScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(appBar: AppBar(title: const Text('Profile')),
    body: FutureBuilder<Json>(future: ref.read(userRepositoryProvider).byId(userId ?? ''),
      builder: (context, snap) => snap.hasData
        ? ListTile(title: Text('${snap.data!['name'] ?? ''}'), subtitle: Text('${snap.data!['username'] ?? ''}'))
        : Center(child: Text(snap.hasError ? apiError(snap.error!) : 'Loading…'))));
}
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});
  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}
class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  late Future<List<Json>> future;
  @override
  void initState() { super.initState(); refresh(); }
  void refresh() { future = ref.read(conversationRepositoryProvider).list(); }
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: () async { setState(refresh); await future; },
    child: FutureBuilder<List<Json>>(future: future, builder: (context, snap) {
      if (!snap.hasData) return ListView(children: [ListTile(title: Text(snap.hasError
        ? apiError(snap.error!) : 'Loading conversations…'), onTap: () => setState(refresh))]);
      if (snap.data!.isEmpty) return ListView(children: const [ListTile(title: Text('No conversations yet'))]);
      return ListView(children: [
        for (final c in snap.data!) ListTile(
          title: Text((c['name'] ?? c['title'] ?? 'Conversation').toString()),
          subtitle: Text('ID: ${c['id']}'),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ConversationDetailsScreen(id: c['id'])))),
      ]);
    }));
}
class ConversationDetailsScreen extends ConsumerWidget {
  final Object? id;
  const ConversationDetailsScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(appBar: AppBar(title: const Text('Conversation')),
    body: FutureBuilder<Json>(future: ref.read(conversationRepositoryProvider).byId(id ?? ''),
      builder: (context, snap) {
        if (!snap.hasData) return Center(child: Text(snap.hasError ? apiError(snap.error!) : 'Loading…'));
        return Column(children: [
          ListTile(title: Text((snap.data!['name'] ?? 'Conversation').toString())),
          Expanded(child: FutureBuilder<List<Json>>(
            future: ref.read(conversationRepositoryProvider).members(id ?? ''),
            builder: (context, members) => members.hasData
              ? ListView(children: [
                  for (final m in members.data!) ListTile(title: Text((m['name'] ?? m['username'] ?? m['userId'] ?? 'Member').toString()))
                ]) : Center(child: Text(members.hasError ? apiError(members.error!) : 'Loading members…')))),
        ]);
      }));
}
