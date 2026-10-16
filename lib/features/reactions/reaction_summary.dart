/// Aggregates reaction payloads (`ReactionResponse` rows: id, messageId,
/// userId, username, emoji, createdAt) into per-emoji counts.
class ReactionSummary {
  final String emoji;
  final int count;
  final bool mine;
  const ReactionSummary(this.emoji, this.count, this.mine);
}

Object? _reactionUserId(Map<String, dynamic> r) =>
    r['userId'] ?? (r['user'] is Map ? (r['user'] as Map)['id'] : null);

/// Duplicate (userId, emoji) rows are counted once. Rows that carry an
/// aggregate `count` are summed instead.
List<ReactionSummary> summarizeReactions(
  Iterable<Map<String, dynamic>> reactions, {
  Object? currentUserId,
}) {
  final counts = <String, int>{};
  final mine = <String>{};
  final seen = <String>{};
  for (final r in reactions) {
    final emoji = (r['emoji'] ?? '').toString();
    if (emoji.isEmpty) continue;
    final userId = _reactionUserId(r)?.toString();
    final rawCount = r['count'];
    if (rawCount is num) {
      counts[emoji] = (counts[emoji] ?? 0) + rawCount.toInt();
    } else {
      if (userId != null && !seen.add('$userId|$emoji')) continue;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    if (currentUserId != null && userId == currentUserId.toString()) mine.add(emoji);
  }
  return [for (final e in counts.entries) ReactionSummary(e.key, e.value, mine.contains(e.key))];
}

/// What tapping a reaction chip should do for the current user.
enum ReactionAction { add, remove }

ReactionAction toggleAction(List<ReactionSummary> current, String emoji) =>
    current.any((r) => r.emoji == emoji && r.mine) ? ReactionAction.remove : ReactionAction.add;
