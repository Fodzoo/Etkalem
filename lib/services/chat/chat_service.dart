import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:etkalem/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _backendUrl = 'http://10.0.2.2:3000';

  // Get chat room ID
  String _getChatRoomID(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    return ids.join('_');
  }

  // Get all public users
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection("PublicUsers").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data();
      }).toList();
    });
  }

  // Send notification through backend
  Future<void> _sendNotification({
    required String chatRoomID,
    required String messageID,
  }) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        return;
      }

      final idToken = await currentUser.getIdToken();

      if (idToken == null) {
        print('Notification Error: Firebase ID Token is null');
        return;
      }

      final response = await http
          .post(
            Uri.parse('$_backendUrl/send-notification'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'chatRoomID': chatRoomID,
              'messageID': messageID,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('Notification Request: ${response.body}');
      } else {
        print(
          'Notification Failed: '
          '${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Notification Error: $e');
    }
  }

  // Send message
  Future<void> sendMessage(
    String receiverID,
    String message, {
    String? replyToMessageID,
    String? replyToMessage,
    String? replyToSenderID,
    String? replyToSenderName,
  }) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderID: currentUserId,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      message: message,
      timestamp: timestamp,
      replyToMessageID: replyToMessageID,
      replyToMessage: replyToMessage,
      replyToSenderID: replyToSenderID,
      replyToSenderName: replyToSenderName,
    );

    final chatRoomID = _getChatRoomID(currentUserId, receiverID);

    final messageDocument = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());

    // Send notification after saving the message
    await _sendNotification(
      chatRoomID: chatRoomID,
      messageID: messageDocument.id,
    );
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    final chatRoomID = _getChatRoomID(userID, otherUserID);

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // Mark message as delivered
  Future<void> markMessageAsDelivered(
    String otherUserID,
    String messageID,
  ) async {
    final currentUserID = _auth.currentUser!.uid;
    final chatRoomID = _getChatRoomID(currentUserID, otherUserID);

    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(messageID)
        .update({
          'deliveredTo': FieldValue.arrayUnion([currentUserID]),
        });
  }

  // Mark message as seen
  Future<void> markMessageAsSeen(String otherUserID, String messageID) async {
    final currentUserID = _auth.currentUser!.uid;
    final chatRoomID = _getChatRoomID(currentUserID, otherUserID);

    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(messageID)
        .update({
          'readBy': FieldValue.arrayUnion([currentUserID]),
        });
  }

  // Edit message
  Future<void> editMessage(
    String receiverID,
    String messageID,
    String newMessage,
  ) async {
    final currentUserID = _auth.currentUser!.uid;
    final chatRoomID = _getChatRoomID(currentUserID, receiverID);

    final messageRef = _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(messageID);

    final messageSnapshot = await messageRef.get();

    if (!messageSnapshot.exists) {
      throw Exception('Message not found');
    }

    final data = messageSnapshot.data()!;

    if (data['senderID'] != currentUserID) {
      throw Exception('You can only edit your own messages');
    }

    await messageRef.update({
      'message': newMessage,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete message
  Future<void> deleteMessage(String receiverID, String messageID) async {
    final currentUserID = _auth.currentUser!.uid;
    final chatRoomID = _getChatRoomID(currentUserID, receiverID);

    final messageRef = _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(messageID);

    final messageSnapshot = await messageRef.get();

    if (!messageSnapshot.exists) {
      throw Exception('Message not found');
    }

    final data = messageSnapshot.data()!;

    if (data['senderID'] != currentUserID) {
      throw Exception('You can only delete your own messages');
    }

    await messageRef.delete();
  }

  // Add, change, or remove message reaction
  Future<void> setMessageReaction(
    String otherUserID,
    String messageID,
    String? reaction,
  ) async {
    final currentUserID = _auth.currentUser!.uid;
    final chatRoomID = _getChatRoomID(currentUserID, otherUserID);

    final messageRef = _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .doc(messageID);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(messageRef);

      if (!snapshot.exists) {
        throw Exception('Message not found');
      }

      final data = snapshot.data()!;
      final reactions = Map<String, String>.from(data['reactions'] ?? {});

      if (reaction == null || reactions[currentUserID] == reaction) {
        reactions.remove(currentUserID);
      } else {
        reactions[currentUserID] = reaction;
      }

      transaction.update(messageRef, {'reactions': reactions});
    });
  }
}
