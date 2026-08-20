import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/encryption_helper.dart';
import '../models/chat_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepository(this._firestore, this._auth);

  /// Get existing chat or create a new one if it doesn't exist
  Future<String> getOrCreateChat({
    required String jobId,
    required String candidateId,
    required String recruiterId,
  }) async {
    // Check if chat exists
    final query = await _firestore
        .collection('chats')
        .where('jobId', isEqualTo: jobId)
        .where('candidateId', isEqualTo: candidateId)
        .where('recruiterId', isEqualTo: recruiterId)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    // Create new chat
    final docRef = await _firestore.collection('chats').add({
      'jobId': jobId,
      'candidateId': candidateId,
      'recruiterId': recruiterId,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageId': '',
      'lastMessageIsEdited': false,
      'participantIds': [candidateId, recruiterId],
    });

    return docRef.id;
  }

  /// Send a message
  Future<void> sendMessage({
    required String chatId,
    required String content,
  }) async {
    final senderId = _auth.currentUser?.uid ?? '';
    if (senderId.isEmpty) return;

    // Encrypt content
    final encryptedContent = EncryptionHelper.encryptMessage(content);

    // Add message to subcollection
    final docRef = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'content': encryptedContent,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'isEdited': false,
        });

    // Update last message in chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': encryptedContent, // Also store encrypted here
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageId': docRef.id,
      'lastMessageIsEdited': false,
      'unreadCountCandidate': FieldValue.increment(1),
    });
  }

  /// Stream messages for a chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return MessageModel.fromMap(data);
          }).toList();
        });
  }

  /// Get chats for the current recruiter
  Stream<List<ChatModel>> getRecruiterChats() {
    final recruiterId = _auth.currentUser?.uid;
    if (recruiterId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('recruiterId', isEqualTo: recruiterId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Mark chat as read for recruiter
  Future<void> markAsRead(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCountRecruiter': 0,
    });
  }

  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    // Delete messages subcollection
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    for (var doc in messages.docs) {
      await doc.reference.delete();
    }

    // Delete chat document
    await _firestore.collection('chats').doc(chatId).delete();
  }

  /// Edit a message
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newContent,
  }) async {
    final senderId = _auth.currentUser?.uid ?? '';
    if (senderId.isEmpty) return;

    final encryptedContent = EncryptionHelper.encryptMessage(newContent);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'content': encryptedContent,
          'isEdited': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    // Robust Sync: Check if the edited message is the *current* latest message in the subcollection.
    // This handles cases where chatDoc.lastMessageId might be null/outdated.
    final latestMsgQuery = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (latestMsgQuery.docs.isNotEmpty) {
      final latestMsg = latestMsgQuery.docs.first;
      if (latestMsg.id == messageId) {
        // The edited message is the latest one, update chat summary
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': encryptedContent,
          'lastMessageId': messageId,
          'lastMessageIsEdited': true,
          // 'lastMessageTime': ... We typically preserve the original timestamp or update updateAt
        });
      }
    }
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final senderId = _auth.currentUser?.uid ?? '';
    if (senderId.isEmpty) return;

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();

    // Robust Sync: Always fetch the new latest message and update the chat doc.
    // This ensures self-healing if the state was previously desynchronized.
    final messagesQuery = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (messagesQuery.docs.isNotEmpty) {
      final lastMsg = messagesQuery.docs.first;
      // Always update to match the true latest message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': lastMsg['content'],
        'lastMessageTime': lastMsg['timestamp'],
        'lastMessageId': lastMsg.id,
        'lastMessageIsEdited': lastMsg['isEdited'] ?? false,
      });
    } else {
      // No messages left
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageId': '',
        'lastMessageIsEdited': false,
      });
    }
  }
}
