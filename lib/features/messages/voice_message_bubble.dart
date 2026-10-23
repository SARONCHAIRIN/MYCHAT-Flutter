import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/network/api.dart';

/// Protected, seekable voice-message player with a live playback clock.
class VoiceMessageBubble extends ConsumerStatefulWidget {
  final Object messageId;
  final Object? durationSeconds;
  final bool mine;

  const VoiceMessageBubble({
    super.key,
    required this.messageId,
    required this.mine,
    this.durationSeconds,
  });

  @override
  ConsumerState<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends ConsumerState<VoiceMessageBubble> {
  late final AudioPlayer _player;
  bool _sourceLoaded = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!_sourceLoaded) {
        final token = await ref.read(tokenStoreProvider).access;
        if (token == null || token.isEmpty) {
          throw StateError('Please sign in again to play this voice message.');
        }

        var base = apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
        base = base.replaceFirst(RegExp(r'/api/v1$', caseSensitive: false), '');
        final rawId = widget.messageId.toString().trim();

        if (rawId.isEmpty || int.tryParse(rawId) == null) {
          throw StateError('This voice message has no valid numeric message ID.');
        }

        final audioUrl = '$base/api/v1/voice-messages/$rawId/audio';
        debugPrint('Voice playback request: $audioUrl');

        await _player.setUrl(
          audioUrl,
          headers: {'Authorization': 'Bearer $token'},
        );
        _sourceLoaded = true;
      }

      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        unawaited(_player.play());
      }
    } catch (e) {
      _sourceLoaded = false;
      final detail = e.toString().toLowerCase();
      final message = detail.contains('404')
          ? 'Audio not found on server (404).'
          : detail.contains('401') || detail.contains('403')
              ? 'You are not authorized to play this audio.'
              : 'Could not load audio. Check your connection.';
      if (mounted) setState(() => _error = message);
      debugPrint('Voice playback failed for messageId=${widget.messageId}: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Duration _fallbackDuration() {
    final seconds = int.tryParse(widget.durationSeconds?.toString() ?? '') ?? 0;
    return Duration(seconds: seconds < 0 ? 0 : seconds);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = widget.mine
        ? const Color(0xFF1687E8)
        : const Color(0xFF2878D4);
    final track = widget.mine
        ? const Color(0xFFB7D9F5)
        : colors.outlineVariant.withValues(alpha: 0.75);
    final textColor = colors.onSurface;
    final muted = colors.onSurfaceVariant;

    return SizedBox(
      width: 258,
      child: StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, playerSnapshot) {
          final playerState = playerSnapshot.data;
          final playing = playerState?.playing ?? false;
          final completed =
              playerState?.processingState == ProcessingState.completed;

          return StreamBuilder<Duration?>(
            stream: _player.durationStream,
            builder: (context, durationSnapshot) {
              final reportedDuration =
                  durationSnapshot.data ?? _player.duration;
              final fallback = _fallbackDuration();
              final duration = (reportedDuration != null &&
                      reportedDuration > Duration.zero)
                  ? reportedDuration
                  : fallback;

              return StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, positionSnapshot) {
                  var position = positionSnapshot.data ?? Duration.zero;
                  if (completed) position = duration;
                  if (duration > Duration.zero && position > duration) {
                    position = duration;
                  }

                  final maxMs = duration.inMilliseconds > 0
                      ? duration.inMilliseconds.toDouble()
                      : 1.0;
                  final progress = position.inMilliseconds
                      .toDouble()
                      .clamp(0.0, maxMs)
                      .toDouble();
                  final remaining = duration > Duration.zero
                      ? (duration - position).abs()
                      : Duration.zero;
                  final timeLabel = playing || position > Duration.zero
                      ? _format(position)
                      : _format(duration);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Semantics(
                            button: true,
                            label: playing
                                ? 'Pause voice message'
                                : 'Play voice message',
                            child: Material(
                              color: accent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _loading ? null : _togglePlayback,
                                child: SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Center(
                                    child: _loading
                                        ? const SizedBox(
                                            width: 19,
                                            height: 19,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            playing
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 28,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    activeTrackColor: accent,
                                    inactiveTrackColor: track,
                                    thumbColor: accent,
                                    overlayColor: accent.withValues(alpha: 0.12),
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12,
                                    ),
                                    trackShape:
                                        const RoundedRectSliderTrackShape(),
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: maxMs,
                                    value: progress,
                                    onChanged: duration <= Duration.zero ||
                                            !_sourceLoaded
                                        ? null
                                        : (ms) => _player.seek(
                                              Duration(
                                                milliseconds: ms.round(),
                                              ),
                                            ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 3,
                                    right: 4,
                                    top: 1,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        timeLabel,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        playing
                                            ? '-${_format(remaining)}'
                                            : _format(duration),
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 11,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 7),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 15,
                                color: colors.onErrorContainer,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: colors.onErrorContainer,
                                    fontSize: 11,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
