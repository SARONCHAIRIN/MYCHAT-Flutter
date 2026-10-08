import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api.dart';

final notificationsRepositoryProvider = Provider(
  (ref) => NotificationsRepository(ref.read(dioProvider)),
);

class NotificationsRepository {
  final Dio dio;
  NotificationsRepository(this.dio);
  Future<List<Map<String, dynamic>>> page(int page) async => listPayload(
    (await dio.get(
      '/api/v1/notifications',
      queryParameters: {'page': page, 'size': 20},
    )).data,
  ).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  Future<void> markRead(Object id) async {
    await dio.post('/api/v1/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await dio.post('/api/v1/notifications/read-all');
  }

  Future<void> delete(Object id) async {
    await dio.delete('/api/v1/notifications/$id');
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Map<String, dynamic>> items = [];
  int page = 0;
  bool busy = false, hasMore = true;
  String? error;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load({bool reset = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final next = await ref
          .read(notificationsRepositoryProvider)
          .page(reset ? 0 : page);
      if (!mounted) return;
      setState(() {
        if (reset) {
          items = [];
          page = 0;
        }
        final ids = items.map((e) => '${e['id']}').toSet();
        items.addAll(next.where((e) => ids.add('${e['id']}')));
        page++;
        hasMore = next.length == 20;
      });
    } catch (e) {
      if (mounted) setState(() => error = apiError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> action(Future<void> Function() task) async {
    try {
      await task();
      await load(reset: true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        IconButton(
          tooltip: 'Mark all read',
          icon: const Icon(Icons.done_all),
          onPressed: () => action(
            () => ref.read(notificationsRepositoryProvider).markAllRead(),
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => load(reset: true),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () => load(reset: true),
      child: ListView(
        children: [
          if (error != null)
            ListTile(
              title: Text(error!),
              trailing: TextButton(
                onPressed: () => load(reset: true),
                child: const Text('Retry'),
              ),
            ),
          if (items.isEmpty && !busy)
            const ListTile(title: Text('No notifications')),
          for (final n in items)
            ListTile(
              leading: Icon(
                n['isRead'] == true || n['read'] == true
                    ? Icons.notifications_none
                    : Icons.notifications_active,
              ),
              title: Text('${n['title'] ?? n['type'] ?? 'Notification'}'),
              subtitle: Text('${n['body'] ?? n['message'] ?? ''}'),
              onTap: n['id'] == null
                  ? null
                  : () => action(
                      () => ref
                          .read(notificationsRepositoryProvider)
                          .markRead(n['id']),
                    ),
              trailing: n['id'] == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => action(
                        () => ref
                            .read(notificationsRepositoryProvider)
                            .delete(n['id']),
                      ),
                    ),
            ),
          if (busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          if (hasMore && !busy)
            TextButton(onPressed: load, child: const Text('Load more')),
        ],
      ),
    ),
  );
}
