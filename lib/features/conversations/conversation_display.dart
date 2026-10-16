import 'package:flutter/material.dart';

/// Resolves the title/avatar shown for a conversation.
/// DIRECT chats display the OTHER member; GROUP chats use the group fields.
/// A direct chat with only yourself is shown as "Saved Messages" (Telegram style).
class ConversationDisplay {
  final String name;
  final String? avatarUrl;
  final bool isGroup;
  final Object? peerId;
  final bool isSelf;
  const ConversationDisplay(
    this.name,
    this.avatarUrl,
    this.isGroup, [
    this.peerId,
    this.isSelf = false,
  ]);

  /// Stable key used to pick the avatar color, so a chat always keeps its color.
  String get colorKey => (peerId ?? name).toString();
}

String? _clean(Object? v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty || s == 'null') ? null : s;
}

ConversationDisplay resolveConversationDisplay(
  Map<String, dynamic> conversation, {
  Object? currentUserId,
}) {
  final isGroup =
      (conversation['type'] ?? '').toString().toUpperCase() == 'GROUP';
  final ownName = _clean(conversation['name']) ?? _clean(conversation['title']);
  if (isGroup) {
    return ConversationDisplay(
      ownName ?? 'Group',
      _clean(conversation['avatarUrl'] ?? conversation['avatar_url']),
      true,
      conversation['id'],
    );
  }

  final members = conversation['members'];
  var sawSelf = false;
  if (members is List) {
    for (final raw in members) {
      if (raw is! Map) continue;
      final member = Map<String, dynamic>.from(raw);
      final nested = member['user'] is Map
          ? Map<String, dynamic>.from(member['user'] as Map)
          : member;
      final id = member['userId'] ?? nested['userId'] ?? nested['id'];
      if (id == null) continue;
      if (id.toString() == currentUserId?.toString()) {
        sawSelf = true;
        continue;
      }
      final name = _clean(nested['name']) ??
          _clean(nested['fullName']) ??
          _clean(nested['username']);
      // Never fall back to the current user's avatar; initials are used instead.
      return ConversationDisplay(
        name ?? ownName ?? 'Unknown user',
        _clean(nested['avatarUrl'] ?? nested['avatar_url']),
        false,
        id,
      );
    }
  }
  if (sawSelf) {
    return ConversationDisplay(
      'Saved Messages',
      null,
      false,
      currentUserId,
      true,
    );
  }
  return ConversationDisplay(ownName ?? 'Conversation', null, false);
}

/// Initials for avatar fallback ("rin1" -> "R", "Jane Doe" -> "JD").
/// Works on grapheme clusters, so emoji and accented letters are not split.
String initialsFor(String label) {
  final parts = label
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  String first(String s) => s.characters.first.toUpperCase();
  if (parts.length == 1) return first(parts.first);
  return first(parts.first) + first(parts.last);
}

// ───────────────────────── Telegram-style avatars ─────────────────────────

/// Telegram's seven peer colors as (top, bottom) gradient pairs.
const _peerGradients = <List<Color>>[
  [Color(0xFFFF885E), Color(0xFFFF516A)], // red
  [Color(0xFFFFCD6A), Color(0xFFFFA85C)], // orange
  [Color(0xFF82B1FF), Color(0xFF665FFF)], // violet
  [Color(0xFFA0DE7E), Color(0xFF54CB68)], // green
  [Color(0xFF53EDD6), Color(0xFF28C9B7)], // cyan
  [Color(0xFF72D5FD), Color(0xFF2A9EF1)], // blue
  [Color(0xFFE0A2F3), Color(0xFFD669ED)], // pink
];

/// Deterministic hash (String.hashCode is not guaranteed stable across runs).
int _stableHash(String s) {
  var h = 5381;
  for (final unit in s.codeUnits) {
    h = ((h << 5) + h + unit) & 0x7fffffff;
  }
  return h;
}

List<Color> avatarGradientFor(String key) =>
    _peerGradients[_stableHash(key) % _peerGradients.length];

/// Circular avatar: network photo when available, otherwise a gradient
/// circle with white initials. Saved Messages gets the blue bookmark icon.
class ConversationAvatar extends StatelessWidget {
  final ConversationDisplay display;
  final double size;
  const ConversationAvatar({super.key, required this.display, this.size = 52});

  @override
  Widget build(BuildContext context) {
    final url = display.avatarUrl;

    Widget fallback() {
      if (display.isSelf) {
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF72D5FD), Color(0xFF2A9EF1)],
            ),
          ),
          child: Center(
            child: Icon(Icons.bookmark, color: Colors.white, size: 26),
          ),
        );
      }
      final g = avatarGradientFor(display.colorKey);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: g,
          ),
        ),
        child: Center(
          child: Text(
            initialsFor(display.name),
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: url == null
            ? fallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              ),
      ),
    );
  }
}