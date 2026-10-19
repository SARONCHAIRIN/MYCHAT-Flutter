import '../../core/preferences/app_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../settings/settings.dart';
import '../notifications/notifications.dart';
import '../messages/chat_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth.dart';
import '../data/repositories.dart';
import '../../core/network/api.dart';
import '../../core/widgets/user_avatar.dart';
import '../conversations/conversation_display.dart';
import 'group_screen.dart';


// ─────────────────────────────────────────────────────────────────────────────
// Telegram look & feel
// ─────────────────────────────────────────────────────────────────────────────

class Tg {
  static const blue = Color(0xFF2481CC); // app bar / header
  static const accent = Color(0xFF3390EC); // buttons, links, badges
  static const text = Color(0xFF222222);
  static const secondary = Color(0xFF8A8A8A);
  static const divider = Color(0xFFE7E8EC);
  static const surface = Color(0xFFF1F1F4);
  static const online = Color(0xFF4DCD5E);
  static const danger = Color(0xFFE53935);
}

/// Optional: plug into MaterialApp(theme: telegramTheme()) for a global match.
ThemeData telegramTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Tg.accent, primary: Tg.accent),
      scaffoldBackgroundColor: Colors.white,
      dividerColor: Tg.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: Tg.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((s) =>
            IconThemeData(color: s.contains(WidgetState.selected) ? Tg.accent : Tg.secondary)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: s.contains(WidgetState.selected) ? Tg.accent : Tg.secondary)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Tg.accent,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );

InputDecoration _tgField(String label, IconData icon, {String? hint, Widget? suffix}) => InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Tg.secondary),
      suffixIcon: suffix,
      filled: false,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Tg.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Tg.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Tg.accent, width: 1.6)),
    );

/// Rounded grey search box, like Telegram's in-list search.
Widget _searchBox({required TextEditingController controller, required String hint, ValueChanged<String>? onChanged}) =>
    Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: Tg.secondary),
          filled: true,
          fillColor: Tg.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
        ),
      ),
    );

Widget _sectionHeader(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(t, style: const TextStyle(color: Tg.accent, fontWeight: FontWeight.w600, fontSize: 14)),
    );

Widget _insetDivider() => const Padding(padding: EdgeInsets.only(left: 78), child: Divider(height: 1, thickness: .6, color: Tg.divider));

String _lastPreview(Json c) {
  final m = c['lastMessage'] ?? c['last_message'];
  if (m is Map) return (m['content'] ?? m['text'] ?? m['body'] ?? '').toString();
  if (m != null && m.toString().isNotEmpty) return m.toString();
  return (c['description'] ?? 'No messages yet').toString();
}

String _lastTime(Json c) {
  final m = c['lastMessage'] ?? c['last_message'];
  final raw = c['lastMessageAt'] ?? c['last_message_at'] ?? c['updatedAt'] ?? c['updated_at'] ?? (m is Map ? (m['createdAt'] ?? m['created_at']) : null);
  final d = DateTime.tryParse('${raw ?? ''}')?.toLocal();
  if (d == null) return '';
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  if (d.year == now.year && d.month == now.month && d.day == now.day) return '${two(d.hour)}:${two(d.minute)}';
  final diff = now.difference(d).inDays;
  const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (diff < 7) return wd[d.weekday - 1];
  return '${d.day} ${mo[d.month - 1]}';
}

/// Kept for existing call sites; delegates to the hardened [UserAvatar].
class TelegramAvatar extends StatelessWidget {
  const TelegramAvatar({super.key, required this.label, this.url, this.group = false, this.radius = 27});
  final String label;
  final String? url;
  final bool group;
  final double radius;
  @override
  Widget build(BuildContext context) => UserAvatar(label: label, url: url, group: group, radius: radius);
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth
// ─────────────────────────────────────────────────────────────────────────────

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

