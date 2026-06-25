import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/orders_repository.dart';

/// In-app chat thread between the customer and the assigned rider for an order.
///
/// Loads history from `GET /orders/:id/messages`, posts via `POST`, and appends
/// live messages from the `order:message` socket event. Customer-authored
/// messages align right; the rider's align left.
class OrderChatSheet extends ConsumerStatefulWidget {
  const OrderChatSheet({
    super.key,
    required this.orderId,
    required this.riderName,
  });

  final String orderId;
  final String riderName;

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String riderName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderChatSheet(orderId: orderId, riderName: riderName),
    );
  }

  @override
  ConsumerState<OrderChatSheet> createState() => _OrderChatSheetState();
}

class _OrderChatSheetState extends ConsumerState<OrderChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // The tracking screen already connected the socket and joined the order
    // room; just listen for incoming messages here.
    ref.read(socketServiceProvider).onOrderMessage(_ingest);
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).offOrderMessage();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final raw =
          await ref.read(ordersRepositoryProvider).listMessages(widget.orderId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
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
    final id = data['id']?.toString();
    if (id == null || _messages.any((m) => m['id']?.toString() == id)) return;
    if (!mounted) return;
    setState(() => _messages.add(data));
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent =
          await ref.read(ordersRepositoryProvider).sendMessage(widget.orderId, text);
      _controller.clear();
      final id = sent['id']?.toString();
      if (id != null && !_messages.any((m) => m['id']?.toString() == id)) {
        setState(() => _messages.add(sent));
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message failed to send')),
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
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.72,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.riderName.isEmpty ? 'Your rider' : widget.riderName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const Divider(),
              Expanded(child: _messageList()),
              const SizedBox(height: 8),
              _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Color(0xFF6B7280))),
      );
    }
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet. Say hello 👋',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final m = _messages[index];
        final mine = m['senderRole']?.toString() == 'CUSTOMER';
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.72,
            ),
            decoration: BoxDecoration(
              color: mine ? AppColors.primary : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              m['body']?.toString() ?? '',
              style: TextStyle(
                color: mine ? Colors.white : const Color(0xFF111827),
                fontSize: 15,
              ),
            ),
          ),
        );
      },
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
            decoration: InputDecoration(
              hintText: 'Message your rider…',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _sending ? null : _send,
          style: IconButton.styleFrom(backgroundColor: AppColors.primary),
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send, color: Colors.white),
        ),
      ],
    );
  }
}
