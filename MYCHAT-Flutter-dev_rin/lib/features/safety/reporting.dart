import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String targetType;
  final Object targetId;
  const ReportScreen({
    super.key,
    required this.targetType,
    required this.targetId,
  });
  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? reason;
  final details = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    details.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (reason == null || busy) return;
    setState(() => busy = true);
    try {
      await ref
          .read(dioProvider)
          .post(
            '/api/v1/reports',
            data: {
              'targetType': widget.targetType,
              'targetId': widget.targetId,
              'reason': reason,
              'description': details.text.trim(),
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report submitted')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Choose a reason'),
        for (final option in ['SPAM', 'INAPPROPRIATE', 'OTHER'])
          RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: reason,
            onChanged: (v) => setState(() => reason = v),
          ),
        TextField(
          controller: details,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
          ),
        ),
        FilledButton(
          onPressed: busy || reason == null ? null : submit,
          child: const Text('Submit report'),
        ),
      ],
    ),
  );
}
