import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/chat/repositories/chat_repository.dart';
import '../../features/jobs/repositories/job_repository.dart';
import '../../features/chat/models/chat_model.dart';
import '../../features/jobs/models/job_application_model.dart';
import 'local_notification_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart');
});

final fcmTokenUpdaterProvider = Provider<void>((ref) {
  final user = ref.watch(authControllerProvider.notifier).currentUser;
  if (user != null) {
    try {
      () async {
        try {
          await FirebaseMessaging.instance.getAPNSToken();
        } catch (_) {}
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            ref.read(authRepositoryProvider).updateRecruiterProfile(user.uid, {'fcmToken': token});
          }
        } catch (_) {}
      }();

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        ref.read(authRepositoryProvider).updateRecruiterProfile(user.uid, {'fcmToken': token});
      });
    } catch (e) {
      // Ignore
    }
  }
});

final notificationsEnabledProvider = NotifierProvider<NotificationsEnabledNotifier, bool>(() {
  return NotificationsEnabledNotifier();
});

class NotificationsEnabledNotifier extends Notifier<bool> {
  static const _key = 'notifications_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, value);
    if (value) {
      await LocalNotificationService.requestPermissions();
    }
  }
}

class SeenChatsNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => {};
  void updateSeen(Map<String, DateTime> newSeen) => state = newSeen;
}
final seenChatsProvider = NotifierProvider<SeenChatsNotifier, Map<String, DateTime>>(() => SeenChatsNotifier());

class SeenAppsNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => {};
  void updateSeen(Map<String, DateTime> newSeen) => state = newSeen;
}
final seenAppsProvider = NotifierProvider<SeenAppsNotifier, Map<String, DateTime>>(() => SeenAppsNotifier());

// A simple provider that we can "watch" at the root level to keep listeners active
final notificationListenerProvider = Provider<void>((ref) {
  final enabled = ref.watch(notificationsEnabledProvider);
  if (!enabled) return;

  final user = ref.watch(authControllerProvider.notifier).currentUser;
  if (user == null) return;

  final profileAsync = ref.watch(recruiterProfileProvider(user.uid));
  if (profileAsync is! AsyncData || profileAsync.value == null) return;
  final companyId = profileAsync.value!.companyId;

  // Listen to chats
  final chatRepo = ref.watch(chatRepositoryProvider);
  ref.listen<AsyncValue<List<ChatModel>>>(
    StreamProvider((_) => chatRepo.getRecruiterChats()),
    (previous, next) {
      if (next is AsyncData && next.value != null) {
        final chats = next.value!;
        final seen = ref.read(seenChatsProvider);
        bool updated = false;

        for (final chat in chats) {
          final lastSeen = seen[chat.id];
          if (chat.unreadCount > 0 && 
              (lastSeen == null || chat.lastMessageTime.isAfter(lastSeen))) {
            // Unread message
            seen[chat.id] = chat.lastMessageTime;
            updated = true;

            // Only notify if it's very recent (within 1 minute) to avoid spamming old unread messages on login
            if (DateTime.now().difference(chat.lastMessageTime).inSeconds < 60) {
              LocalNotificationService.showMessageNotification(
                id: chat.id.hashCode,
                title: 'New Message',
                body: chat.decryptedLastMessage.isEmpty ? 'You have a new message' : chat.decryptedLastMessage,
                payload: '/chat/${chat.id}',
              );
            }
          } else if (chat.unreadCount == 0 && lastSeen != chat.lastMessageTime) {
             seen[chat.id] = chat.lastMessageTime;
             updated = true;
          }
        }
        if (updated) ref.read(seenChatsProvider.notifier).updateSeen(Map.from(seen));
      }
    },
  );

  // Listen to active jobs
  final jobRepo = ref.watch(jobRepositoryProvider);
  final jobsAsync = ref.watch(StreamProvider((_) => jobRepo.getJobsStream(companyId)));
  
  if (jobsAsync is AsyncData && jobsAsync.value != null) {
    final activeJobs = jobsAsync.value!.where((j) => j.status == 'active').toList();
    
    // For each active job, listen to its applications
    for (final job in activeJobs) {
      ref.listen<AsyncValue<List<JobApplicationModel>>>(
        StreamProvider((_) => jobRepo.getApplicationsStream(job.jobId)),
        (previous, next) {
          if (next is AsyncData && next.value != null) {
            final apps = next.value!;
            final seenApps = ref.read(seenAppsProvider);
            bool updatedApps = false;

            for (final app in apps) {
              final lastSeen = seenApps[app.applicationId];
              if (app.applicationStatus == 'applied' || app.applicationStatus == 'invited') {
                if (lastSeen == null || app.appliedAt.isAfter(lastSeen)) {
                  seenApps[app.applicationId] = app.appliedAt;
                  updatedApps = true;

                  if (DateTime.now().difference(app.appliedAt).inSeconds < 60) {
                    LocalNotificationService.showApplicationNotification(
                      id: app.applicationId.hashCode,
                      title: app.applicationStatus == 'applied' ? 'New Applicant' : 'New Match',
                      body: 'A candidate has ${app.applicationStatus == 'applied' ? 'applied' : 'been matched'} for ${job.roleName}.',
                    );
                  }
                }
              }
            }
            if (updatedApps) ref.read(seenAppsProvider.notifier).updateSeen(Map.from(seenApps));
          }
        },
      );
    }
  }
});
