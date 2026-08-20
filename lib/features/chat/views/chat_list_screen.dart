import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../../candidates/repositories/candidate_repository.dart';
import '../../jobs/repositories/job_repository.dart';
import 'chat_screen.dart';
import 'package:recruiter_talentbay/features/auth/controllers/auth_controller.dart';
import 'package:recruiter_talentbay/features/subscription/views/subscription_screen.dart';
import '../../../theme/app_colors.dart';

// Providers for fetching details
final chatListProvider = StreamProvider<List<ChatModel>>((ref) {
  return ref.watch(chatRepositoryProvider).getRecruiterChats();
});

final candidateDetailsProvider = FutureProvider.family<String, String>((
  ref,
  candidateId,
) async {
  final repo = ref.watch(candidateRepositoryProvider);
  final candidate = await repo.getCandidate(candidateId);
  return candidate?.fullName ?? 'Unknown Candidate';
});

final jobDetailsProvider = FutureProvider.family<String, String>((
  ref,
  jobId,
) async {
  final repo = ref.watch(jobRepositoryProvider);
  final job = await repo.getJob(jobId);
  return job?.roleName ?? 'Unknown Job';
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      // appBar: AppBar(
      //   title: Text(
      //     'MESSAGES',
      //     style: theme.textTheme.labelLarge?.copyWith(
      //       fontWeight: FontWeight.bold,
      //       letterSpacing: 1.2,
      //     ),
      //   ),
      //   centerTitle: true,
      //   backgroundColor: colorScheme.background,
      //   elevation: 0,
      // ),
      body: chatsAsync.when(
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: AppColors.textSubLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NO MESSAGES YET',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.textSubLight,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            );
          }
          final isDark = theme.brightness == Brightness.dark;
          return ListView.separated(
            padding: const EdgeInsets.all(0),
            itemCount: chats.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatListItem(chat: chat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class ChatListItem extends ConsumerWidget {
  final ChatModel chat;

  const ChatListItem({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candidateNameAsync = ref.watch(
      candidateDetailsProvider(chat.candidateId),
    );
    final jobTitleAsync = ref.watch(jobDetailsProvider(chat.jobId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSubColor = isDark
        ? AppColors.textSubDark
        : AppColors.textSubLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return InkWell(
      onTap: () {
        final user = ref.read(authControllerProvider.notifier).currentUser;
        if (user != null) {
          final recruiter = ref.read(recruiterProfileProvider(user.uid)).value;
          final isSubscribed = recruiter?.isSubscribed == true && 
              (recruiter?.subscriptionExpiry == null || !recruiter!.subscriptionExpiry!.isBefore(DateTime.now()));
          if (!isSubscribed) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
            return;
          }
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.id,
              otherUserId: chat.candidateId,
              candidateName: candidateNameAsync.asData?.value ?? 'Candidate',
              jobTitle: jobTitleAsync.asData?.value ?? '',
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.person, color: theme.colorScheme.onSurface),
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
                        child: candidateNameAsync.when(
                          data: (name) => Text(
                            name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => Text(
                            'Loading...',
                            style: TextStyle(color: textSubColor),
                          ),
                          error: (_, __) => const Text('Unknown'),
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: chat.unreadCount > 0
                              ? AppColors.tealPrimary
                              : textSubColor,
                          fontWeight: chat.unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.decryptedLastMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textSubColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.tealPrimary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          child: Center(
                            child: Text(
                              '${chat.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  jobTitleAsync.when(
                    data: (title) => Text(
                      title.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textSubColor.withOpacity(0.6),
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return DateFormat.jm().format(time);
    } else if (now.difference(time).inDays < 7) {
      return DateFormat.E().format(time);
    } else {
      return DateFormat.MMMd().format(time).toUpperCase();
    }
  }
}
