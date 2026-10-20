import '../../core/preferences/app_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api.dart';

// ───────────────────────── Data layer (unchanged) ─────────────────────────

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

// ───────────────────────── Telegram-style UI kit ─────────────────────────

const _tgBlue = Color(0xFF3390EC);

class _TgColors {
  final Color background;
  final Color surface;
  final Color divider;
  final Color secondaryText;
  const _TgColors._(
    this.background,
    this.surface,
    this.divider,
    this.secondaryText,
  );

  static _TgColors of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const _TgColors._(
            Color(0xFF0F0F0F),
            Color(0xFF1C1C1D),
            Color(0xFF2C2C2E),
            Color(0xFF8D8E93),
          )
        : const _TgColors._(
            Color(0xFFEFEFF4),
            Colors.white,
            Color(0xFFE3E3E8),
            Color(0xFF8A8A8E),
          );
  }
}

/// Grouped, rounded card with an optional blue header and grey footer.
class _Section extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  const _Section({this.header, this.footer, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = _TgColors.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Divider(height: 0.5, thickness: 0.5, indent: 60, color: c.divider));
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 16, 7),
              child: Text(
                header!,
                style: const TextStyle(
                  color: _tgBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: rows),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 7, 24, 0),
              child: Text(
                footer!,
                style: TextStyle(color: c.secondaryText, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

/// Colored rounded-square icon, as used in Telegram's settings list.
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge(this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Icon(icon, color: Colors.white, size: 19),
  );
}

class _TgTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? value;
  final bool chevron;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _TgTile({
    required this.icon,
    required this.color,
    required this.title,
    this.value,
    this.chevron = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = _TgColors.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _IconBadge(icon, color),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16.5))),
              if (value != null)
                Flexible(
                  child: Text(
                    value!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.secondaryText, fontSize: 16),
                  ),
                ),
              if (trailing != null) trailing!,
              if (chevron) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 22, color: c.secondaryText),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Labels ─────────────────────────

const _toggleFields = <String, (String, IconData, Color)>{
  'messageNotifications': ('Message notifications', Icons.notifications, Color(0xFFE5534B)),
  'groupNotifications': ('Group notifications', Icons.groups, Color(0xFF4CB05A)),
  'reactionNotifications': ('Reaction notifications', Icons.favorite, Color(0xFFEF6C9B)),
  'readReceipts': ('Read receipts', Icons.done_all, _tgBlue),
};

const _privacyFields = <String, (String, IconData, Color)>{
  'lastSeenPrivacy': ('Last seen & online', Icons.visibility, Color(0xFF4CB05A)),
  'profilePhotoPrivacy': ('Profile photo', Icons.account_circle, Color(0xFFF2994A)),
  'groupAddPrivacy': ('Groups & channels', Icons.group_add, Color(0xFF8E6CD8)),
};

String _pretty(dynamic v) {
  final s = v?.toString();
  if (s == null || s.isEmpty) return 'Not set';
  final t = s.replaceAll('_', ' ').toLowerCase();
  return t[0].toUpperCase() + t.substring(1);
}

void _showError(BuildContext context, Object e) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(apiError(e)), behavior: SnackBarBehavior.floating),
  );
}

