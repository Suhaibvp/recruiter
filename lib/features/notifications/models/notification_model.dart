import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { message, application }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? payloadId;
  final String? jobId;
  final String? candidateId;
  final String? candidateName;
  final String? candidateImageUrl;
  final String? jobTitle;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.payloadId,
    this.jobId,
    this.candidateId,
    this.candidateName,
    this.candidateImageUrl,
    this.jobTitle,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    NotificationType type = NotificationType.application;
    if (map['type'] == 'message') {
      type = NotificationType.message;
    }

    return NotificationModel(
      id: docId,
      type: type,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      payloadId: map['payloadId'],
      jobId: map['jobId'],
      candidateId: map['candidateId'],
      candidateName: map['candidateName'],
      candidateImageUrl: map['candidateImageUrl'],
      jobTitle: map['jobTitle'],
    );
  }
}
