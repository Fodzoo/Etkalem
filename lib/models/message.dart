import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final List<String> deliveredTo;
  final List<String> readBy;
  final Map<String, String> reactions;

  // Reply fields
  final String? replyToMessageID;
  final String? replyToMessage;
  final String? replyToSenderID;
  final String? replyToSenderName;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
    this.deliveredTo = const [],
    this.readBy = const [],
    this.reactions = const {},
    this.replyToMessageID,
    this.replyToMessage,
    this.replyToSenderID,
    this.replyToSenderName,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
      'deliveredTo': deliveredTo,
      'readBy': readBy,
      'reactions': reactions,

      // Reply fields
      'replyToMessageID': replyToMessageID,
      'replyToMessage': replyToMessage,
      'replyToSenderID': replyToSenderID,
      'replyToSenderName': replyToSenderName,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderID: map['senderID'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverID: map['receiverID'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      deliveredTo: List<String>.from(map['deliveredTo'] ?? []),
      readBy: List<String>.from(map['readBy'] ?? []),
      reactions: Map<String, String>.from(map['reactions'] ?? {}),

      // Reply fields
      replyToMessageID: map['replyToMessageID'],
      replyToMessage: map['replyToMessage'],
      replyToSenderID: map['replyToSenderID'],
      replyToSenderName: map['replyToSenderName'],
    );
  }
}
