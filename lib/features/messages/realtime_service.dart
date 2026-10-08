import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

/// Configure these values ONLY after verifying the backend WebSocket/STOMP contract.
/// No default destinations are invented.
class RealtimeConfig {
  final String websocketUrl;
  final String Function(Object conversationId) subscription;
  const RealtimeConfig({
    required this.websocketUrl,
    required this.subscription,
  });
}

class RealtimeService {
  final RealtimeConfig config;
  final String accessToken;
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  StompClient? _client;
  bool _disposed = false;
  Stream<Map<String, dynamic>> get events => _events.stream;
  RealtimeService(this.config, this.accessToken);
  void connect(Object conversationId) {
    _client?.deactivate();
    _client = StompClient(
      config: StompConfig(
        url: config.websocketUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (StompFrame frame) {
          if (_disposed) return;
          _client?.subscribe(
            destination: config.subscription(conversationId),
            callback: (frame) {
              if (_disposed || frame.body == null) return;
              try {
                final decoded = jsonDecode(frame.body!);
                if (decoded is Map)
                  _events.add(Map<String, dynamic>.from(decoded));
              } catch (_) {
                /* Malformed event: do not crash the chat. */
              }
            },
          );
        },
      ),
    );
    _client!.activate();
  }

  Future<void> dispose() async {
    _disposed = true;
    _client?.deactivate();
    await _events.close();
  }
}
