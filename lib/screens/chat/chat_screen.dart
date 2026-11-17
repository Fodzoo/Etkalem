import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etkalem/screens/chat/widgets/chat_input.dart';
import 'package:etkalem/screens/chat/widgets/chat_message_list.dart';
import 'package:etkalem/screens/chat/widgets/edit_message_dialog.dart';
import 'package:etkalem/services/auth/auth_service.dart';
import 'package:etkalem/services/auth/presence_service.dart';
import 'package:etkalem/services/chat/chat_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final String receiverName;
  final String receiverID;

  const ChatScreen({
    super.key,
    required this.receiverName,
    required this.receiverID,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _authService = AuthService();
  final _presenceService = PresenceService();

  final myFocusNode = FocusNode();
  final _scrollController = ScrollController();

  late final String _currentUserID;

  late final Stream<QuerySnapshot> _messageStream;

  String? _replyToMessageID;
  String? _replyToMessage;
  String? _replyToSenderID;
  String? _replyToSenderName;

  @override
  void initState() {
    super.initState();

    _currentUserID = _authService.getCurrentUser()!.uid;

    _messageStream = _chatService.getMessages(
      widget.receiverID,
      _currentUserID,
    );

    WidgetsBinding.instance.addObserver(this);
    unawaited(_setActiveChat());

    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), scrollDown);
      }
    });

    Future.delayed(const Duration(milliseconds: 500), scrollDown);
  }

  Future<void> _setActiveChat() async {
    try {
      await _presenceService.setActiveChat(_currentUserID, widget.receiverID);
    } catch (e) {
      debugPrint('Active Chat Error: $e');
    }
  }

  Future<void> _clearActiveChat() async {
    try {
      await _presenceService.clearActiveChat(_currentUserID);
    } catch (e) {
      debugPrint('Clear Active Chat Error: $e');
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_setActiveChat());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_clearActiveChat());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_clearActiveChat());

    myFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void scrollDown() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _handleReply(
    String messageID,
    String message,
    String senderID,
    String senderName,
  ) {
    setState(() {
      _replyToMessageID = messageID;
      _replyToMessage = message;
      _replyToSenderID = senderID;
      _replyToSenderName = senderName;
    });

    myFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToMessageID = null;
      _replyToMessage = null;
      _replyToSenderID = null;
      _replyToSenderName = null;
    });
  }

  Future<void> sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      scrollDown();
      return;
    }

    // Clear the input immediately
    _messageController.clear();

    // Save reply data before clearing the reply UI
    final replyToMessageID = _replyToMessageID;
    final replyToMessage = _replyToMessage;
    final replyToSenderID = _replyToSenderID;
    final replyToSenderName = _replyToSenderName;

    _cancelReply();

    scrollDown();

    try {
      await _chatService.sendMessage(
        widget.receiverID,
        message,
        replyToMessageID: replyToMessageID,
        replyToMessage: replyToMessage,
        replyToSenderID: replyToSenderID,
        replyToSenderName: replyToSenderName,
      );
    } catch (e) {
      debugPrint('Send Message Error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    }
  }

  Future<void> _copyMessage(String message) async {
    await Clipboard.setData(ClipboardData(text: message));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateIncomingMessageStatus(
    DocumentSnapshot doc,
    String currentUserID,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    if (data['senderID'] == currentUserID) return;

    final deliveredTo = List<String>.from(data['deliveredTo'] ?? []);

    final readBy = List<String>.from(data['readBy'] ?? []);

    if (!deliveredTo.contains(currentUserID)) {
      _chatService.markMessageAsDelivered(widget.receiverID, doc.id).catchError(
        (error) {
          debugPrint('Delivered Error: $error');
        },
      );
    }

    if (!readBy.contains(currentUserID)) {
      _chatService.markMessageAsSeen(widget.receiverID, doc.id).catchError((
        error,
      ) {
        debugPrint('Seen Error: $error');
      });
    }
  }

  Future<void> _handleReactionChanged(
    String messageID,
    String? reaction,
  ) async {
    try {
      await _chatService.setMessageReaction(
        widget.receiverID,
        messageID,
        reaction,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update reaction')),
      );

      debugPrint('Reaction Error: $e');
    }
  }

  void _showEditDialog(String messageID, String oldMessage) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return EditMessageDialog(
          oldMessage: oldMessage,
          onSave: (newMessage) async {
            try {
              await _chatService.editMessage(
                widget.receiverID,
                messageID,
                newMessage,
              );
            } catch (e) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to edit message')),
              );
            }
          },
        );
      },
    );
  }

  void _showDeleteDialog(String messageID) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  await _chatService.deleteMessage(
                    widget.receiverID,
                    messageID,
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete message')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatLastSeen(int timestamp) {
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = DateTime.now().difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    }

    if (difference.inHours < 1) {
      return 'Last seen ${difference.inMinutes} min ago';
    }

    if (difference.inDays < 1) {
      return 'Last seen ${difference.inHours} hours ago';
    }

    final hour = lastSeen.hour % 12 == 0 ? 12 : lastSeen.hour % 12;
    final minute = lastSeen.minute.toString().padLeft(2, '0');
    final period = lastSeen.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $period';

    if (difference.inDays == 1) {
      return 'Last seen yesterday at $time';
    }

    final date =
        '${lastSeen.day.toString().padLeft(2, '0')}/'
        '${lastSeen.month.toString().padLeft(2, '0')}/'
        '${lastSeen.year}';

    return 'Last seen $date at $time';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primary,
              child: Text(
                widget.receiverName.isNotEmpty
                    ? widget.receiverName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instanceFor(
                  app: Firebase.app(),
                  databaseURL:
                      'https://etkalem-app-default-rtdb.europe-west1.firebasedatabase.app/',
                ).ref('status/${widget.receiverID}').onValue,
                builder: (context, snapshot) {
                  final data = snapshot.data?.snapshot.value;

                  final isOnline = data is Map && data['state'] == 'online';

                  final lastChanged = data is Map ? data['last_changed'] : null;

                  final lastSeenText = lastChanged is num
                      ? _formatLastSeen(lastChanged.toInt())
                      : 'Offline';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.receiverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF9CA3AF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isOnline ? 'Online' : lastSeenText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessageList(
              messageStream: _messageStream,
              currentUserID: _currentUserID,
              receiverID: widget.receiverID,
              receiverName: widget.receiverName,
              scrollController: _scrollController,
              onUpdateMessageStatus: _updateIncomingMessageStatus,
              onCopy: _copyMessage,
              onEdit: _showEditDialog,
              onDelete: _showDeleteDialog,
              onReactionChanged: _handleReactionChanged,
              onReply: _handleReply,
            ),
          ),
          ChatInput(
            controller: _messageController,
            focusNode: myFocusNode,
            onSend: sendMessage,
            replyToMessage: _replyToMessage,
            replyToSenderName: _replyToSenderName,
            onCancelReply: _cancelReply,
          ),
        ],
      ),
    );
  }
}
