import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api.dart';
import '../../core/theme/stitch_theme.dart';

import '../auth/auth.dart';
import '../conversations/conversation_display.dart';
import '../data/repositories.dart';
import '../reactions/reaction_summary.dart';
import '../ui/screens.dart';
import '../uploads/attachment.dart';

import 'message_repository.dart';
import 'realtime_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Object conversationId;
  const ChatScreen({super.key, required this.conversationId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _refreshInFlight = false;
  final input = TextEditingController();
  final scroll = ScrollController();
  List<MessageJson> messages = [];
  String? cursor, error;
  bool loading = false, sending = false, hasMore = true;
  Object? replyTo;
  final Set<String> receiptSent = {};
  final Map<String, List<MessageJson>> _reactionCache = {};
  final Set<String> _reactionLoading = {};
  final Map<String, MessageJson> _uploadedAttachments = {};
  final Set<String> _mediaLookupInFlight = {};
  final Set<String> _mediaLookupDone = {};
  // Temporary local previews while uploads finish. Persisted images come from
  // the attachment URLs in the message history API.
  final Map<String, PlatformFile> _localFiles = {};
  final Set<String> _pinnedIds = {};
  double? _uploadProgress;
  String? _token;
  RealtimeService? _realtime;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;
  bool _showPinned = true;
  final ValueNotifier<bool> _showJump = ValueNotifier(false);
  Json? _conversation;
  Json? _peer;
  int? _groupMemberCount;
  Object? get _ownId {
    final account = ref.read(authProvider).valueOrNull;
    return account?['id'] ?? account?['userId'];
  }

  ConversationDisplay get _display => resolveConversationDisplay(
    _conversation ?? <String, dynamic>{},
    currentUserId: _ownId,
  );
  String get _chatName =>
      (_peer?['name'] ??
              _peer?['fullName'] ??
              _peer?['username'] ??
              _display.name)
          .toString();
  String? get _chatAvatar =>
      (_peer?['avatarUrl'] ?? _peer?['avatar_url'] ?? _display.avatarUrl)
          ?.toString();
  Future<void> _loadConversation() async {
    try {
      final repo = ref.read(conversationRepositoryProvider);
      final details = await repo.byId(widget.conversationId);
      Json? peer;
      final type = (details['type'] ?? '').toString().toUpperCase();
      if (type != 'GROUP') {
        final account = ref.read(authProvider).valueOrNull;
        final ownId = account?['id'] ?? account?['userId'];
        final embedded = details['members'];
        final members = embedded is List && embedded.isNotEmpty
            ? embedded.map((e) => Json.from(e as Map)).toList()
            : await repo.members(widget.conversationId);
        for (final member in members) {
          final nested = member['user'];
          final user = nested is Map ? Json.from(nested) : member;
          final userId = member['userId'] ?? user['userId'] ?? user['id'];
          if (userId != null && userId.toString() != ownId?.toString()) {
            peer = user;
            if (peer['avatarUrl'] == null && peer['avatar_url'] == null) {
              try {
                peer = await ref.read(userRepositoryProvider).byId(userId);
              } catch (_) {}
            }
            break;
          }
        }
      }
      int? groupMemberCount;
      if (type == 'GROUP') {
        final embedded = details['members'];
        if (embedded is List) {
          groupMemberCount = embedded.length;
        } else {
          try {
            groupMemberCount = (await repo.members(
              widget.conversationId,
            )).length;
          } catch (_) {
            /* Leave count unavailable when access fails. */
          }
        }
      }
      if (mounted)
        setState(() {
          _conversation = details;
          _peer = peer;
          _groupMemberCount = groupMemberCount;
        });
    } catch (_) {
      /* Keep chat usable if details are unavailable. */
    }
  }

  bool _isMine(MessageJson m) {
    if (m['isMine'] == true || m['mine'] == true || m['isOwn'] == true)
      return true;
    final account = ref.read(authProvider).valueOrNull;
    final selfId = account?['id'] ?? account?['userId'];
    final sender =
        m['senderId'] ?? (m['sender'] is Map ? m['sender']['id'] : null);
    return selfId != null &&
        sender != null &&
        selfId.toString() == sender.toString();
  }

  String _time(MessageJson m) {
    final raw = (m['createdAt'] ?? m['created_at'] ?? '').toString();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$hour:${local.minute.toString().padLeft(2, '0')} ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients)
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 230),
          curve: Curves.easeOut,
        );
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scroll.addListener(_onScroll);
    Future.microtask(load);
    Future.microtask(_loadConversation);
    Future.microtask(_loadPins);
    Future.microtask(_startRealtime);
    // REST fallback until the backend STOMP contract is verified.
    // Poll only while this screen is visible; never overlap refreshes.
    _startRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _realtimeSub?.cancel();
    _realtime?.dispose();
    input.dispose();
    scroll.dispose();
    _showJump.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRefreshTimer();
      refreshLatest();
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }

  Future<void> _loadPins() async {
    try {
      final pins = await ref
          .read(messageRepositoryProvider)
          .pins(widget.conversationId);
      if (mounted) {
        setState(() {
          _pinnedIds
            ..clear()
            ..addAll(pins.map((p) => (p['messageId'] ?? p['id']).toString()));
        });
      }
    } catch (_) {
      /* Pin state is optional. */
    }
  }

  // Contract (backend source): STOMP at /ws, Bearer token in CONNECT headers,
  // topic /topic/conversations/{id}, events {type, conversationId, data}.
  // REST polling stays as a fallback when the socket is unavailable.
  Future<void> _startRealtime() async {
    final token = await ref.read(tokenStoreProvider).access;
    if (!mounted || token == null || token.isEmpty) return;
    setState(() => _token = token);
    final wsBase = apiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    final service = RealtimeService(
      RealtimeConfig(
        websocketUrl: '$wsBase/ws',
        subscription: (id) => '/topic/conversations/$id',
      ),
      token,
    );
    _realtime = service;
    _realtimeSub = service.events.listen(_onRealtimeEvent);
    service.connect(widget.conversationId);
  }

  void _onRealtimeEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final type = (event['type'] ?? '').toString();
    final data = event['data'];
    switch (type) {
      case 'message:new':
      case 'message:edited':
      case 'message:deleted':
        if (data is Map) {
          setState(
            () => messages = mergeMessages(messages, [MessageJson.from(data)]),
          );
          _syncReactions();
        } else {
          refreshLatest();
        }
        break;
      case 'reaction:added':
      case 'reaction:removed':
        final messageId = data is Map ? data['messageId'] : null;
        if (messageId != null) _refreshReactions(messageId);
        break;
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refreshLatest(),
    );
  }

  Future<void> load({bool older = false, bool keepScroll = false}) async {
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
      _syncReactions();
      if (!older && !keepScroll) _scrollToLatest();
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

  Future<void> refreshLatest() async {
    if (!mounted || loading || _refreshInFlight) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed)
      return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    _refreshInFlight = true;
    try {
      final page = await ref
          .read(messageRepositoryProvider)
          .history(widget.conversationId);
      if (!mounted) return;
      setState(() {
        messages = mergeMessages(messages, page.messages);
      });
      _syncReactions();
    } catch (_) {
      // Keep cached messages on transient network/server failures.
    } finally {
      _refreshInFlight = false;
    }
  }

  // Fetch reactions independently because the history endpoint does not
  // guarantee that reactions are embedded in each message.
  void _syncReactions() {
    for (final message in messages) {
      final id = messageKey(message);
      if (id.isEmpty ||
          _reactionLoading.contains(id) ||
          _reactionCache.containsKey(id))
        continue;
      _reactionLoading.add(id);
      ref
          .read(messageRepositoryProvider)
          .reactions(id)
          .then((items) {
            if (mounted) setState(() => _reactionCache[id] = items);
          })
          .catchError((Object _) {
            // Reactions are optional; a failure must not hide the message.
          })
          .whenComplete(() => _reactionLoading.remove(id));
    }
  }

  Future<void> _refreshReactions(Object id) async {
    try {
      final result = await ref.read(messageRepositoryProvider).reactions(id);
      if (mounted) setState(() => _reactionCache[id.toString()] = result);
    } catch (_) {
      /* Message remains visible if reaction fetch fails. */
    }
  }

  Widget _reactionChips(MessageJson message) {
    final id = messageKey(message);
    final reactions = _reactionCache[id] ?? const <MessageJson>[];
    final summary = summarizeReactions(reactions, currentUserId: _ownId);
    if (summary.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Wrap(
        spacing: 5,
        runSpacing: 4,
        children: [
          for (final entry in summary)
            InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () async {
                try {
                  final repo = ref.read(messageRepositoryProvider);
                  if (toggleAction(summary, entry.emoji) ==
                      ReactionAction.remove) {
                    await repo.unreact(id, entry.emoji);
                  } else {
                    await repo.react(id, entry.emoji);
                  }
                  await _refreshReactions(id);
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(apiError(e))));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.mine
                      ? const Color(0xffb9d8fb)
                      : const Color(0xffe9f2fb),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: entry.mine
                        ? StitchTheme.primary
                        : const Color(0xffa9c8f3),
                  ),
                ),
                child: Text(
                  '${entry.emoji} ${entry.count}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff234c79),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Accept both a list of attachments and a single upload object. The
  // backend may return either a URL or a nested file object.
  List<Map<String, dynamic>> _attachmentsFor(MessageJson message) {
    final results = <Map<String, dynamic>>[];
    void add(dynamic value) {
      if (value is List) {
        for (final item in value) {
          add(item);
        }
      } else if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        if (map['data'] is Map) {
          add(map['data']);
          return;
        }
        if (map['attachments'] is List) {
          add(map['attachments']);
        }
        if (map['attachment'] is Map) {
          add(map['attachment']);
        }
        final url =
            map['url'] ??
            map['fileUrl'] ??
            map['downloadUrl'] ??
            map['attachmentUrl'] ??
            map['imageUrl'] ??
            map['file_url'] ??
            map['storageUrl'];
        if (url is String && url.trim().isNotEmpty) results.add(map);
      } else if (value is String && value.trim().isNotEmpty) {
        // Upload responses and history may contain relative /uploads/ paths.
        results.add({'url': value});
      }
    }

    add(message['attachments']);
    add(message['attachment']);
    add(message['files']);
    add(message['fileUrl']);
    add(message['attachmentUrl']);
    add(message['imageUrl']);
    add(message['image_url']);
    add(message['file_url']);
    add(message['media']);
    final id = messageKey(message);
    if (_uploadedAttachments.containsKey(id)) add(_uploadedAttachments[id]);
    // A selected image should be visible immediately in its own bubble,
    // even before the upload response arrives. This is a local preview only:
    // persistence still depends on the backend returning attachment metadata.
    final localPath = _localFiles[id];
    if (results.isEmpty && localPath != null) {
      results.add({
        'fileName': localPath.name,
        'mimeType':
            mimeTypeForFile(localPath.name) ?? 'application/octet-stream',
        'localPreview': true,
      });
    }
    // Some backend versions omit attachments in the history list. Request the
    // single-message endpoint once as a fallback, then merge its media fields.
    final type = (message['type'] ?? '').toString().toUpperCase();
    if (results.isEmpty &&
        (type == 'IMAGE' || type == 'FILE') &&
        id.isNotEmpty &&
        !_mediaLookupInFlight.contains(id) &&
        !_mediaLookupDone.contains(id)) {
      _mediaLookupInFlight.add(id);
      Future.microtask(() async {
        try {
          final fresh = await ref.read(messageRepositoryProvider).get(id);
          if (!mounted) return;
          final merged = <String, dynamic>{...message, ...fresh};
          setState(() {
            messages = [
              for (final item in messages)
                if (messageKey(item) == id) merged else item,
            ];
          });
        } catch (error) {
          debugPrint('Media metadata lookup failed for message $id: $error');
        } finally {
          _mediaLookupInFlight.remove(id);
          _mediaLookupDone.add(id);
        }
      });
    }
    return results;
  }

  Widget _messageAttachments(MessageJson message) {
    final attachments = _attachmentsFor(message);
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final file in attachments)
          Builder(
            builder: (context) {
              final url =
                  (file['url'] ??
                          file['fileUrl'] ??
                          file['downloadUrl'] ??
                          file['attachmentUrl'] ??
                          file['imageUrl'] ??
                          file['file_url'] ??
                          file['storageUrl'] ??
                          '')
                      .toString();
              final mime =
                  (file['mimeType'] ??
                          file['contentType'] ??
                          file['mime_type'] ??
                          '')
                      .toString()
                      .toLowerCase();
              final name =
                  (file['fileName'] ??
                          file['filename'] ??
                          file['originalName'] ??
                          'Attachment')
                      .toString();
              final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
              final isImage =
                  mime.startsWith('image/') ||
                  RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)$').hasMatch(path) ||
                  RegExp(
                    r'\.(jpg|jpeg|png|gif|webp|bmp)$',
                    caseSensitive: false,
                  ).hasMatch(name);
              if (!isImage)
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 20),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                );
              final local = _localFiles[messageKey(message)];
              final resolved = resolveAttachmentUrl(url, apiBaseUrl);
              final isPendingLocal = file['localPreview'] == true;
              Widget broken() => Container(
                width: 245,
                height: 100,
                color: const Color(0xffedf0f4),
                alignment: Alignment.center,
                child: const Text(
                  'Image unavailable',
                  style: TextStyle(fontSize: 12),
                ),
              );
              Widget image(BoxFit fit, {double? w, double? h}) {
                if (local != null) {
                  if (local.bytes != null) {
                    return Image.memory(
                      local.bytes!,
                      width: w,
                      height: h,
                      fit: fit,
                      errorBuilder: (_, __, ___) => broken(),
                    );
                  }

                  if (!kIsWeb && local.path != null) {
                    return Image.file(
                      File(local.path!),
                      width: w,
                      height: h,
                      fit: fit,
                      errorBuilder: (_, __, ___) => broken(),
                    );
                  }
                }

                if (resolved == null) {
                  return broken();
                }

                return Image.network(
                  resolved,
                  width: w,
                  height: h,
                  fit: fit,
                  headers: _token == null || _token!.isEmpty
                      ? null
                      : {'Authorization': 'Bearer $_token'},
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;

                    return SizedBox(
                      width: w,
                      height: h ?? 120,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, error, __) {
                    debugPrint(
                      'Message image failed to load: $resolved ($error)',
                    );
                    return broken();
                  },
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        body: Center(
                          child: InteractiveViewer(
                            minScale: 1,
                            maxScale: 5,
                            child: image(BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      children: [
                        image(BoxFit.cover, w: 245, h: 210),
                        if (isPendingLocal)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xCC17212B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                child: Text(
                                  'Local preview · upload pending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
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
      _scrollToLatest();
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
      if (mounted) await load(keepScroll: true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }

  Future<void> pickAndSendAttachment() async {
    if (sending) return;

    try {
      // 1. Pick file
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (selection == null || selection.files.isEmpty || !mounted) {
        return;
      }

      final PlatformFile file = selection.files.first;

      // 2. Validate file
      final problem = validateUpload(file.name, file.size);

      if (problem != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(problem)));
        return;
      }

      if (file.bytes == null || file.bytes!.isEmpty) {
        throw StateError('Unable to read selected file');
      }

      // 3. Detect file type
      final mimeType = mimeTypeForFile(file.name) ?? '';
      final isImage = mimeType.startsWith('image/');

      final captionController = TextEditingController();

      // 4. Preview before sending
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(isImage ? 'Send image' : 'Send file'),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      file.bytes!,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Text('Preview unavailable');
                      },
                    ),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(file.name),
                  ),

                const SizedBox(height: 10),

                TextField(
                  controller: captionController,
                  decoration: const InputDecoration(hintText: 'Add a caption'),
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Send'),
              ),
            ],
          );
        },
      );

      final caption = captionController.text;
      captionController.dispose();

      if (confirmed != true || !mounted) {
        return;
      }

      // 5. Start sending
      setState(() {
        sending = true;
        _uploadProgress = 0;
      });

      MessageJson? created;

      try {
        // Step 1: Create message
        created = await ref
            .read(messageRepositoryProvider)
            .sendAttachmentMessage(
              widget.conversationId,
              file.name,
              caption: caption,
              replyTo: replyTo,
            );

        if (!mounted) return;

        // Step 2: Show local preview
        setState(() {
          messages = mergeMessages(messages, [created!]);
          replyTo = null;
          _localFiles[messageKey(created!)] = file;
        });

        _scrollToLatest();

        // Step 3: Upload file
        await _uploadExisting(created, file);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Send failed: ${apiError(e)}'),
            action: created == null
                ? null
                : SnackBarAction(
                    label: 'Retry upload',
                    onPressed: () {
                      _uploadExisting(created!, file);
                    },
                  ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            sending = false;
            _uploadProgress = null;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File selection failed: ${apiError(e)}')),
      );
    }
  }

  Future<void> _uploadExisting(MessageJson message, PlatformFile file) async {
    final id = messageKey(message);

    try {
      final uploaded = await ref
          .read(messageRepositoryProvider)
          .upload(
            id,
            file,
            progress: (sent, total) {
              if (mounted && total > 0) {
                setState(() {
                  _uploadProgress = sent / total;
                });
              }
            },
          );

      if (!mounted) return;

      setState(() {
        _uploadedAttachments[id] = uploaded;
      });

      try {
        final fresh = await ref.read(messageRepositoryProvider).get(id);

        if (!mounted) return;

        setState(() {
          messages = mergeMessages(messages, [fresh]);
          _localFiles.remove(id);
        });
      } catch (error) {
        debugPrint('Unable to refresh uploaded message $id: $error');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${apiError(e)}'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              _uploadExisting(message, file);
            },
          ),
        ),
      );
    }
  }

  Future<void> _forwardAsText(MessageJson message) async {
    final content = (message['content'] ?? '').toString().trim();
    if (content.isEmpty) return;
    try {
      final chats = await ref.read(conversationRepositoryProvider).list();
      if (!mounted) return;
      final selected = await showModalBottomSheet<Json>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Send text to another chat',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final chat in chats)
                Builder(
                  builder: (_) {
                    final display = resolveConversationDisplay(
                      chat,
                      currentUserId: _ownId,
                    );
                    return ListTile(
                      leading: TelegramAvatar(
                        label: display.name,
                        url: display.avatarUrl,
                        group: display.isGroup,
                      ),
                      title: Text(display.name),
                      onTap: () => Navigator.pop(ctx, chat),
                    );
                  },
                ),
            ],
          ),
        ),
      );
      if (selected == null) return;
      final id = selected['id'];
      if (id == null) return;
      await ref.read(messageRepositoryProvider).send(id, content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent to selected chat')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(error))));
      }
    }
  }

  Future<void> showActions(MessageJson m, Offset globalPosition) async {
    final id = m['id'] ?? m['messageId'];
    if (id == null) return;
    final mine = _isMine(m);
    final repo = ref.read(messageRepositoryProvider);
    final size = MediaQuery.sizeOf(context);
    final menuWidth = (size.width - 16).clamp(0.0, 290.0);
    final left = (globalPosition.dx - menuWidth / 2)
        .clamp(8.0, size.width - menuWidth - 8.0)
        .toDouble();
    final top = (globalPosition.dy - 78)
        .clamp(MediaQuery.paddingOf(context).top + 4, size.height - 310)
        .toDouble();
    final choice = await showMenu<String>(
      context: context,
      color: const Color(0xff243447),
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      position: RelativeRect.fromLTRB(
        left,
        top,
        size.width - left - menuWidth,
        0,
      ),
      items: [
        PopupMenuItem<String>(
          enabled: true,
          height: 61,
          padding: EdgeInsets.zero,
          child: ReactionBar(
            onPick: (emoji) => Navigator.of(context).pop('emoji:$emoji'),
          ),
        ),

        const PopupMenuDivider(height: 1),
        _telegramAction('reply', Icons.reply_rounded, 'Reply'),
        _telegramAction('copy', Icons.copy_rounded, 'Copy'),
        _telegramAction('forward', Icons.forward_rounded, 'Forward'),
        _pinnedIds.contains(id.toString())
            ? _telegramAction('unpin', Icons.push_pin, 'Unpin')
            : _telegramAction('pin', Icons.push_pin_outlined, 'Pin'),
        if (mine) _telegramAction('edit', Icons.edit_outlined, 'Edit'),
        if (mine)
          _telegramAction(
            'delete',
            Icons.delete_outline,
            'Delete',
            destructive: true,
          ),
        _telegramAction(
          'reactions',
          Icons.emoji_emotions_outlined,
          'Reactions',
        ),
      ],
    );
    if (!mounted || choice == null) return;
    if (choice.startsWith('emoji:')) {
      try {
        await repo.react(id, choice.substring(6));
        await _refreshReactions(id);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
      return;
    }
    switch (choice) {
      case 'reply':
        setState(() => replyTo = id);
        break;
      case 'copy':
        await Clipboard.setData(
          ClipboardData(text: (m['content'] ?? '').toString()),
        );
        break;
      case 'forward':
        await _forwardAsText(m);
        break;
      case 'pin':
        await act(() => repo.pin(widget.conversationId, id));
        await _loadPins();
        break;
      case 'unpin':
        await act(() => repo.unpin(widget.conversationId, id));
        await _loadPins();
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete message?'),
            content: const Text('This message will be deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) await act(() => repo.delete(id));
        break;
      case 'edit':
        final controller = TextEditingController(
          text: (m['content'] ?? '').toString(),
        );
        try {
          final value = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Edit message'),
              content: TextField(controller: controller, autofocus: true),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (value != null && value.isNotEmpty)
            await act(() => repo.edit(id, value));
        } finally {
          controller.dispose();
        }
        break;
      case 'reactions':
        try {
          final reactions = await repo.reactions(id);
          if (!mounted) return;
          await showModalBottomSheet<void>(
            context: context,
            builder: (ctx) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(title: Text('Reactions')),
                  for (final reaction in reactions)
                    ListTile(
                      title: Text((reaction['emoji'] ?? '').toString()),
                      subtitle: Text((reaction['userId'] ?? '').toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(ctx);
                          act(
                            () => repo.unreact(
                              id,
                              (reaction['emoji'] ?? '').toString(),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        } catch (e) {
          if (mounted)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(apiError(e))));
        }
        break;
    }
  }

  PopupMenuItem<String> _telegramAction(
    String value,
    IconData icon,
    String label, {
    bool destructive = false,
  }) => PopupMenuItem<String>(
    value: value,
    height: 49,
    child: Row(
      children: [
        Icon(
          icon,
          size: 23,
          color: destructive ? const Color(0xffff8c8c) : Colors.white,
        ),
        const SizedBox(width: 18),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: destructive ? const Color(0xffff8c8c) : Colors.white,
          ),
        ),
      ],
    ),
  );

  // ---------- Telegram-style UI helpers ----------
  static const _tgAccent = Color(0xff3390ec);
  static const _tgOut = Color(0xffeffdde);
  static const _tgOutMeta = Color(0xff5fb35b);
  static const _tgMuted = Color(0xff8a96a3);
  static const _tgInk = Color(0xff0f1419);
  static const _tgChip = Color(0x66000000);
  static const _nameColors = [
    Color(0xffd0453b),
    Color(0xff3a8f3a),
    Color(0xffc27a12),
    Color(0xff2f7fc1),
    Color(0xff8a4fbf),
    Color(0xff1f9aa3),
  ];

  bool get _isGroup =>
      (_conversation?['type'] ?? '').toString().toUpperCase() == 'GROUP';

  void _onScroll() {
    if (!scroll.hasClients) return;
    final far = scroll.position.maxScrollExtent - scroll.offset > 400;
    if (far != _showJump.value) _showJump.value = far;
  }

  DateTime? _dateOf(MessageJson m) => DateTime.tryParse(
    (m['createdAt'] ?? m['created_at'] ?? '').toString(),
  )?.toLocal();

  bool _sameDay(DateTime? a, DateTime? b) =>
      a != null &&
      b != null &&
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;

  String _dayLabel(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return d.year == now.year
        ? '${months[d.month - 1]} ${d.day}'
        : '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _senderKey(MessageJson m) =>
      (m['senderId'] ??
              (m['sender'] is Map ? m['sender']['id'] : null) ??
              (_isMine(m) ? 'me' : 'other'))
          .toString();

  bool _isRead(MessageJson m) {
    final status = (m['status'] ?? '').toString().toUpperCase();
    return m['read'] == true ||
        m['isRead'] == true ||
        m['seen'] == true ||
        status == 'READ' ||
        status == 'SEEN';
  }

  MessageJson? _findMessage(Object? id) {
    if (id == null) return null;
    for (final m in messages) {
      if (messageKey(m) == id.toString()) return m;
    }
    return null;
  }

  String _previewOf(MessageJson? m) {
    if (m == null) return 'Original message';
    final c = (m['content'] ?? '').toString();
    return c.isEmpty ? '📎 Attachment' : c;
  }

  String _nameOf(MessageJson? m) {
    if (m == null) return 'Message';
    if (_isMine(m)) return 'You';
    return (m['senderName'] ?? _chatName).toString();
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: Colors.white,
    foregroundColor: _tgInk,
    elevation: 0.5,
    scrolledUnderElevation: 0.5,
    surfaceTintColor: Colors.transparent,
    titleSpacing: 0,
    title: Row(
      children: [
        TelegramAvatar(
          radius: 19,
          label: _chatName,
          url: _chatAvatar,
          group: _isGroup,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _chatName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _isGroup
                    ? (_groupMemberCount == null
                          ? 'group chat'
                          : '$_groupMemberCount members')
                    : 'MYCHAT',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _tgMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: _tgMuted),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (action) {
          if (action == 'pins')
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PinsScreen(conversationId: widget.conversationId),
              ),
            );
          if (action == 'refresh') load(keepScroll: true);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'pins', child: Text('Pinned messages')),
          PopupMenuItem(value: 'refresh', child: Text('Refresh messages')),
        ],
      ),
    ],
  );

  Widget _pinnedBar() => Material(
    color: Colors.white,
    child: InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinsScreen(conversationId: widget.conversationId),
        ),
      ),
      child: Container(
        height: 46,
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x14000000))),
        ),
        child: Row(
          children: [
            Container(
              width: 2.5,
              height: 32,
              decoration: BoxDecoration(
                color: _tgAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pinnedIds.length > 1
                        ? 'Pinned messages (${_pinnedIds.length})'
                        : 'Pinned message',
                    style: const TextStyle(
                      color: _tgAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Tap to view',
                    maxLines: 1,
                    style: TextStyle(color: _tgInk, fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.push_pin_outlined, size: 20, color: _tgMuted),
            IconButton(
              icon: const Icon(Icons.close, size: 19, color: _tgMuted),
              onPressed: () => setState(() => _showPinned = false),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _dateChip(String label) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: _tgChip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  Widget _replyQuote(MessageJson m, bool mine) {
    final raw = m['replyToId'] ?? m['replyTo'] ?? m['parentId'];
    if (raw == null) return const SizedBox.shrink();
    final target = raw is Map ? MessageJson.from(raw) : _findMessage(raw);
    final color = mine ? _tgOutMeta : _tgAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(5),
        border: Border(left: BorderSide(color: color, width: 2.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _nameOf(target),
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _previewOf(target),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: _tgInk),
          ),
        ],
      ),
    );
  }

  Widget _bubble(int i) {
    final m = messages[i];
    final mine = _isMine(m);
    final prev = i > 0 ? messages[i - 1] : null;
    final next = i < messages.length - 1 ? messages[i + 1] : null;
    final date = _dateOf(m);
    final showDay = prev == null || !_sameDay(_dateOf(prev), date);
    final groupedWithPrev =
        prev != null && !showDay && _senderKey(prev) == _senderKey(m);
    final groupedWithNext =
        next != null &&
        _sameDay(_dateOf(next), date) &&
        _senderKey(next) == _senderKey(m);
    final attachments = _attachmentsFor(m);
    var content = (m['content'] ?? '').toString();
    // A file name is used as content when no caption was typed; hide it.
    if (attachments.isNotEmpty) {
      final names = attachments.map(
        (a) => (a['fileName'] ?? a['filename'] ?? '').toString(),
      );
      if (names.contains(content)) content = '';
    }
    final edited = m['edited'] == true || m['editedAt'] != null;
    final deleted = m['deleted'] == true;
    final metaColor = mine ? _tgOutMeta : _tgMuted;
    final showName =
        _isGroup && !mine && !groupedWithPrev && m['senderName'] != null;
    final nameColor =
        _nameColors[_senderKey(m).hashCode.abs() % _nameColors.length];
    const big = Radius.circular(16);
    const small = Radius.circular(4);
    final radius = BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: (!mine && !groupedWithNext) ? small : big,
      bottomRight: (mine && !groupedWithNext) ? small : big,
    );
    final time = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (edited)
          Text('edited ', style: TextStyle(fontSize: 11.5, color: metaColor)),
        Text(_time(m), style: TextStyle(fontSize: 11.5, color: metaColor)),
        if (mine) ...[
          const SizedBox(width: 3),
          Icon(
            _isRead(m) ? Icons.done_all : Icons.done,
            size: 15,
            color: _isRead(m) ? _tgAccent : _tgOutMeta,
          ),
        ],
      ],
    );
    final text = deleted
        ? 'Message deleted'
        : (content.isEmpty && attachments.isEmpty ? '📎 Attachment' : content);
    final hasText = text.isNotEmpty;
    final bubble = GestureDetector(
      onLongPressStart: (d) => showActions(m, d.globalPosition),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        padding: EdgeInsets.fromLTRB(
          attachments.isEmpty ? 10 : 4,
          attachments.isEmpty ? 6 : 4,
          attachments.isEmpty ? 10 : 4,
          5,
        ),
        decoration: BoxDecoration(
          color: mine ? _tgOut : Colors.white,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1a000000),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showName)
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 4),
                child: Text(
                  (m['senderName']).toString(),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: nameColor,
                  ),
                ),
              ),
            _replyQuote(m, mine),
            _messageAttachments(m),
            if (hasText)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: attachments.isEmpty ? 0 : 6,
                ),
                // Text with the time floated to the bottom-right corner.
                child: Stack(
                  children: [
                    Text(
                      '$text\u2003\u2003\u2003${mine ? '\u2003' : ''}${edited ? '\u2003' : ''}',
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.28,
                        color: _tgInk,
                        fontStyle: deleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                    Positioned(right: 0, bottom: 0, child: time),
                  ],
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: time,
                ),
              ),
            _reactionChips(m),
          ],
        ),
      ),
    );
    return Column(
      children: [
        if (showDay && date != null) _dateChip(_dayLabel(date)),
        _SwipeReply(
          onReply: () {
            final id = m['id'] ?? m['messageId'];
            if (id != null) setState(() => replyTo = id);
          },
          child: Padding(
            padding: EdgeInsets.only(
              top: groupedWithPrev ? 2 : 7,
              left: 8,
              right: 8,
            ),
            child: Row(
              mainAxisAlignment: mine
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [Flexible(child: bubble)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _replyBar() {
    final target = _findMessage(replyTo);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: _tgAccent),
          const SizedBox(width: 10),
          Container(width: 2.5, height: 34, color: _tgAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reply to ${_nameOf(target)}',
                  style: const TextStyle(
                    color: _tgAccent,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  target == null ? 'Message $replyTo' : _previewOf(target),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, color: _tgInk),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: _tgMuted),
            onPressed: () => setState(() => replyTo = null),
          ),
        ],
      ),
    );
  }

  Widget _composer() => SafeArea(
    top: false,
    child: Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xfff1f3f5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 4, 12),
                    child: Icon(
                      Icons.sentiment_satisfied_alt_outlined,
                      color: _tgMuted,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: _tgMuted, fontSize: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: input,
                    builder: (_, value, __) => value.text.trim().isEmpty
                        ? IconButton(
                            tooltip: 'Attach image or file',
                            icon: const Icon(
                              Icons.attach_file_rounded,
                              color: _tgMuted,
                              size: 24,
                            ),
                            onPressed: sending ? null : pickAndSendAttachment,
                          )
                        : const SizedBox(width: 8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: input,
            builder: (_, value, __) {
              final hasText = value.text.trim().isNotEmpty;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: hasText
                    ? Material(
                        key: const ValueKey('send'),
                        color: _tgAccent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: sending ? null : send,
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: sending
                                ? const Padding(
                                    padding: EdgeInsets.all(13),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('none'),
                        width: 0,
                        height: 46,
                      ),
              );
            },
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xffb6d7b0),
    appBar: _appBar(),
    body: Column(
      children: [
        if (_showPinned && _pinnedIds.isNotEmpty) _pinnedBar(),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xffdbe7c0),
                  Color(0xffb6d7b0),
                  Color(0xff9fd0c0),
                ],
              ),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    if (error != null)
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          dense: true,
                          title: Text(
                            error!,
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: TextButton(
                            onPressed: () => load(),
                            child: const Text('Retry'),
                          ),
                        ),
                      ),
                    if (loading) const LinearProgressIndicator(minHeight: 2),
                    Expanded(
                      child: messages.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _tgChip,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  loading
                                      ? 'Loading…'
                                      : 'No messages here yet…',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scroll,
                              padding: const EdgeInsets.fromLTRB(0, 6, 0, 10),
                              itemCount: messages.length + (hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (hasMore && index == 0) {
                                  return Center(
                                    child: TextButton(
                                      onPressed: loading
                                          ? null
                                          : () => load(older: true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: _tgChip,
                                        shape: const StadiumBorder(),
                                      ),
                                      child: const Text('Load older messages'),
                                    ),
                                  );
                                }
                                return _bubble(hasMore ? index - 1 : index);
                              },
                            ),
                    ),
                  ],
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _showJump,
                    builder: (_, show, __) => AnimatedScale(
                      scale: show ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Material(
                        color: Colors.white,
                        elevation: 3,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _scrollToLatest,
                          child: const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _tgMuted,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (replyTo != null) _replyBar(),
        if (_uploadProgress != null)
          LinearProgressIndicator(value: _uploadProgress, minHeight: 3),
        _composer(),
      ],
    ),
  );
}

