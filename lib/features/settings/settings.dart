import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api.dart';

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.read(dioProvider)),
);

class SettingsRepository {
  final Dio dio;
  SettingsRepository(this.dio);
  Future<Map<String, dynamic>> get() async => Map<String, dynamic>.from(
    unwrap((await dio.get('/api/v1/settings')).data) as Map,
  );
  Future<Map<String, dynamic>> patch(Map<String, dynamic> fields) async =>
      Map<String, dynamic>.from(
        unwrap((await dio.patch('/api/v1/settings', data: fields)).data) as Map,
      );
}

final settingsProvider =
    AsyncNotifierProvider<SettingsController, Map<String, dynamic>>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() =>
      ref.read(settingsRepositoryProvider).get();
  Future<void> updateSetting(String key, dynamic value) async {
    final previous = state.valueOrNull;
    if (previous == null) return;
    state = AsyncData({...previous, key: value});
    try {
      state = AsyncData(
        await ref.read(settingsRepositoryProvider).patch({key: value}),
      );
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(apiError(e)),
              TextButton(
                onPressed: () => ref.invalidate(settingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) => ListView(
          children: [
            ListTile(
              title: const Text('Appearance'),
              subtitle: Text('Theme: ${data['theme'] ?? 'System'}'),
            ),
            for (final field in [
              'messageNotifications',
              'groupNotifications',
              'reactionNotifications',
              'readReceipts',
            ])
              if (data[field] is bool)
                SwitchListTile(
                  title: Text(field),
                  value: data[field] as bool,
                  onChanged: (value) async {
                    try {
                      await ref
                          .read(settingsProvider.notifier)
                          .updateSetting(field, value);
                    } catch (e) {
                      if (context.mounted)
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(apiError(e))));
                    }
                  },
                ),
            for (final field in [
              'lastSeenPrivacy',
              'profilePhotoPrivacy',
              'groupAddPrivacy',
            ])
              ListTile(
                title: Text(field),
                subtitle: Text('${data[field] ?? 'Not set'}'),
              ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Privacy values are read-only until backend enum options are verified.',
              ),
            ),
            for (final theme in ['LIGHT', 'DARK'])
              RadioListTile<String>(
                title: Text(theme),
                value: theme,
                groupValue: data['theme']?.toString(),
                onChanged: (value) async {
                  if (value == null) return;
                  try {
                    await ref
                        .read(settingsProvider.notifier)
                        .updateSetting('theme', value);
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(apiError(e))));
                  }
                },
              ),
            ListTile(
              title: const Text('Blocked users'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final blockedUsersProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) async => listPayload(
    (await ref.read(dioProvider).get('/api/v1/users/me/blocked')).data,
  ),
);

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(blockedUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(blockedUsersProvider),
            child: Text('Retry: ${apiError(e)}'),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No blocked users'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final user = Map<String, dynamic>.from(items[i] as Map);
                  final id = user['id'];
                  return ListTile(
                    title: Text('${user['username'] ?? user['name'] ?? id}'),
                    trailing: TextButton(
                      onPressed: id == null
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Unblock user?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Unblock'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok != true) return;
                              try {
                                await ref
                                    .read(dioProvider)
                                    .delete('/api/v1/users/$id/block');
                                ref.invalidate(blockedUsersProvider);
                              } catch (e) {
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(apiError(e))),
                                  );
                              }
                            },
                      child: const Text('Unblock'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
