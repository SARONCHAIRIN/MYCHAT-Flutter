// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:just_audio/just_audio.dart';

// import '../../core/network/api.dart';

// /// Voice bubble that streams protected audio from the MYCHAT backend.
// /// just_audio forwards HTTP Range requests while seeking through the track.
// class VoiceMessageBubble extends ConsumerStatefulWidget {
//   final Object messageId;
//   final Object? durationSeconds;
//   final bool mine;

//   const VoiceMessageBubble({
//     super.key,
//     required this.messageId,
//     required this.mine,
//     this.durationSeconds,
//   });

//   @override
//   ConsumerState<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
// }

// class _VoiceMessageBubbleState extends ConsumerState<VoiceMessageBubble> {
//   late final AudioPlayer _player;
//   bool _sourceLoaded = false;
//   bool _loading = false;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _player = AudioPlayer();
//   }

//   @override
//   void dispose() {
//     _player.dispose();
//     super.dispose();
//   }

//   Future<void> _togglePlayback() async {
//     if (_loading) return;
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       if (!_sourceLoaded) {
//         final token = await ref.read(tokenStoreProvider).access;
//         if (token == null || token.isEmpty) {
//           throw StateError('Please sign in again to play this voice message.');
//         }
//         // API_BASE_URL must normally be the server origin. Also tolerate an
//         // accidental trailing /api/v1 so we do not request /api/v1/api/v1/...
//         var base = apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
//         base = base.replaceFirst(RegExp(r'/api/v1$', caseSensitive: false), '');
//         final rawId = widget.messageId.toString().trim();
//         if (rawId.isEmpty || int.tryParse(rawId) == null) {
//           throw StateError('This voice message has no valid numeric message ID.');
//         }
//         final audioUrl = '$base/api/v1/voice-messages/$rawId/audio';
//         debugPrint('Voice playback request: $audioUrl');
//         try {
//           await _player.setUrl(
//             audioUrl,
//             headers: {'Authorization': 'Bearer $token'},
//           );
//         } on PlayerException catch (e) {
//           debugPrint('Voice playback source error code=${e.code}, message=${e.message}');
//           rethrow;
//         }
//         _sourceLoaded = true;
//       }

//       if (_player.playing) {
//         await _player.pause();
//       } else {
//         if (_player.processingState == ProcessingState.completed) {
//           await _player.seek(Duration.zero);
//         }
//         // play() completes when playback ends or pauses; do not await it here,
//         // otherwise the button stays disabled for the whole audio duration.
//         unawaited(_player.play());
//       }
//     } catch (e) {
//       _sourceLoaded = false;
//       final detail = e.toString().toLowerCase();
//       final message = detail.contains('404')
//           ? 'Audio not found on server (404). Check the message ID and backend file storage.'
//           : detail.contains('401') || detail.contains('403')
//               ? 'You are not authorized to play this voice message. Sign in again or check conversation access.'
//               : 'Could not play audio. Check connection and access.';
//       if (mounted) setState(() => _error = message);
//       debugPrint('Voice playback failed for messageId=${widget.messageId}: $e');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   String _format(Duration value) {
//     final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return '$minutes:$seconds';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final accent = widget.mine ? const Color(0xff2584d8) : const Color(0xff3390ec);
//     return SizedBox(
//       width: 240,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               IconButton(
//                 tooltip: 'Play or pause voice message',
//                 onPressed: _loading ? null : _togglePlayback,
//                 iconSize: 30,
//                 color: accent,
//                 icon: _loading
//                     ? const SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : StreamBuilder<PlayerState>(
//                         stream: _player.playerStateStream,
//                         builder: (context, snapshot) {
//                           final playing = snapshot.data?.playing ?? false;
//                           return Icon(
//                             playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
//                           );
//                         },
//                       ),
//               ),
//               Expanded(
//                 child: StreamBuilder<Duration?>(
//                   stream: _player.durationStream,
//                   builder: (context, durationSnapshot) {
//                     final duration = durationSnapshot.data ??
//                         Duration(
//                           seconds: int.tryParse(
//                                 widget.durationSeconds?.toString() ?? '',
//                               ) ??
//                               0,
//                         );
//                     return StreamBuilder<Duration>(
//                       stream: _player.positionStream,
//                       builder: (context, positionSnapshot) {
//                         final position = positionSnapshot.data ?? Duration.zero;
//                         final maxMs = duration.inMilliseconds > 0
//                             ? duration.inMilliseconds.toDouble()
//                             : 1.0;
//                         final value = position.inMilliseconds
//                             .toDouble()
//                             .clamp(0.0, maxMs)
//                             .toDouble();
//                         return Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             SliderTheme(
//                               data: SliderTheme.of(context).copyWith(
//                                 trackHeight: 3,
//                                 thumbShape: const RoundSliderThumbShape(
//                                   enabledThumbRadius: 5,
//                                 ),
//                                 overlayShape: const RoundSliderOverlayShape(
//                                   overlayRadius: 10,
//                                 ),
//                               ),
//                               child: Slider(
//                                 min: 0,
//                                 max: maxMs,
//                                 value: value,
//                                 activeColor: accent,
//                                 onChanged: duration.inMilliseconds <= 0 ||
//                                         !_sourceLoaded
//                                     ? null
//                                     : (ms) => _player.seek(
//                                           Duration(milliseconds: ms.round()),
//                                         ),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 8),
//                               child: Text(
//                                 '${_format(position)} / ${_format(duration)}',
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   color: Color(0xff697586),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//           if (_error != null)
//             Padding(
//               padding: const EdgeInsets.only(left: 10, bottom: 4),
//               child: Text(
//                 _error!,
//                 style: const TextStyle(color: Colors.red, fontSize: 11),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
