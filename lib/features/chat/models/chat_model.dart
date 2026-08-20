import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/encryption_helper.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String content; // Stored encrypted
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final DateTime? updatedAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isEdited': isEdited,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Helper to get decrypted content
  String get decryptedContent => EncryptionHelper.decryptMessage(content);
}

class ChatModel {
  final String id;
  final String jobId;
  final String candidateId;
  final String recruiterId;
  final String lastMessage; // Stored encrypted
  final DateTime lastMessageTime;
  final String lastMessageId;
  final bool lastMessageIsEdited;
  final List<String> participantIds;
  final int unreadCount;

  ChatModel({
    required this.id,
    required this.jobId,
    required this.candidateId,
    required this.recruiterId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.lastMessageId = '',
    this.lastMessageIsEdited = false,
    required this.participantIds,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'candidateId': candidateId,
      'recruiterId': recruiterId,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageId': lastMessageId,
      'lastMessageIsEdited': lastMessageIsEdited,
      'participantIds': participantIds,
      'unreadCountRecruiter': unreadCount,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatModel(
      id: docId,
      jobId: map['jobId'] ?? '',
      candidateId: map['candidateId'] ?? '',
      recruiterId: map['recruiterId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageId: map['lastMessageId'] ?? '',
      lastMessageIsEdited: map['lastMessageIsEdited'] ?? false,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      unreadCount: map['unreadCountRecruiter'] ?? 0,
    );
  }

  String get decryptedLastMessage =>
      EncryptionHelper.decryptMessage(lastMessage);
}
