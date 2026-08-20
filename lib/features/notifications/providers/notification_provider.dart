import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../chat/repositories/chat_repository.dart';
import '../../jobs/repositories/job_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../../../core/services/notification_controller.dart';

final readApplicationsProvider = NotifierProvider<ReadApplicationsNotifier, Set<String>>(() {
  return ReadApplicationsNotifier();
});

class ReadApplicationsNotifier extends Notifier<Set<String>> {
  static const _key = 'read_applications';

  @override
  Set<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  void markAsRead(String id) {
    if (state.contains(id)) return;
    final newSet = {...state, id};
    state = newSet;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setStringList(_key, newSet.toList());
  }
}

final _chatsStreamProvider = StreamProvider((ref) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.getRecruiterChats();
});

final _jobsStreamProvider = StreamProvider.family((ref, String companyId) {
  final jobRepo = ref.watch(jobRepositoryProvider);
  return jobRepo.getJobsStream(companyId);
});

final _notifStreamProvider = StreamProvider.family((ref, String userId) {
  final notifRepo = ref.watch(notificationRepositoryProvider);
  return notifRepo.getNotificationsStream(userId);
});

final _jobAppsStreamProvider = StreamProvider.family((ref, String jobId) {
  final jobRepo = ref.watch(jobRepositoryProvider);
  return jobRepo.getApplicationsStream(jobId);
});

final notificationsListProvider = Provider<AsyncValue<List<NotificationModel>>>((ref) {
  final user = ref.watch(authControllerProvider.notifier).currentUser;
  if (user == null) return const AsyncData([]);

  final profileAsync = ref.watch(recruiterProfileProvider(user.uid));
  if (profileAsync is! AsyncData || profileAsync.value == null) return const AsyncLoading();
  
  final companyId = profileAsync.value!.companyId;

  // Watch streams using global providers properly
  final chatsAsync = ref.watch(_chatsStreamProvider);
  final jobsAsync = ref.watch(_jobsStreamProvider(companyId));
  final notifStreamAsync = ref.watch(_notifStreamProvider(user.uid));
  
  List<NotificationModel> notifications = [];

  // Add Firebase Notifications
  if (notifStreamAsync is AsyncData) {
    notifications.addAll(notifStreamAsync.value ?? []);
  }

  // Add Chat Notifications
  if (chatsAsync is AsyncData) {
    for (final chat in chatsAsync.value ?? []) {
      if (chat.lastMessageTime != null && chat.lastMessageTime.year > 2000) {
        if (!notifications.any((n) => n.payloadId == chat.id && n.type == NotificationType.message)) {
          notifications.add(NotificationModel(
            id: chat.id,
            type: NotificationType.message,
            title: 'New Message',
            content: chat.decryptedLastMessage.isEmpty ? 'You have a message' : chat.decryptedLastMessage,
            timestamp: chat.lastMessageTime,
            isRead: chat.unreadCount == 0,
            payloadId: chat.id,
            jobId: chat.jobId,
            candidateId: chat.candidateId,
          ));
        }
      }
    }
  }

  // Add Job Application Notifications
  final readApps = ref.watch(readApplicationsProvider);

  if (jobsAsync is AsyncData && jobsAsync.value != null) {
    final activeJobs = jobsAsync.value!.where((j) => j.status == 'active').toList();
    for (final job in activeJobs) {
      final appsAsync = ref.watch(_jobAppsStreamProvider(job.jobId));
      if (appsAsync is AsyncData) {
        for (final app in appsAsync.value ?? []) {
          if (app.applicationStatus == 'applied' || app.applicationStatus == 'invited') {
             if (!notifications.any((n) => n.payloadId == app.candidateId && n.jobId == job.jobId)) {
                notifications.add(NotificationModel(
                  id: app.applicationId,
                  type: NotificationType.application,
                  title: app.applicationStatus == 'applied' ? 'New Applicant' : 'New Match',
                  content: 'A candidate has ${app.applicationStatus == 'applied' ? 'applied' : 'been matched'} for ${job.roleName}.',
                  timestamp: app.appliedAt,
                  isRead: readApps.contains(app.applicationId),
                  payloadId: app.candidateId,
                  jobId: job.jobId,
                  candidateId: app.candidateId,
                  jobTitle: job.roleName,
                ));
             }
          }
        }
      }
    }
  }

  // Sort descending by date
  notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  
  return AsyncData(notifications);
});
