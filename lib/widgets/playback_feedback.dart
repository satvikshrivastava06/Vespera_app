import 'package:flutter/material.dart';

Future<void> showPlaybackResult(
  BuildContext context, {
  required String title,
  required bool ok,
}) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok ? 'Playing: $title' : 'No licensed stream for $title',
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: ok ? const Color(0xFFE052FF) : Colors.grey[800],
    ),
  );
}
