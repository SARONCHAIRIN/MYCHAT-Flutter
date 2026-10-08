import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api.dart';
import 'message_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Object conversationId;
  const ChatScreen({super.key, required this.conversationId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  List<MessageJson> messages = [];
  String? cursor, error;
  bool loading = false, sending = false, hasMore = true;
  Object? replyTo;
  final Set<String> receiptSent = {};
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> load({bool older = false}) async {
    if (loading || (older && !hasMore)) return;
    setState(() {
      loading = true;
      error = null;
    });
    final oldOffset = scroll.hasClients ? scroll.offset : 0.0;
    final oldExtent = scroll.hasClients ? scroll.position.maxScrollExtent : 0.0;
    try {
      final page = await ref
          .read(messageRepositoryProvider)
          .history(widget.conversationId, before: older ? cursor : null);
      if (!mounted) return;
      setState(() {
        messages = mergeMessages(older ? messages : [], page.messages);
        cursor = page.nextCursor;
        hasMore = cursor != null && cursor!.isNotEmpty;
      });
      if (older)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients)
            scroll.jumpTo(
              (oldOffset + scroll.position.maxScrollExtent - oldExtent).clamp(
                0.0,
                scroll.position.maxScrollExtent,
              ),
            );
        });
    } catch (e) {
      if (mounted) setState(() => error = apiError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    final content = input.text.trim();
    if (content.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      final sent = await ref
          .read(messageRepositoryProvider)
          .send(widget.conversationId, content, replyTo: replyTo);
      if (!mounted) return;
      setState(() {
        messages = mergeMessages(messages, [sent]);
        input.clear();
        replyTo = null;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Send failed: ${apiError(e)}'),
            action: SnackBarAction(label: 'Retry', onPressed: send),
          ),
        );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> act(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) await load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }

  Future<void> attach(Object messageId) async {
    final selection = await FilePicker.platform.pickFiles(withData: false);
    final path = selection?.files.single.path;
    if (path == null) return;
    if (!mounted) return;
    await act(() async {
      await ref.read(messageRepositoryProvider).upload(messageId, path);
    });
  }

  void showActions(MessageJson m) {
    final id = m['id'] ?? m['messageId'];
    if (id == null) return;
    final repo = ref.read(messageRepositoryProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(sheetContext);
                setState(() => replyTo = id);
              },
            ),
            ListTile(
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(sheetContext);
                final controller = TextEditingController(
                  text: (m['content'] ?? '').toString(),
                );
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Edit message'),
                    content: TextField(controller: controller),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          act(() async {
                            await repo.edit(id, controller.text.trim());
                          });
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(sheetContext);
                act(() => repo.delete(id));
              },
            ),
            ListTile(
              title: const Text('React 👍'),
              onTap: () {
                Navigator.pop(sheetContext);
                act(() => repo.react(id, '👍'));
              },
            ),
            ListTile(
              title: const Text('Remove 👍'),
              onTap: () {
                Navigator.pop(sheetContext);
                act(() => repo.unreact(id, '👍'));
              },
            ),
            ListTile(
              title: const Text('Pin'),
              onTap: () {
                Navigator.pop(sheetContext);
                act(() => repo.pin(widget.conversationId, id));
              },
            ),
            ListTile(
              title: const Text('Unpin'),
              onTap: () {
                Navigator.pop(sheetContext);
                act(() => repo.unpin(widget.conversationId, id));
              },
            ),
            ListTile(
              title: const Text('Attach file'),
              onTap: () {
                Navigator.pop(sheetContext);
                attach(id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Messages'),
      actions: [
        IconButton(
          icon: const Icon(Icons.push_pin_outlined),
          tooltip: 'Pinned messages',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PinsScreen(conversationId: widget.conversationId),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => load()),
      ],
    ),
    body: Column(
      children: [
        if (error != null)
          ListTile(
            title: Text(error!),
            trailing: TextButton(onPressed: load, child: const Text('Retry')),
          ),
        if (loading) const LinearProgressIndicator(),
        if (hasMore && messages.isNotEmpty)
          TextButton(
            onPressed: loading ? null : () => load(older: true),
            child: const Text('Load older messages'),
          ),
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('No messages yet'))
              : ListView.builder(
                  controller: scroll,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final date = (m['createdAt'] ?? m['created_at'] ?? '')
                        .toString();
                    final previous = i > 0
                        ? (messages[i - 1]['createdAt'] ??
                                  messages[i - 1]['created_at'] ??
                                  '')
                              .toString()
                        : '';
                    final day = date.length >= 10 ? date.substring(0, 10) : '';
                    final previousDay = previous.length >= 10
                        ? previous.substring(0, 10)
                        : '';
                    return Column(
                      children: [
                        if (day.isNotEmpty && day != previousDay)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              day,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ListTile(
                          title: Text(
                            (m['content'] ?? '[Attachment]').toString(),
                          ),
                          subtitle: Text(
                            '${m['senderName'] ?? m['senderId'] ?? 'User'}  $date',
                          ),
                          onLongPress: () => showActions(m),
                        ),
                      ],
                    );
                  },
                ),
        ),
        if (replyTo != null)
          ListTile(
            title: Text('Replying to $replyTo'),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => replyTo = null),
            ),
          ),
        SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              IconButton(
                onPressed: sending ? null : send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PinsScreen extends ConsumerWidget {
  final Object conversationId;
  const PinsScreen({super.key, required this.conversationId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Pinned messages')),
    body: FutureBuilder<List<MessageJson>>(
      future: ref.read(messageRepositoryProvider).pins(conversationId),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(apiError(snap.error!)));
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snap.data!.isEmpty)
          return const Center(child: Text('No pinned messages'));
        return ListView(
          children: [
            for (final m in snap.data!)
              ListTile(
                title: Text(
                  (m['content'] ?? m['messageId'] ?? 'Pinned').toString(),
                ),
              ),
          ],
        );
      },
    ),
  );
}
