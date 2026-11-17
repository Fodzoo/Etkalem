import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final DateTime timestamp;
  final bool isCurrentUser;
  final bool isEdited;
  final bool isDelivered;
  final bool isSeen;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  final Map<String, String> reactions;
  final String? currentUserId;
  final ValueChanged<String?>? onReactionChanged;

  // Reply data
  final String? replyToMessage;
  final String? replyToSenderName;
  final String? replyToSenderID;

  const ChatBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.isCurrentUser,
    this.isEdited = false,
    this.isDelivered = false,
    this.isSeen = false,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.reactions = const {},
    this.currentUserId,
    this.onReactionChanged,
    this.replyToMessage,
    this.replyToSenderName,
    this.replyToSenderID,
  });

  static const List<String> _availableReactions = [
    '❤️',
    '😂',
    '👍',
    '😮',
    '😢',
    '🙏',
  ];

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'React to message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _availableReactions.map((emoji) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.pop(sheetContext);

                        final currentReaction = currentUserId == null
                            ? null
                            : reactions[currentUserId];

                        onReactionChanged?.call(
                          currentReaction == emoji ? null : emoji,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.add_reaction_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text('React to Message'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showReactionPicker(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.copy, color: colorScheme.primary),
                title: const Text('Copy Message'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onCopy?.call();
                },
              ),
              if (isCurrentUser) ...[
                ListTile(
                  leading: Icon(Icons.edit, color: colorScheme.primary),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onEdit?.call();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: colorScheme.error),
                  title: Text(
                    'Delete Message',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onDelete?.call();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReactions(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final groupedReactions = <String, int>{};

    for (final emoji in reactions.values) {
      groupedReactions[emoji] = (groupedReactions[emoji] ?? 0) + 1;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, top: 2, bottom: 5),
      child: Wrap(
        spacing: 6,
        runSpacing: 5,
        children: groupedReactions.entries.map((entry) {
          final isSelected =
              currentUserId != null && reactions[currentUserId] == entry.key;

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              onReactionChanged?.call(isSelected ? null : entry.key);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(color: colorScheme.primary)
                    : null,
              ),
              child: Text(
                '${entry.key} ${entry.value}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Reply preview inside message bubble
  Widget _buildReplyPreview(BuildContext context) {
    if (replyToMessage == null || replyToMessage!.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    final senderName =
        replyToSenderID != null && replyToSenderID == currentUserId
        ? 'You'
        : (replyToSenderName ?? 'Unknown');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colorScheme.onPrimary.withValues(alpha: 0.12)
            : colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isCurrentUser ? colorScheme.onPrimary : colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: TextStyle(
              color: isCurrentUser
                  ? colorScheme.onPrimary
                  : colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            replyToMessage!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrentUser
                  ? colorScheme.onPrimary.withValues(alpha: 0.85)
                  : colorScheme.onSurface.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(timestamp));

    return Column(
      crossAxisAlignment: isCurrentUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () => _showMessageOptions(context),
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentUser ? colorScheme.primary : colorScheme.tertiary,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (replyToMessage != null) _buildReplyPreview(context),

                Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isEdited) ...[
                      Text(
                        'Edited',
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrentUser
                              ? colorScheme.onPrimary.withValues(alpha: 0.7)
                              : colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentUser
                            ? colorScheme.onPrimary.withValues(alpha: 0.7)
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 5),
                      Icon(
                        isDelivered || isSeen ? Icons.done_all : Icons.check,
                        size: 16,
                        color: isSeen
                            ? const Color(0xFF60A5FA)
                            : colorScheme.onPrimary.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildReactions(context),
      ],
    );
  }
}