  Future<void> _submit() async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e)), backgroundColor: Tg.danger));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: form,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (register)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: busy ? null : () => setState(() => register = false),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(color: Tg.accent, shape: BoxShape.circle),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 48),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(register ? 'Create account' : 'MYCHAT Login',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Tg.text)),
                      const SizedBox(height: 8),
                      Text(
                        register ? 'Please enter your name, username, email and a password.' : 'Please sign in to continue your conversations.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Tg.secondary, height: 1.3),
                      ),
                      const SizedBox(height: 20),
                      if (register) ...[
                        TextFormField(
                          controller: name,
                          textCapitalization: TextCapitalization.words,
                          decoration: _tgField('Full name', Icons.person_outline),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: username,
                        autocorrect: false,
                        decoration: _tgField('Username', Icons.alternate_email),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      if (register) ...[
                        TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _tgField('Email', Icons.mail_outline),
                          validator: (v) => v != null && v.contains('@') ? null : 'Invalid email',
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: password,
                        obscureText: obscure,
                        decoration: _tgField(
                          'Password',
                          Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: Tg.secondary),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'At least 6 characters' : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: busy ? null : _submit,
                        child: busy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(register ? 'Register' : 'Login', style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: .6)),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: busy ? null : () => setState(() => register = !register),
                          child: Text(register ? 'Already have an account? Login' : 'Create account',
                              style: const TextStyle(color: Tg.accent, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Home (drawer + tabs)
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int selected = 0;
  bool _loggingOut = false;
  bool searching = false;
  final searchCtl = TextEditingController();

  @override
  void dispose() {
    searchCtl.dispose();
    super.dispose();
  }

  void _closeSearch() => setState(() {
        searching = false;
        searchCtl.clear();
      });

  void _showNewMenu() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.group_add_outlined, color: Tg.accent),
            title: const Text('New Group'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NewGroupScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_outlined, color: Tg.accent),
            title: const Text('New Message'),
            onTap: () {
              Navigator.pop(ctx);
              setState(() => selected = 1);
            },
          ),
        ],
      ),
    ),
  );
}
  Future<void> _confirmLogout() async {
    if (_loggingOut) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to read your messages.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out', style: TextStyle(color: Tg.danger))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _loggingOut = true);
    final navigator = Navigator.of(context);
    try {
      // Revokes the refresh session, clears tokens, and sets auth state to null,
      // which swaps HomeScreen for AuthScreen in MyChatApp.
      await ref.read(authProvider.notifier).logout();
    } finally {
      navigator.popUntil((route) => route.isFirst);
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {Color? color, bool enabled = true}) => ListTile(
        enabled: enabled,
        leading: Icon(icon, color: color ?? Tg.secondary),
        title: Text(label, style: TextStyle(color: color ?? Tg.text, fontWeight: FontWeight.w500)),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appPreferencesProvider).languageCode;
    final titles = ['Chats', 'Contacts', 'Notifications', 'My profile'].map((t) => tr(t, lang)).toList();
    return Scaffold(
      appBar: AppBar(
        leading: searching
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _closeSearch)
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: 'Open menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        title: searching
            ? TextField(
                controller: searchCtl,
                autofocus: true,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(titles[selected]),
        actions: [
          if (searching)
            if (searchCtl.text.isNotEmpty)
              IconButton(icon: const Icon(Icons.close), onPressed: () => setState(searchCtl.clear))
            else
              const SizedBox.shrink()
          else ...[
            if (selected == 0) IconButton(tooltip: 'Search', icon: const Icon(Icons.search_rounded), onPressed: () => setState(() => searching = true)),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Builder(builder: (context) {
                final me = ref.watch(authProvider).valueOrNull;
                final name = (me?['name'] ?? me?['fullName'] ?? me?['username'] ?? 'MYCHAT').toString();
                final username = (me?['username'] ?? '').toString();
                return Container(
                  width: double.infinity,
                  color: Tg.blue,
                  padding: EdgeInsets.fromLTRB(18, MediaQuery.of(context).padding.top + 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(radius: 34, label: name, url: (me?['avatarUrl'] ?? me?['avatar_url'])?.toString()),
                      const SizedBox(height: 14),
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                      if (username.isNotEmpty) Text('@$username', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              _drawerItem(Icons.chat_bubble_outline, 'All chats', () { Navigator.pop(context); setState(() => selected = 0); }),
              _drawerItem(Icons.person_outline, 'Contacts', () { Navigator.pop(context); setState(() => selected = 1); }),
              _drawerItem(Icons.notifications_none, 'Notifications', () { Navigator.pop(context); setState(() => selected = 2); }),
              _drawerItem(Icons.account_circle_outlined, 'My profile', () { Navigator.pop(context); setState(() => selected = 3); }),
              const Divider(height: 16),
              _drawerItem(Icons.palette_outlined, tr('Appearance & language', lang), () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceLanguageScreen()));
              }),
              _drawerItem(Icons.settings_outlined, tr('Settings & privacy', lang), () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
              _drawerItem(Icons.block_outlined, 'Blocked users', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen()));
              }),
              const Spacer(),
              const Divider(height: 1),
              _drawerItem(Icons.logout_rounded, 'Log out', _confirmLogout, color: Tg.danger, enabled: !_loggingOut),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: selected,
        children: [
          ConversationsScreen(query: searchCtl.text),
          const PeopleScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: selected == 0 && !searching
    ? FloatingActionButton(
        backgroundColor: Tg.accent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        tooltip: 'New',
        onPressed: _showNewMenu,
        child: const Icon(Icons.edit_rounded),
      )
    : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Tg.divider, width: .6))),
        child: NavigationBar(
          selectedIndex: selected,
          height: 62,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => setState(() {
            selected = index;
            if (index != 0 && searching) _closeSearch();
          }),
          destinations:  [
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: tr('Chats', lang)),
            NavigationDestination(icon: Icon(Icons.account_box_outlined), selectedIcon: Icon(Icons.account_box_rounded), label: tr('Contacts', lang)),
            NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: tr('Alerts', lang)),
            NavigationDestination(icon: Icon(Icons.account_circle_outlined), selectedIcon: Icon(Icons.account_circle), label: tr('Profile', lang)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile (own)
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.showAppBar = false});

  /// false when embedded in HomeScreen (it already has an app bar).
  final bool showAppBar;
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final name = TextEditingController(), bio = TextEditingController();
  late Future<Json> future;
  bool _filled = false, _saving = false;

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

  Future<void> _changePhoto(Json user) async {
    if (_saving) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final selected = result.files.single;
      if (selected.size == 0) {
        throw StateError('Unable to read the selected photo. Please try again.');
      }
      if (selected.size > 5 * 1024 * 1024) {
        throw StateError('Profile photos must be 5 MB or smaller.');
      }
      final filePath = selected.path;
      if (filePath == null || filePath.isEmpty) {
        throw StateError('Unable to access the selected photo path.');
      }
      setState(() => _saving = true);
      final bytes = selected.bytes;

if (bytes == null || bytes.isEmpty) {
  throw StateError('Unable to read the selected image.');
}

await ref.read(userRepositoryProvider).uploadAvatar(
  bytes: bytes,
  fileName: selected.name,
);
      // All screens watching authProvider rebuild with the latest avatar URL.
      ref.invalidate(authProvider);
      if (!mounted) return;
      setState(() => future = ref.read(userRepositoryProvider).me());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error is StateError ? error.message.toString() : apiError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(userRepositoryProvider).update({'name': name.text, 'bio': bio.text});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Tg.surface,
        appBar: widget.showAppBar ? AppBar(title: const Text('My profile')) : null,
        body: FutureBuilder<Json>(
          future: future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return Center(child: snap.hasError ? Text('Failed: ${apiError(snap.error!)}') : const CircularProgressIndicator());
            }
            final user = snap.data!;
            if (!_filled) {
              name.text = (user['name'] ?? '').toString();
              bio.text = (user['bio'] ?? '').toString();
              _filled = true;
            }
            final display = (user['name'] ?? user['username'] ?? '?').toString();
            return ListView(
              children: [
                // Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          UserAvatar(radius: 52, label: display, url: (user['avatarUrl'] ?? user['avatar_url'])?.toString()),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Material(
                              color: Tg.accent,
                              shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _saving ? null : () => _changePhoto(user),
                                child: Padding(padding: const EdgeInsets.all(9), child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(display, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Tg.text)),
                      const SizedBox(height: 2),
                      const Text('online', style: TextStyle(color: Tg.accent, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sectionHeader('Account'),
                    ListTile(
                      title: Text('@${user['username'] ?? ''}', style: const TextStyle(fontSize: 16)),
                      subtitle: const Text('Username'),
                    ),
                    const Divider(height: 1, indent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: TextField(controller: bio, maxLines: null, decoration: const InputDecoration(labelText: 'Bio', helperText: 'Tell people a little about yourself')),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: .6)),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Contacts
// ─────────────────────────────────────────────────────────────────────────────

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
      final result = search.text.trim().isEmpty ? await repo.list(page: page) : await repo.search(search.text.trim(), page: page);
      if (!mounted || id != generation) return;
      setState(() => users = next ? [...users, ...result] : result);
    } catch (e) {
      if (mounted && id == generation) setState(() => error = apiError(e));
    } finally {
      if (mounted && id == generation) setState(() => loading = false);
    }
  }

  Future<void> _startChat(Json u) async {
    try {
      final conversation = await ref.read(conversationRepositoryProvider).create({'type': 'DIRECT', 'memberId': u['id']});
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conversation['id'] ?? '')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _searchBox(
            controller: search,
            hint: 'Search contacts or @username',
            onChanged: (_) {
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 400), load);
            },
          ),
          if (error != null) TextButton(onPressed: load, child: Text('$error — Retry')),
          Expanded(
            child: ListView(
              children: [
                _sectionHeader(search.text.trim().isEmpty ? 'Contacts' : 'Search results'),
                for (final u in users) ...[
                  InkWell(
                    onTap: () => _startChat(u),
                    onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: u['id']))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(children: [
                        TelegramAvatar(radius: 26, label: (u['name'] ?? u['username'] ?? 'U').toString(), url: (u['avatarUrl'] ?? u['avatar_url'])?.toString()),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((u['name'] ?? u['username'] ?? 'User').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Tg.text)),
                            const SizedBox(height: 2),
                            Text('@${u['username'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Tg.secondary)),
                          ]),
                        ),
                        IconButton(
                          tooltip: 'View profile',
                          icon: const Icon(Icons.info_outline, color: Tg.secondary),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: u['id']))),
                        ),
                      ]),
                    ),
                  ),
                  _insetDivider(),
                ],
                if (loading) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
                if (!loading && users.isEmpty && error == null)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No contacts found', style: TextStyle(color: Tg.secondary)))),
                if (!loading && users.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      page++;
                      load(next: true);
                    },
                    child: const Text('Load more', style: TextStyle(color: Tg.accent)),
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
        backgroundColor: Tg.surface,
        appBar: AppBar(title: const Text('Profile')),
        body: FutureBuilder<Json>(
          future: ref.read(userRepositoryProvider).byId(userId ?? ''),
          builder: (context, snap) {
            if (!snap.hasData) {
              return Center(child: snap.hasError ? Text(apiError(snap.error!)) : const CircularProgressIndicator());
            }
            final u = snap.data!;
            final display = (u['name'] ?? u['username'] ?? '?').toString();
            final bio = (u['bio'] ?? '').toString();
            return ListView(children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(children: [
                  UserAvatar(radius: 52, label: display, url: (u['avatarUrl'] ?? u['avatar_url'])?.toString()),
                  const SizedBox(height: 14),
                  Text(display, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Tg.text)),
                  const SizedBox(height: 2),
                  Text('@${u['username'] ?? ''}', style: const TextStyle(color: Tg.secondary)),
                ]),
              ),
              const SizedBox(height: 8),
              Container(
                color: Colors.white,
                child: Column(children: [
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, color: Tg.secondary),
                    title: const Text('Send message'),
                    onTap: () async {
                      try {
                        final c = await ref.read(conversationRepositoryProvider).create({'type': 'DIRECT', 'memberId': u['id']});
                        if (!context.mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c['id'] ?? '')));
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
                      }
                    },
                  ),
                  if (bio.isNotEmpty) ...[
                    const Divider(height: 1, indent: 72),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Tg.secondary),
                      title: Text(bio),
                      subtitle: const Text('Bio'),
                    ),
                  ],
                ]),
              ),
            ]);
          },
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat list
// ─────────────────────────────────────────────────────────────────────────────

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key, this.query = ''});

  /// Search text coming from the app bar in HomeScreen.
  final String query;
  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  late Future<List<Json>> future;
  String category = 'All';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    future = ref.read(conversationRepositoryProvider).list();
  }

  int _unread(Json c) => int.tryParse('${c['unreadCount'] ?? 0}') ?? 0;
  bool _isGroup(Json c) => (c['type'] ?? '').toString().toUpperCase() == 'GROUP';

  Widget _tabs(List<Json> all) {
    final unread = all.where((c) => _unread(c) > 0).length;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Tg.divider, width: .6))),
      child: SingleChildScrollView(
        child: Row(children: [
          for (final label in const ['All', 'Unread', 'Groups', 'Direct'])
            InkWell(
              onTap: () => setState(() => category = label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: category == label ? Tg.accent : Colors.transparent, width: 2.5)),
                ),
                child: Row(children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: category == label ? Tg.accent : Tg.secondary)),
                  if (label == 'Unread' && unread > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: category == label ? Tg.accent : Tg.secondary, borderRadius: BorderRadius.circular(10)),
                      child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _row(Json c, Object? ownId) {
    final display = resolveConversationDisplay(c, currentUserId: ownId);
    final unread = _unread(c);
    final time = _lastTime(c);
    return Column(children: [
      InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: c['id'] ?? ''))).then((_) => setState(refresh)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
          child: Row(children: [
            UserAvatar(radius: 28, label: display.name, url: display.avatarUrl, group: display.isGroup),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (display.isGroup) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.group, size: 16, color: Tg.secondary)),
                  Expanded(child: Text(display.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Tg.text))),
                  const SizedBox(width: 6),
                  Text(time, style: TextStyle(fontSize: 12, color: unread > 0 ? Tg.accent : Tg.secondary)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Expanded(child: Text(_lastPreview(c), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, color: Tg.secondary))),
                  if (unread > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: Tg.accent, borderRadius: BorderRadius.circular(12)),
                      child: Text(unread > 999 ? '999+' : '$unread', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
      _insetDivider(),
    ]);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Json>>(
        future: future,
        builder: (context, snap) {
          final all = snap.data ?? <Json>[];
          final me = ref.watch(authProvider).valueOrNull;
          final ownId = me?['id'] ?? me?['userId'];
          final q = widget.query.trim().toLowerCase();
          final visible = all.where((c) {
            final title = resolveConversationDisplay(c, currentUserId: ownId).name;
            final matches = q.isEmpty || title.toLowerCase().contains(q) || _lastPreview(c).toLowerCase().contains(q);
            return matches &&
                (category == 'All' ||
                    (category == 'Groups' && _isGroup(c)) ||
                    (category == 'Direct' && !_isGroup(c)) ||
                    (category == 'Unread' && _unread(c) > 0));
          }).toList();

          return Column(children: [
            _tabs(all),
            if (snap.hasError)
              Container(
                color: const Color(0xFFFFF3E0),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.wifi_off_rounded, color: Tg.secondary),
                  title: Text(apiError(snap.error!), maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: TextButton(onPressed: () => setState(refresh), child: const Text('Retry')),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                color: Tg.accent,
                onRefresh: () async {
                  setState(refresh);
                  try {
                    await future;
                  } catch (_) {}
                },
                child: !snap.hasData && !snap.hasError
                    ? ListView(children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))])
                    : visible.isEmpty
                        ? ListView(children: const [
                            Padding(
                              padding: EdgeInsets.all(60),
                              child: Center(child: Text('No conversations found', style: TextStyle(color: Tg.secondary, fontSize: 15))),
                            ),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 90),
                            itemCount: visible.length,
                            itemBuilder: (_, i) => _row(visible[i], ownId),
                          ),
              ),
            ),
          ]);
        },
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Conversation info
// ─────────────────────────────────────────────────────────────────────────────

