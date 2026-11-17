
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etkalem/screens/chat/widgets/chat_date_separator.dart';
import 'package:etkalem/screens/chat/widgets/chat_message_item.dart';
import 'package:etkalem/screens/chat/widgets/empty_chat_widget.dart';
import 'package:flutter/material.dart';

class ChatMessageList extends StatefulWidget {
  final Stream<QuerySnapshot> messageStream;
  final String currentUserID;
  final String receiverID;
  final String receiverName;
  final ScrollController scrollController;

  final Function(DocumentSnapshot, String) onUpdateMessageStatus;
  final ValueChanged<String> onCopy;
  final Function(String, String) onEdit;
  final ValueChanged<String> onDelete;
  final Function(String, String?) onReactionChanged;

  final Function(
      String messageID,
      String message,
      String senderID,
      String senderName,
      ) onReply;

  const ChatMessageList({
    super.key,
    required this.messageStream,
    required this.currentUserID,
    required this.receiverID,
    required this.receiverName,
    required this.scrollController,
    required this.onUpdateMessageStatus,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onReactionChanged,
    required this.onReply,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  int _previousMessageCount = 0;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.scrollController.hasClients) return;

      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: widget.messageStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong',
              style: TextStyle(color: colorScheme.error),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return EmptyChatWidget(receiverName: widget.receiverName);
        }

        if (docs.length > _previousMessageCount) {
          _previousMessageCount = docs.length;
          _scrollToBottom();
        }

        for (final doc in docs) {
          widget.onUpdateMessageStatus(doc, widget.currentUserID);
        }

        final List<Widget> messageWidgets = [];
        DateTime? previousDate;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp).toDate();

          if (previousDate == null ||
              !DateUtils.isSameDay(previousDate, timestamp)) {
            messageWidgets.add(ChatDateSeparator(date: timestamp));
          }

          messageWidgets.add(
            ChatMessageItem(
              doc: doc,
              currentUserID: widget.currentUserID,
              receiverID: widget.receiverID,
              receiverName: widget.receiverName,
              onCopy: widget.onCopy,
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
              onReactionChanged: widget.onReactionChanged,
              onReply: widget.onReply,
            ),
          );

          previousDate = timestamp;
        }

        return ListView(
          controller: widget.scrollController,
          children: messageWidgets,
        );
      },
    );
  }
}
