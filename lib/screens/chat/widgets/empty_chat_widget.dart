import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyChatWidget extends StatelessWidget {
  final String receiverName;

  const EmptyChatWidget({super.key, required this.receiverName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/empty_chat.json',
              width: 230,
              height: 230,
              fit: BoxFit.contain,
              repeat: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Start a Conversation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Say hello to $receiverName and start chatting!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