const _quickReactions = ['👍', '❤️', '🔥', '😁', '🙏', '👌'];

const _allReactions = [
  '👍',
  '👎',
  '❤️',
  '🔥',
  '🥰',
  '👏',
  '😁',
  '🤔',
  '🤯',
  '😱',
  '🤬',
  '😢',
  '🎉',
  '🤩',
  '🤮',
  '💩',
  '🙏',
  '👌',
  '🕊',
  '🤡',
  '🥱',
  '🥴',
  '😍',
  '🐳',
  '❤️‍🔥',
  '🌚',
  '🌭',
  '💯',
  '🤣',
  '⚡️',
  '🍌',
  '🏆',
  '💔',
  '🤨',
  '😐',
  '🍓',
  '🍾',
  '💋',
  '😈',
  '😴',
  '😭',
  '🤓',
  '👻',
  '👨‍💻',
  '👀',
  '🎃',
  '🙈',
  '😇',
  '😨',
  '🤝',
  '✍️',
  '🤗',
  '🫡',
  '🎅',
  '🎄',
  '☃️',
  '💅',
  '🤪',
  '🗿',
  '🆒',
  '💘',
  '🙉',
  '🦄',
  '😘',
  '💊',
  '🙊',
  '😎',
  '👾',
  '🤷',
  '😡',
];