class ConversationDetailsScreen extends ConsumerWidget {
  final Object? id;
  const ConversationDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authProvider).valueOrNull;
    final ownId = me?['id'] ?? me?['userId'];
    return Scaffold(
      backgroundColor: Tg.surface,
      appBar: AppBar(title: const Text('Info')),
      body: FutureBuilder<Json>(
        future: ref.read(conversationRepositoryProvider).byId(id ?? ''),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Center(child: snap.hasError ? Text(apiError(snap.error!)) : const CircularProgressIndicator());
          }
          final c = snap.data!;
          final display = resolveConversationDisplay(c, currentUserId: ownId);
          return FutureBuilder<List<Json>>(
            future: ref.read(conversationRepositoryProvider).members(id ?? ''),
            builder: (context, members) {
              final list = members.data ?? <Json>[];
              return ListView(children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(children: [
                    UserAvatar(radius: 52, label: display.name, url: display.avatarUrl, group: display.isGroup),
                    const SizedBox(height: 14),
                    Text(display.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Tg.text)),
                    const SizedBox(height: 2),
                    Text(members.hasData ? '${list.length} members' : '', style: const TextStyle(color: Tg.secondary)),
                  ]),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, color: Tg.accent),
                    title: const Text('Open messages', style: TextStyle(color: Tg.accent, fontWeight: FontWeight.w500)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversationId: id ?? ''))),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  color: Colors.white,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sectionHeader('Members'),
                    if (members.hasError)
                      Padding(padding: const EdgeInsets.all(16), child: Text(apiError(members.error!)))
                    else if (!members.hasData)
                      const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                    else
                      for (final m in list) ...[
                        ListTile(
                          leading: TelegramAvatar(radius: 22, label: (m['name'] ?? m['username'] ?? 'M').toString(), url: (m['avatarUrl'] ?? m['avatar_url'])?.toString()),
                          title: Text((m['name'] ?? m['username'] ?? m['userId'] ?? 'Member').toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: m['username'] != null ? Text('@${m['username']}') : null,
                        ),
                      ],
                  ]),
                ),
              ]);
            },
          );
        },
      ),
    );
  }
}
class AppearanceLanguageScreen extends ConsumerWidget {
  const AppearanceLanguageScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(appPreferencesProvider);
    final lang = pref.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Appearance & language', lang))),
      body: ListView(children: [
        ListTile(title: Text(tr('Theme', lang))),
        for (final mode in ThemeMode.values)
          RadioListTile<ThemeMode>(
            title: Text(tr(mode == ThemeMode.system ? 'System' : mode == ThemeMode.dark ? 'Dark' : 'Light', lang)),
            value: mode, groupValue: pref.themeMode,
            onChanged: (value) { if (value != null) ref.read(appPreferencesProvider.notifier).setTheme(value); },
          ),
        const Divider(),
        ListTile(title: Text(tr('Language', lang))),
        for (final code in ['en', 'km'])
          RadioListTile<String>(
            title: Text(tr(code == 'en' ? 'English' : 'Khmer', lang)),
            value: code, groupValue: lang,
            onChanged: (value) { if (value != null) ref.read(appPreferencesProvider.notifier).setLanguage(value); },
          ),
      ]),
    );
  }
}
