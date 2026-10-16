import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api.dart';

// ───────────────────────── Data layer (unchanged) ─────────────────────────

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

// ───────────────────────── Telegram-style helpers ─────────────────────────

const _tgBlue = Color(0xFF3390EC);

bool _isRead(Map<String, dynamic> n) => n['isRead'] == true || n['read'] == true;

/// (icon, gradient top, gradient bottom) per notification type.
(IconData, Color, Color) _styleFor(Map<String, dynamic> n) {
  final t = '${n['type'] ?? ''}'.toLowerCase();
  if (t.contains('reaction') || t.contains('like')) {
    return (Icons.favorite, const Color(0xFFE0A2F3), const Color(0xFFD669ED));
  }
  if (t.contains('group')) {
    return (Icons.groups, const Color(0xFFA0DE7E), const Color(0xFF54CB68));
  }
  if (t.contains('message') || t.contains('chat')) {
    return (Icons.chat_bubble, const Color(0xFF72D5FD), const Color(0xFF2A9EF1));
  }
  return (Icons.notifications, const Color(0xFFFFCD6A), const Color(0xFFFFA85C));
}

/// Telegram chat-list style time: HH:mm today, weekday this week, else "12 Mar".
String? _timeLabel(Map<String, dynamic> n) {
  final raw = n['createdAt'] ?? n['created_at'] ?? n['timestamp'];
  final d = DateTime.tryParse('${raw ?? ''}')?.toLocal();
  if (d == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  String two(int v) => v.toString().padLeft(2, '0');
  if (diff == 0) return '${two(d.hour)}:${two(d.minute)}';
  const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (diff > 0 && diff < 7) return wd[d.weekday - 1];
  return '${d.day} ${mo[d.month - 1]}';
}

// ───────────────────────── Screen ─────────────────────────

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scroll = ScrollController();
  List<Map<String, dynamic>> items = [];
  int page = 0;
  bool busy = false, hasMore = true;
  String? error;

  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300 &&
          hasMore &&
          !busy &&
          error == null) {
        load();
      }
    });
    Future.microtask(load);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> load({bool reset = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final next = await _repo.page(reset ? 0 : page);
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

  void _toast(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(apiError(e)), behavior: SnackBarBehavior.floating),
    );
  }

  /// Optimistic: mark read locally first, roll back if the request fails.
  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['id'] == null || _isRead(n)) return;
    setState(() => n['isRead'] = true);
    try {
      await _repo.markRead(n['id']);
    } catch (e) {
      if (mounted) setState(() => n['isRead'] = false);
      _toast(e);
    }
  }

  Future<void> _markAllRead() async {
    final unread = items.where((n) => !_isRead(n)).toList();
    if (unread.isEmpty) return;
    setState(() {
      for (final n in unread) {
        n['isRead'] = true;
      }
    });
    try {
      await _repo.markAllRead();
    } catch (e) {
      if (mounted) setState(() {
        for (final n in unread) {
          n['isRead'] = false;
        }
      });
      _toast(e);
    }
  }

  /// Called after the swipe animation finishes; the row is already removed.
  Future<void> _delete(Map<String, dynamic> n) async {
    setState(() => items.remove(n));
    try {
      await _repo.delete(n['id']);
    } catch (e) {
      _toast(e);
      load(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF0F0F0F) : Colors.white;
    final secondary = dark ? const Color(0xFF8D8E93) : const Color(0xFF8A8A8E);
    final divider = dark ? const Color(0xFF2C2C2E) : const Color(0xFFE3E3E8);
    final unreadCount = items.where((n) => !_isRead(n)).length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: dark ? const Color(0xFF1C1C1D) : Colors.white,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Notifications',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (unreadCount > 0)
              Text('$unreadCount unread',
                  style: TextStyle(fontSize: 12, color: secondary)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) {
              if (v == 'read') _markAllRead();
              if (v == 'refresh') load(reset: true);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'read',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.done_all),
                  title: Text('Mark all as read'),
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _tgBlue,
        onRefresh: () => load(reset: true),
        child: _body(secondary, divider),
      ),
    );
  }

  Widget _body(Color secondary, Color divider) {
    // Initial load / error / empty states fill the screen but stay pull-to-refresh friendly.
    if (items.isEmpty) {
      Widget center(Widget child) => LayoutBuilder(
        builder: (context, c) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: c.maxHeight, child: Center(child: child))],
        ),
      );
      if (busy) {
        return center(const CircularProgressIndicator(color: _tgBlue));
      }
      if (error != null) {
        return center(
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 56, color: secondary),
                const SizedBox(height: 12),
                Text(error!, textAlign: TextAlign.center),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: _tgBlue),
                  onPressed: () => load(reset: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      return center(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 64, color: secondary),
            const SizedBox(height: 12),
            const Text('No notifications',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('New activity will show up here.',
                style: TextStyle(color: secondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length + 1,
      itemBuilder: (context, i) {
        if (i == items.length) return _footer();
        final n = items[i];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NotificationRow(
              key: ValueKey('${n['id'] ?? i}'),
              n: n,
              secondary: secondary,
              onTap: () => _markRead(n),
              onDelete: n['id'] == null ? null : () => _delete(n),
            ),
            Divider(height: 0.5, thickness: 0.5, indent: 80, color: divider),
          ],
        );
      },
    );
  }

  Widget _footer() {
    if (busy) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _tgBlue),
          ),
        ),
      );
    }
    if (error != null) {
      return TextButton(
        style: TextButton.styleFrom(foregroundColor: _tgBlue),
        onPressed: load,
        child: Text('Retry: $error'),
      );
    }
    return const SizedBox(height: 24);
  }
}

// ───────────────────────── Row ─────────────────────────

class _NotificationRow extends StatelessWidget {
  final Map<String, dynamic> n;
  final Color secondary;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _NotificationRow({
    super.key,
    required this.n,
    required this.secondary,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final read = _isRead(n);
    final (icon, top, bottom) = _styleFor(n);
    final title = '${n['title'] ?? n['type'] ?? 'Notification'}';
    final body = '${n['body'] ?? n['message'] ?? ''}';
    final time = _timeLabel(n);

    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [top, bottom],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: read ? FontWeight.w500 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (time != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 13,
                              color: read ? secondary : _tgBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, color: secondary, height: 1.25),
                        ),
                      ),
                      if (!read)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: _tgBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onDelete == null) return row;

    // Swipe left to delete, like Telegram's chat list.
    return Dismissible(
      key: ValueKey('dismiss-${n['id']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete!(),
      background: Container(
        color: const Color(0xFFE5534B),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(height: 2),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      child: row,
    );
  }
}