class ReactionBar extends StatefulWidget {
  const ReactionBar({super.key, required this.onPick});
  final ValueChanged<String> onPick;
  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  bool expanded = false;

  Widget _emoji(String e, {double size = 22}) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () => widget.onPick(e),
    child: Padding(
      padding: const EdgeInsets.all(5),
      child: Text(e, style: TextStyle(fontSize: size)),
    ),
  );

  Widget _toggle() => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () => setState(() => expanded = !expanded),
    child: Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFE9ECEF),
        shape: BoxShape.circle,
      ),
      child: Icon(
        expanded
            ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded,
        size: 20,
        color: Tg.secondary,
      ),
    ),
  );

  Widget _quickRow() => SizedBox(
    height: 61,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [for (final e in _quickReactions) _emoji(e), _toggle()],
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
    alignment: Alignment.topCenter,
    child: expanded
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _quickRow(),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 230),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (final e in _allReactions) _emoji(e, size: 24),
                    ],
                  ),
                ),
              ),
            ],
          )
        : _quickRow(),
  );
}

/// Swipe a message left to reply, like Telegram.
class _SwipeReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  const _SwipeReply({required this.child, required this.onReply});
  @override
  State<_SwipeReply> createState() => _SwipeReplyState();
}

class _SwipeReplyState extends State<_SwipeReply> {
  double dx = 0;
  static const _trigger = 56.0;
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onHorizontalDragUpdate: (d) =>
        setState(() => dx = (dx + d.delta.dx).clamp(-72.0, 0.0)),
    onHorizontalDragEnd: (_) {
      if (dx <= -_trigger) {
        HapticFeedback.lightImpact();
        widget.onReply();
      }
      setState(() => dx = 0);
    },
    onHorizontalDragCancel: () => setState(() => dx = 0),
    child: Stack(
      alignment: Alignment.centerRight,
      children: [
        Positioned(
          right: 10,
          child: Opacity(
            opacity: (-dx / _trigger).clamp(0.0, 1.0).toDouble(),
            child: const CircleAvatar(
              radius: 15,
              backgroundColor: Color(0x66000000),
              child: Icon(Icons.reply_rounded, size: 18, color: Colors.white),
            ),
          ),
        ),
        AnimatedContainer(
          duration: dx == 0 ? const Duration(milliseconds: 160) : Duration.zero,
          transform: Matrix4.translationValues(dx, 0, 0),
          child: widget.child,
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
    backgroundColor: const Color(0xfff1f3f5),
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xff0f1419),
      elevation: 0.5,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Pinned messages',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
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
              Container(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 1),
                child: ListTile(
                  leading: const Icon(
                    Icons.push_pin_outlined,
                    color: Color(0xff3390ec),
                  ),
                  title: Text(
                    (m['content'] ?? 'Message #${m['messageId'] ?? ''}')
                        .toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
