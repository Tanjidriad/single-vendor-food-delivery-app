import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/websockets/socket_service.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../data/chat_message.dart';
import '../../data/chat_repository.dart';

/// Bottom sheet for messaging the customer during an active delivery.
///
/// Loads history, appends live socket messages for [orderId], and sends new
/// messages via the [chatRepositoryProvider].
class DeliveryChatSheet extends ConsumerStatefulWidget {
  const DeliveryChatSheet({
    super.key,
    required this.orderId,
    required this.customerName,
  });

  final String orderId;
  final String customerName;

  @override
  ConsumerState<DeliveryChatSheet> createState() => _DeliveryChatSheetState();
}

class _DeliveryChatSheetState extends ConsumerState<DeliveryChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final msgs =
          await ref.read(chatRepositoryProvider).listMessages(widget.orderId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load messages.';
      });
    }
  }

  void _ingest(Map<String, dynamic> data) {
    if (data['orderId']?.toString() != widget.orderId) return;
    final msg = ChatMessage.fromJson(data);
    if (msg.id.isEmpty || _messages.any((m) => m.id == msg.id)) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent =
          await ref.read(chatRepositoryProvider).sendMessage(widget.orderId, text);
      _controller.clear();
      if (sent != null && !_messages.any((m) => m.id == sent.id)) {
        setState(() => _messages.add(sent));
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message failed to send'),
            backgroundColor: AppColors.offline,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Append live incoming messages for this order.
    ref.listen(orderMessageStreamProvider, (prev, next) {
      final data = next.value;
      if (data != null) _ingest(data);
    });

    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const BottomSheetHandle(),
              const SizedBox(height: AppSpacing.sm),
              _header(),
              const Divider(height: AppSpacing.xl),
              Expanded(child: _messageList()),
              const SizedBox(height: AppSpacing.sm),
              _quickReplies(),
              const SizedBox(height: AppSpacing.sm),
              _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.inProgress.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.messageSquare, color: AppColors.inProgress),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            widget.customerName.isEmpty ? 'Customer' : widget.customerName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _messageList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet. Say hello 👋',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) => _Bubble(message: _messages[index]),
    );
  }

  Widget _quickReplies() {
    const replies = ['On my way', "I've arrived", 'Running late'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final reply in replies)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ActionChip(
                label: Text(reply),
                backgroundColor: AppColors.surfaceElevated,
                side: const BorderSide(color: AppColors.borderLight),
                onPressed: _sending
                    ? null
                    : () {
                        _controller.text = reply;
                        _send();
                      },
              ),
            ),
        ],
      ),
    );
  }

  Widget _composer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: const InputDecoration(
              hintText: 'Message the customer…',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filled(
          onPressed: _sending ? null : _send,
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.send),
        ),
      ],
    );
  }
}

/// A single chat bubble — rider messages align right (brand), others left.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isFromRider;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          message.body,
          style: TextStyle(
            color: mine ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
