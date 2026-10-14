import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// A request-failure indicator; it does not claim that an active internet connection
/// means the server is reachable. Keep already-loaded data visible on refresh failure.
class ConnectionNotice extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const ConnectionNotice({
    super.key,
    required this.error,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    final issue = error is DioException ? error as DioException : null;
    final message =
        issue?.type == DioExceptionType.connectionTimeout ||
            issue?.type == DioExceptionType.receiveTimeout
        ? 'Connection is slow. Please retry.'
        : issue?.type == DioExceptionType.connectionError
        ? 'Unable to connect. Check your internet connection.'
        : 'Unable to reach the service right now.';
    return MaterialBanner(
      content: Text(message),
      actions: [TextButton(onPressed: onRetry, child: const Text('Retry'))],
    );
  }
}
