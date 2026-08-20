import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../../candidates/repositories/candidate_repository.dart';
import '../../candidates/models/candidate_model.dart';
import '../../jobs/repositories/job_repository.dart';

final notificationCandidateProvider = FutureProvider.family<CandidateModel?, String>((ref, candidateId) async {
  final repo = ref.watch(candidateRepositoryProvider);
  return await repo.getCandidate(candidateId);
});

final notificationJobProvider = FutureProvider.family<String, String>((ref, jobId) async {
  final repo = ref.watch(jobRepositoryProvider);
  final job = await repo.getJob(jobId);
  return job?.roleName ?? '';
});

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            fontFamily: 'Didot',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: ['All', 'Unread', 'Read'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ChoiceChip(
                  label: Text(
                    f,
                    style: TextStyle(
                      letterSpacing: 1,
                      fontWeight: _filter == f ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: _filter == f,
                  onSelected: (val) {
                    if (val) setState(() => _filter = f);
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: _filter == f
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: const RoundedRectangleBorder(),
                ),
              )).toList(),
            ),
          ),
          
          Expanded(
            child: notificationsAsync.when(
              data: (allNotifs) {
                final notifications = allNotifs.where((n) {
                  if (_filter == 'Unread') return !n.isRead;
                  if (_filter == 'Read') return n.isRead;
                  return true;
                }).toList();

                if (notifications.isEmpty) {
                  return Center(
                    child: Text(
                      'NO ${_filter.toUpperCase()} NOTIFICATIONS',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _NotificationTile(notification: notif);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.isRead;
    
    final candidateAsync = notification.candidateId != null 
        ? ref.watch(notificationCandidateProvider(notification.candidateId!))
        : null;
        
    final jobTitleAsync = notification.jobId != null
        ? ref.watch(notificationJobProvider(notification.jobId!))
        : null;

    final candidateName = notification.candidateName ?? candidateAsync?.value?.fullName;
    final candidateImageUrl = notification.candidateImageUrl ?? candidateAsync?.value?.photoUrl;
    final jobTitle = notification.jobTitle ?? jobTitleAsync?.value ?? '';

    return InkWell(
      onTap: () {
        if (notification.type == NotificationType.application) {
          ref.read(readApplicationsProvider.notifier).markAsRead(notification.id);
          // If the payloadId is candidateId we can route to candidate details
        }
        
        if (notification.type == NotificationType.message && notification.payloadId != null) {
          // It might be a locally aggregated notification that doesn't exist in collection, 
          // but calling markAsRead is safe (will just print an error or do nothing).
          ref.read(notificationRepositoryProvider).markAsRead(notification.id);
          context.push('/chat/${notification.payloadId}', extra: {
            'otherUserId': notification.candidateId ?? '',
            'candidateName': candidateName ?? 'Candidate',
            'jobTitle': jobTitle,
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Theme.of(context).cardTheme.color,
          border: Border.all(
            color: isUnread
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.type == NotificationType.message && candidateImageUrl != null && candidateImageUrl.isNotEmpty)
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(candidateImageUrl),
              )
            else
              Icon(
                notification.type == NotificationType.message
                    ? Icons.chat_bubble_outline
                    : Icons.work_outline,
                color: isUnread
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.type == NotificationType.message && candidateName != null
                              ? 'Received message from $candidateName'.toUpperCase()
                              : notification.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1,
                            color: isUnread
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(notification.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnread
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 16),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
