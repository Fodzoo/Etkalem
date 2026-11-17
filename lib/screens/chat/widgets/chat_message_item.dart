import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etkalem/core/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';

class ChatMessageItem extends StatefulWidget {
  final DocumentSnapshot doc;
  final String currentUserID;
  final String receiverID;
  final String receiverName;

  final ValueChanged<String> onCopy;
  final Function(String, String) onEdit;
  final ValueChanged<String> onDelete;
  final Function(String, String?)? onReactionChanged;

  final Function(
    String messageID,
    String message,
    String senderID,
    String senderName,
  )?
  onReply;

  const ChatMessageItem({
    super.key,
    required this.doc,
    required this.currentUserID,
    required this.receiverID,
    required this.receiverName,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    this.onReactionChanged,
    this.onReply,
  });

  @override
  State<ChatMessageItem> createState() => _ChatMessageItemState();
}

class _ChatMessageItemState extends State<ChatMessageItem> {
  double _dragOffset = 0;

  static const double _replyThreshold = 65;
  static const double _maxDragOffset = 90;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx > 0) {
      setState(() {
        _dragOffset = (_dragOffset + details.delta.dx).clamp(
          0.0,
          _maxDragOffset,
        );
      });
    } else if (_dragOffset > 0) {
      setState(() {
        _dragOffset = (_dragOffset + details.delta.dx).clamp(
          0.0,
          _maxDragOffset,
        );
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset >= _replyThreshold) {
      final data = widget.doc.data() as Map<String, dynamic>;

      final senderID = data['senderID'] ?? '';
      final isCurrentUser = senderID == widget.currentUserID;

      final senderName = isCurrentUser
          ? (data['senderEmail'] ?? 'Unknown')
          : widget.receiverName;

      widget.onReply?.call(
        widget.doc.id,
        data['message'] ?? '',
        senderID,
        senderName,
      );
    }

    setState(() {
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;

    final isCurrentUser = data['senderID'] == widget.currentUserID;

    final deliveredTo = List<String>.from(data['deliveredTo'] ?? []);

    final readBy = List<String>.from(data['readBy'] ?? []);

    final reactions = Map<String, String>.from(data['reactions'] ?? {});

    final timestamp = (data['timestamp'] as Timestamp).toDate();

    final message = data['message'] ?? '';

    final colorScheme = Theme.of(context).colorScheme;

    // Reply data
    final String? replyToMessage = data['replyToMessage'];
    final String? replyToSenderName = data['replyToSenderName'];
    final String? replyToSenderID = data['replyToSenderID'];

    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 8,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: (_dragOffset / _replyThreshold).clamp(0.0, 1.0),
              child: Icon(
                Icons.reply_rounded,
                color: colorScheme.primary,
                size: 26,
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            onHorizontalDragCancel: () {
              setState(() {
                _dragOffset = 0;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(_dragOffset, 0, 0),
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  ChatBubble(
                    message: message,
                    timestamp: timestamp,
                    isCurrentUser: isCurrentUser,
                    isEdited: data['isEdited'] ?? false,
                    isDelivered: deliveredTo.contains(widget.receiverID),
                    isSeen: readBy.contains(widget.receiverID),
                    reactions: reactions,
                    currentUserId: widget.currentUserID,

                    // Reply data
                    replyToMessage: replyToMessage,
                    replyToSenderName: replyToSenderName,
                    replyToSenderID: replyToSenderID,

                    onCopy: () => widget.onCopy(message),
                    onEdit: () => widget.onEdit(widget.doc.id, message),
                    onDelete: () => widget.onDelete(widget.doc.id),
                    onReactionChanged: (reaction) {
                      widget.onReactionChanged?.call(widget.doc.id, reaction);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
