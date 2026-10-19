import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api.dart';
import '../../features/conversations/conversation_display.dart';
import '../../features/uploads/attachment.dart';

/// Hosts that serve HTML share pages instead of image bytes.
const _nonImageHosts = {'share.google', 'photos.app.goo.gl', 'goo.gl', 'g.co'};


/// Returns a loadable absolute URL, or null when the value cannot be an image.
String? validAvatarUrl(String? raw) {
  final resolved = resolveAttachmentUrl(raw, apiBaseUrl);
  if (resolved == null) return null;
  final host = Uri.parse(resolved).host.toLowerCase();
  if (_nonImageHosts.contains(host)) return null;
  // Google search redirect pages return HTML, not decodable image bytes.
  final uri = Uri.parse(resolved);
  if ((host == 'google.com' || host == 'www.google.com') &&
      uri.path == '/url') return null;
  return resolved;
}

/// Single avatar widget used everywhere: validated URL, loading placeholder,
/// and initials fallback when the URL is missing, not an image, or fails.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    required this.label,
    this.url,
    this.group = false,
    this.radius = 24,
  });
  final String label;
  final String? url;
  final bool group;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final src = validAvatarUrl(url);
    final size = radius * 2;
    final fallback = group
        ? Icon(Icons.groups_rounded, color: Colors.white, size: radius)
        : Text(initialsFor(label),
            style: TextStyle(
                fontSize: radius * .8, color: Colors.white, fontWeight: FontWeight.w700));
    return CircleAvatar(
      radius: radius,
      backgroundColor: group ? const Color(0xff74b9e6) : const Color(0xff72a7d4),
      child: src == null
          ? fallback
          : ClipOval(
              child: FutureBuilder<String?>(
                future: ref.read(tokenStoreProvider).access,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(child: fallback);
                  }
                  final token = snapshot.data;
                  return Image.network(
                src,
                headers: token == null || token.isEmpty
                    ? null : {'Authorization': 'Bearer $token'},
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback,
                // "Invalid image data" and HTTP failures land here.
                errorBuilder: (_, __, ___) {
                  debugPrint('Avatar failed to load: $src');
                  return fallback;
                },
              );
                },
              ),
            ),
    );
  }
}
