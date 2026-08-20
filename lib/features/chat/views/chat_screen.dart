import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../subscription/views/subscription_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;
  final String candidateName; // Passed for display
  final String jobTitle; // Passed for display

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    this.candidateName = 'Candidate',
    this.jobTitle = '',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    ref.read(chatRepositoryProvider).markAsRead(widget.chatId);
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final repo = ref.read(chatRepositoryProvider);

    if (_editingMessageId != null) {
      repo.editMessage(
        chatId: widget.chatId,
        messageId: _editingMessageId!,
        newContent: content,
      );
      setState(() {
        _editingMessageId = null;
      });
    } else {
      repo.sendMessage(chatId: widget.chatId, content: content);
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // Reversed list
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    _messageController.clear();
  }

  void _handleMessageAction(MessageModel message) {
    // Only allow editing/deleting own messages
    if (message.senderId == widget.otherUserId) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Message'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _editingMessageId = message.id;
                _messageController.text = message.decryptedContent;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text(
              'Delete Message',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(context);
              _deleteMessage(message.id);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('DELETE MESSAGE'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(chatRepositoryProvider)
          .deleteMessage(chatId: widget.chatId, messageId: messageId);

      // If we were editing this message, clear the state
      if (_editingMessageId == messageId) {
        setState(() {
          _editingMessageId = null;
          _messageController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authControllerProvider.notifier).currentUser;
    final recruiterAsync = ref.watch(recruiterProfileProvider(user?.uid ?? ''));

    final isSubscribed = recruiterAsync.when(
      data: (data) => data?.isSubscribed ?? false,
      error: (_, __) => false,
      loading: () => false,
    );

    final messagesStream = ref
        .watch(chatRepositoryProvider)
        .getMessages(widget.chatId);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.candidateName.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            if (widget.jobTitle.isNotEmpty)
              Text(
                widget.jobTitle.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: AppColors.textSubLight,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
        backgroundColor: colorScheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'START THE CONVERSATION',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSubLight,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMyMessage = message.senderId != widget.otherUserId;

                    return GestureDetector(
                      onLongPress: () => _handleMessageAction(message),
                      child: Align(
                        alignment: isMyMessage
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMyMessage
                                ? colorScheme
                                      .primary // Pantone 320C
                                : colorScheme.surface,
                            border: isMyMessage
                                ? null
                                : Border.all(color: AppColors.borderLight),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isMyMessage
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                              bottomRight: isMyMessage
                                  ? Radius.zero
                                  : const Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.decryptedContent,
                                style: TextStyle(
                                  color: isMyMessage
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              if (message.isEdited)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),

                                  // child: Text(
                                  //   'EDITED',
                                  //   style: TextStyle(
                                  //     fontSize: 10,
                                  //     color: isMyMessage
                                  //         ? colorScheme.onPrimary.withOpacity(
                                  //             0.7,
                                  //           )
                                  //         : AppColors.textSubLight,
                                  //     fontStyle: FontStyle.italic,
                                  //   ),
                                  // ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (!isSubscribed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: AppColors.textSubLight,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unlock Messaging',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upgrade to Premium to chat with candidates directly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSubLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('UPGRADE NOW'),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.background,
                border: const Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'TYPE A MESSAGE...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubLight,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: AppColors.borderLight),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_editingMessageId != null)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _editingMessageId = null;
                          _messageController.clear();
                        });
                      },
                      icon: const Icon(Icons.close),
                      color: AppColors.textSubLight,
                    ),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(
                        _editingMessageId != null ? Icons.check : Icons.send,
                        size: 20,
                      ),
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
