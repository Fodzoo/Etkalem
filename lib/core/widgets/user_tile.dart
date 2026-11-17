import 'package:etkalem/services/auth/auth_service.dart';
import 'package:etkalem/services/chat/chat_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String receiverID;
  final void Function()? onTap;

  UserTile({
    super.key,
    required this.text,
    required this.receiverID,
    this.onTap,
  });

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://etkalem-app-default-rtdb.europe-west1.firebasedatabase.app/',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final currentUserId = _authService.getCurrentUser()?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                StreamBuilder<DatabaseEvent>(
                  stream: _database.ref('status/$receiverID').onValue,
                  builder: (context, snapshot) {
                    final statusData = snapshot.data?.snapshot.value;

                    final isOnline =
                        statusData is Map && statusData['state'] == 'online';

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: colors.secondary,
                          child: Text(
                            text.trim().isNotEmpty
                                ? text.trim()[0].toUpperCase()
                                : "?",
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF9CA3AF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),

                      if (currentUserId == null)
                        Text(
                          "Sign in to view messages",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        )
                      else
                        StreamBuilder(
                          stream: _chatService.getMessages(
                            receiverID,
                            currentUserId,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(
                                "Couldn't load messages",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.error,
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text(
                                "Loading...",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Text(
                                "No messages yet",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              );
                            }

                            final lastMessage = Map<String, dynamic>.from(
                              snapshot.data!.docs.last.data() as Map,
                            );

                            final String messageText =
                                (lastMessage["message"] ?? "").toString();

                            final bool isSentByMe =
                                lastMessage["senderID"] == currentUserId;

                            return Text(
                              isSentByMe ? "You: $messageText" : messageText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