// ───────────────────────── Settings screen ─────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final c = _TgColors.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Color theme',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            for (final t in const ['LIGHT', 'DARK'])
              ListTile(
                leading: Icon(
                  t == 'LIGHT' ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
                ),
                title: Text(_pretty(t)),
                trailing: current?.toUpperCase() == t
                    ? const Icon(Icons.check, color: _tgBlue)
                    : null,
                onTap: () => Navigator.pop(ctx, t),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || picked == current) return;
    try {
      await ref.read(settingsProvider.notifier).updateSetting('theme', picked);
    } catch (e) {
      _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final c = _TgColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(t('Settings'), style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: c.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _tgBlue)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 48, color: c.secondaryText),
                const SizedBox(height: 12),
                Text(apiError(e), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: _tgBlue),
                  onPressed: () => ref.invalidate(settingsProvider),
                  child: Text(t('Retry')),
                ),
              ],
            ),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _Section(
              header: t('Appearance'),
              children: [
                _TgTile(
                  icon: Icons.palette,
                  color: const Color(0xFFF2994A),
                  title: t('Color theme'),
                  value: t(ref.watch(appPreferencesProvider).themeMode.name == 'system' ? 'System' : ref.watch(appPreferencesProvider).themeMode.name == 'dark' ? 'Dark' : 'Light'),
                  chevron: true,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AppearanceSettingsPage())),
                ),
              ],
            ),
            _Section(
              header: t('Notifications and sounds'),
              children: [
                for (final e in _toggleFields.entries)
                  if (data[e.key] is bool)
                    _TgTile(
                      icon: e.value.$2,
                      color: e.value.$3,
                      title: t(e.value.$1),
                      onTap: () => _toggle(context, ref, e.key, !(data[e.key] as bool)),
                      trailing: Switch.adaptive(
                        value: data[e.key] as bool,
                        activeColor: _tgBlue,
                        onChanged: (v) => _toggle(context, ref, e.key, v),
                      ),
                    ),
              ],
            ),
            _Section(
              header: t('Privacy'),
              footer: t('These options are view-only for now. Editing will be available soon.'),
              children: [
                for (final e in _privacyFields.entries)
                  _TgTile(
                    icon: e.value.$2,
                    color: e.value.$3,
                    title: t(e.value.$1),
                    value: _pretty(data[e.key]),
                  ),
                _TgTile(
                  icon: Icons.block,
                  color: const Color(0xFFE5534B),
                  title: t('Blocked users'),
                  chevron: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    String key,
    bool value,
  ) async {
    try {
      await ref.read(settingsProvider.notifier).updateSetting(key, value);
    } catch (e) {
      _showError(context, e);
    }
  }
}

// ───────────────────────── Blocked users ─────────────────────────

final blockedUsersProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) async => listPayload(
    (await ref.read(dioProvider).get('/api/v1/users/me/blocked')).data,
  ),
);

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  static const _avatarColors = [
    Color(0xFFE5534B),
    Color(0xFFF2994A),
    Color(0xFF8E6CD8),
    Color(0xFF4CB05A),
    Color(0xFF2AABEE),
    Color(0xFFEF6C9B),
    Color(0xFF3FB7B7),
  ];

  Future<void> _unblock(BuildContext context, WidgetRef ref, Object id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Unblock user?'),
        content: const Text('They will be able to contact you again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _tgBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unblock', style: TextStyle(color: _tgBlue)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(dioProvider).delete('/api/v1/users/$id/block');
      ref.invalidate(blockedUsersProvider);
    } catch (e) {
      _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(blockedUsersProvider);
    final c = _TgColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Blocked users', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: c.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _tgBlue)),
        error: (e, _) => Center(
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: _tgBlue),
            onPressed: () => ref.invalidate(blockedUsersProvider),
            child: Text('Retry: ${apiError(e)}'),
          ),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, size: 56, color: c.secondaryText),
                    const SizedBox(height: 12),
                    const Text(
                      'No blocked users',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'People you block will appear here.',
                      style: TextStyle(color: c.secondaryText),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _Section(
                    header: '${items.length} blocked',
                    footer: 'Blocked users can’t message or add you to groups.',
                    children: [
                      for (final raw in items)
                        Builder(builder: (context) {
                          final user = Map<String, dynamic>.from(raw as Map);
                          final id = user['id'];
                          final name = '${user['username'] ?? user['name'] ?? id}';
                          final color = _avatarColors[
                              name.hashCode.abs() % _avatarColors.length];
                          return InkWell(
                            onTap: id == null ? null : () => _unblock(context, ref, id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 21,
                                    backgroundColor: color,
                                    child: Text(
                                      name.isEmpty ? '?' : name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16.5),
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: _tgBlue,
                                    ),
                                    onPressed: id == null
                                        ? null
                                        : () => _unblock(context, ref, id),
                                    child: const Text('Unblock'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
class _AppearanceSettingsPage extends ConsumerWidget {
  const _AppearanceSettingsPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t('Appearance & language'))),
      body: ListView(children: [
        ListTile(title: Text(t('Theme'), style: const TextStyle(fontWeight: FontWeight.bold))),
        for (final mode in ThemeMode.values)
          RadioListTile<ThemeMode>(
            title: Text(t(mode == ThemeMode.dark ? 'Dark' : mode == ThemeMode.light ? 'Light' : 'System')),
            value: mode, groupValue: preferences.themeMode,
            onChanged: (value) { if (value != null) ref.read(appPreferencesProvider.notifier).setTheme(value); },
          ),
        const Divider(),
        ListTile(title: Text(t('Language'), style: const TextStyle(fontWeight: FontWeight.bold))),
        for (final code in ['en', 'km'])
          RadioListTile<String>(
            title: Text(t(code == 'km' ? 'Khmer' : 'English')),
            value: code, groupValue: preferences.languageCode,
            onChanged: (value) { if (value != null) ref.read(appPreferencesProvider.notifier).setLanguage(value); },
          ),
      ]),
    );
  }
}
