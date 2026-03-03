import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/club_provider.dart';
import '../../../core/services/firebase_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String clubId;

  const ChatScreen({super.key, required this.clubId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isPromptMode = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatNotifierProvider.notifier).sendMessage(
          clubId: widget.clubId,
          content: text,
        );
    _messageController.clear();
  }

  void _submitPrompt(bool isAdmin) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatNotifierProvider.notifier).submitPrompt(
          clubId: widget.clubId,
          content: text,
          isAdmin: isAdmin,
        );
    _messageController.clear();
    setState(() => _isPromptMode = false);

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt submitted for admin approval')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showReplySheet(BuildContext context, ChatMessage prompt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => _ReplyThreadSheet(
          clubId: widget.clubId,
          prompt: prompt,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showPendingPromptsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PendingPromptsSheet(clubId: widget.clubId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(clubMessagesProvider(widget.clubId));
    final membersAsync =
        ref.watch(clubMemberProfilesProvider(widget.clubId));
    final memberAsync = ref.watch(currentUserMemberProvider(widget.clubId));
    final currentUserId = FirebaseService.currentUserId;
    final isAdmin = memberAsync.valueOrNull?.isAdmin ?? false;

    // Scroll to bottom when new messages arrive.
    ref.listen(clubMessagesProvider(widget.clubId), (prev, next) {
      final prevCount = prev?.valueOrNull?.length ?? 0;
      final nextCount = next.valueOrNull?.length ?? 0;
      if (nextCount > prevCount) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Chat'),
        actions: [
          // Pending prompts badge (admin only)
          if (isAdmin)
            _PendingPromptsBadge(
              clubId: widget.clubId,
              onTap: () => _showPendingPromptsSheet(context),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: membersAsync.when(
              data: (profiles) => Row(
                children: [
                  for (final profile in profiles.values.take(3))
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    '${profiles.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error loading messages: $error'),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No messages yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }

                final profiles = membersAsync.valueOrNull ?? {};

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    // Discussion prompt card
                    if (message.isPrompt) {
                      return _DiscussionPromptCard(
                        message: message,
                        senderProfile: message.userId != null
                            ? profiles[message.userId]
                            : null,
                        onRespond: () =>
                            _showReplySheet(context, message),
                      );
                    }

                    // Regular message bubble
                    final isMe = message.userId == currentUserId;
                    final showSender = !isMe &&
                        !message.isSystemMessage &&
                        (index == 0 ||
                            messages[index - 1].userId !=
                                message.userId);

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      showSender: showSender,
                      senderProfile: message.userId != null
                          ? profiles[message.userId]
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // Prompt mode banner
          if (_isPromptMode)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(Icons.question_answer,
                      size: 14,
                      color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAdmin
                          ? 'Posting a discussion prompt'
                          : 'Proposing a prompt (admin approval needed)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isPromptMode = false),
                    child: Icon(Icons.close,
                        size: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Prompt toggle button
                  IconButton(
                    onPressed: () =>
                        setState(() => _isPromptMode = !_isPromptMode),
                    icon: Icon(
                      _isPromptMode
                          ? Icons.chat_bubble
                          : Icons.question_answer,
                      color: _isPromptMode
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.grey[500],
                      size: 22,
                    ),
                    tooltip: _isPromptMode
                        ? 'Switch to message'
                        : 'Post a discussion prompt',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: _isPromptMode
                            ? 'Write a discussion prompt...'
                            : 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _isPromptMode
                          ? _submitPrompt(isAdmin)
                          : _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isPromptMode
                        ? () => _submitPrompt(isAdmin)
                        : _sendMessage,
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Discussion Prompt Card ─────────────────────────────────────────

class _DiscussionPromptCard extends StatelessWidget {
  final ChatMessage message;
  final UserProfile? senderProfile;
  final VoidCallback onRespond;

  const _DiscussionPromptCard({
    required this.message,
    this.senderProfile,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = message.isPendingPrompt;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(Icons.question_answer,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 6),
                Text(
                  'Discussion Prompt',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.secondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                if (isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            // Sender name
            if (senderProfile != null) ...[
              const SizedBox(height: 4),
              Text(
                senderProfile!.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Prompt content
            Text(
              message.content,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Footer: reply count + respond button
            Row(
              children: [
                if (message.replyCount > 0) ...[
                  Icon(Icons.chat_bubble_outline,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${message.replyCount} ${message.replyCount == 1 ? 'response' : 'responses'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
                const Spacer(),
                if (!isPending)
                  TextButton.icon(
                    onPressed: onRespond,
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Respond'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reply Thread Bottom Sheet ──────────────────────────────────────

class _ReplyThreadSheet extends ConsumerStatefulWidget {
  final String clubId;
  final ChatMessage prompt;
  final ScrollController scrollController;

  const _ReplyThreadSheet({
    required this.clubId,
    required this.prompt,
    required this.scrollController,
  });

  @override
  ConsumerState<_ReplyThreadSheet> createState() => _ReplyThreadSheetState();
}

class _ReplyThreadSheetState extends ConsumerState<_ReplyThreadSheet> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    ref.read(chatNotifierProvider.notifier).sendReply(
          clubId: widget.clubId,
          promptId: widget.prompt.id,
          content: text,
        );
    _replyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final repliesAsync = ref.watch(promptRepliesProvider(
      (clubId: widget.clubId, promptId: widget.prompt.id),
    ));
    final profiles =
        ref.watch(clubMemberProfilesProvider(widget.clubId)).valueOrNull ??
            {};

    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Pinned prompt header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.question_answer,
                      size: 14,
                      color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Discussion Prompt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.prompt.content,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Divider(height: 24),
            ],
          ),
        ),
        // Reply list
        Expanded(
          child: repliesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (replies) {
              if (replies.isEmpty) {
                return Center(
                  child: Text(
                    'No responses yet. Be the first!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }
              return ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: replies.length,
                itemBuilder: (context, index) {
                  final reply = replies[index];
                  final profile = profiles[reply.userId];
                  return _ReplyBubble(reply: reply, profile: profile);
                },
              );
            },
          ),
        ),
        // Reply input bar
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Write a response...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendReply,
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reply Bubble ───────────────────────────────────────────────────

class _ReplyBubble extends StatelessWidget {
  final ChatMessage reply;
  final UserProfile? profile;

  const _ReplyBubble({required this.reply, this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.1),
            backgroundImage: profile?.avatarUrl != null
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: profile?.avatarUrl == null
                ? Text(
                    profile?.displayName.isNotEmpty == true
                        ? profile!.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.displayName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reply.content,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending Prompts Badge (AppBar) ─────────────────────────────────

class _PendingPromptsBadge extends ConsumerWidget {
  final String clubId;
  final VoidCallback onTap;

  const _PendingPromptsBadge({required this.clubId, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPromptsProvider(clubId));
    final count = pendingAsync.valueOrNull?.length ?? 0;

    if (count == 0) return const SizedBox.shrink();

    return IconButton(
      onPressed: onTap,
      icon: Badge(
        label: Text('$count'),
        child: const Icon(Icons.question_answer_outlined),
      ),
    );
  }
}

// ── Pending Prompts Review Sheet ───────────────────────────────────

class _PendingPromptsSheet extends ConsumerWidget {
  final String clubId;

  const _PendingPromptsSheet({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPromptsProvider(clubId));
    final profiles =
        ref.watch(clubMemberProfilesProvider(clubId)).valueOrNull ?? {};

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Pending Discussion Prompts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          pendingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
            data: (prompts) {
              if (prompts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No pending prompts',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                itemCount: prompts.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1),
                itemBuilder: (context, index) {
                  final prompt = prompts[index];
                  final profile = profiles[prompt.userId];
                  return ListTile(
                    title: Text(
                      prompt.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'by ${profile?.displayName ?? 'Unknown'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          tooltip: 'Approve',
                          onPressed: () {
                            ref
                                .read(chatNotifierProvider.notifier)
                                .approvePrompt(
                                  clubId: clubId,
                                  messageId: prompt.id,
                                );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.cancel,
                              color: Colors.red[400]),
                          tooltip: 'Dismiss',
                          onPressed: () {
                            ref
                                .read(chatNotifierProvider.notifier)
                                .dismissPrompt(
                                  clubId: clubId,
                                  messageId: prompt.id,
                                );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Message Bubble (existing, unchanged) ───────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSender;
  final UserProfile? senderProfile;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showSender,
    this.senderProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            message.content,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final senderName = senderProfile?.displayName ?? 'Unknown';
    final time = _formatTime(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(
        top: showSender ? 12 : 2,
        bottom: 2,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSender)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }
}
