import 'package:flutter_test/flutter_test.dart';
import 'package:recruiter_talentbay/features/chat/models/chat_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  test('ChatModel.fromMap should parse unreadCountRecruiter', () {
    final timestamp = Timestamp.now();
    final map = {
      'jobId': 'job123',
      'candidateId': 'cand456',
      'recruiterId': 'rec789',
      'lastMessage': 'Hello',
      'lastMessageTime': timestamp,
      'lastMessageId': 'msg1',
      'lastMessageIsEdited': false,
      'participantIds': ['cand456', 'rec789'],
      'unreadCountRecruiter': 5,
    };

    final chat = ChatModel.fromMap(map, 'chat1');

    expect(chat.unreadCount, 5);
    expect(chat.id, 'chat1');
    expect(chat.jobId, 'job123');
  });

  test('ChatModel.fromMap should default unreadCount to 0 if missing', () {
    final timestamp = Timestamp.now();
    final map = {
      'jobId': 'job123',
      'candidateId': 'cand456',
      'recruiterId': 'rec789',
      'lastMessage': 'Hello',
      'lastMessageTime': timestamp,
      'lastMessageId': 'msg1',
      'lastMessageIsEdited': false,
      'participantIds': ['cand456', 'rec789'],
    };

    final chat = ChatModel.fromMap(map, 'chat1');

    expect(chat.unreadCount, 0);
  });
}
