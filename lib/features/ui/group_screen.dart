import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api.dart';
import '../../core/widgets/user_avatar.dart';
import '../data/repositories.dart';
import '../messages/chat_screen.dart';
import 'screens.dart';

class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});
  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final search = TextEditingController();
  final groupName = TextEditingController();
  Timer? debounce;
  bool loading = true, creating = false;
  String? error;
  List<Json> users = [];
  final Map<String, Json> selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    groupName.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repo = ref.read(userRepositoryProvider);
      final q = search.text.trim();
      final result = q.isEmpty ? await repo.list(page: 0) : await repo.search(q, page: 0);
      if (mounted) setState(() => users = result);
    } catch (e) {
      if (mounted) setState(() => error = apiError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    final name = groupName.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a group name')));
      return;
    }
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one member')));
      return;
    }
    setState(() => creating = true);
    try {
      final conversation = await ref.read(conversationRepositoryProvider).create({
        'type': 'GROUP',
        'name': name,
        'memberIds': selected.keys.toList(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversation['id'] ?? '')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => creating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    }
  }

  Widget _insetDivider() => const Padding(
        padding: EdgeInsets.only(left: 78),
        child: Divider(height: 1, thickness: .6, color: Tg.divider),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('New Group', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            Text('${selected.length} selected', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ]),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Tg.accent,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: creating ? null : _create,
          child: creating
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.arrow_forward_rounded),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(color: Tg.accent, shape: BoxShape.circle),
                child: const Icon(Icons.group_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: groupName,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Group name', border: UnderlineInputBorder(), filled: false),
                ),
              ),
            ]),
          ),
          if (selected.isNotEmpty)
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final e in selected.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 6, top: 6, bottom: 6),
                      child: InputChip(
                        label: Text((e.value['name'] ?? e.value['username'] ?? 'User').toString()),
                        backgroundColor: const Color(0xFFE8F2FD),
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        onDeleted: () => setState(() => selected.remove(e.key)),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: TextField(
              controller: search,
              onChanged: (_) {
                debounce?.cancel();
                debounce = Timer(const Duration(milliseconds: 400), _load);
              },
              decoration: InputDecoration(
                hintText: 'Add people',
                prefixIcon: const Icon(Icons.search, color: Tg.secondary),
                filled: true,
                fillColor: Tg.surface,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            ),
          ),
          if (error != null) TextButton(onPressed: _load, child: Text('$error — Retry')),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? const Center(child: Text('No users found', style: TextStyle(color: Tg.secondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final u = users[i];
                          final id = '${u['id']}';
                          final on = selected.containsKey(id);
                          return Column(children: [
                            InkWell(
                              onTap: () => setState(() => on ? selected.remove(id) : selected[id] = u),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(children: [
                                  Stack(children: [
                                    UserAvatar(radius: 26, label: (u['name'] ?? u['username'] ?? 'U').toString(), url: (u['avatarUrl'] ?? u['avatar_url'])?.toString()),
                                    if (on)
                                      const Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: CircleAvatar(radius: 10, backgroundColor: Colors.white, child: CircleAvatar(radius: 8, backgroundColor: Tg.accent, child: Icon(Icons.check, size: 12, color: Colors.white))),
                                      ),
                                  ]),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text((u['name'] ?? u['username'] ?? 'User').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text('@${u['username'] ?? ''}', style: const TextStyle(fontSize: 14, color: Tg.secondary)),
                                    ]),
                                  ),
                                ]),
                              ),
                            ),
                            _insetDivider(),
                          ]);
                        },
                      ),
          ),
        ]),
      );
}