import 'package:flutter/material.dart';
import '../../../shared/colors/app_colors.dart';
import '../models/conversation.dart';
import 'delivery_chat_screen.dart';

/// A list of chattable deliveries. Reused by customer and driver —
/// the caller supplies the right loader and the current user's id.
class ConversationsScreen extends StatefulWidget {
  final String currentUserId;
  final Future<List<Conversation>> Function() loader;
  final bool showAppBar;

  const ConversationsScreen({
    super.key,
    required this.currentUserId,
    required this.loader,
    this.showAppBar = false,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  late Future<List<Conversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.loader());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _refresh,
      child: FutureBuilder<List<Conversation>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'មិនមានការសន្ទនាទេ',
                    style: TextStyle(color: Color(0xFF8BA4C8)),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFE3EAF3)),
            itemBuilder: (_, i) => _ConversationTile(
              conversation: items[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeliveryChatScreen(
                    packageId: items[i].packageId,
                    currentUserId: widget.currentUserId,
                    peerName: items[i].peerName,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (!widget.showAppBar) return body;
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ការឆ្លើយឆ្លង',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: body,
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(
        backgroundColor: AppColors.softBlue,
        child: Icon(Icons.local_shipping_rounded, color: AppColors.blue),
      ),
      title: Text(
        conversation.peerName,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      subtitle: Text(
        '${conversation.trackingNumber} • ${_conversationStatusKhmer(conversation.status)}',
        style: const TextStyle(fontSize: 12, color: Color(0xFF8BA4C8)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFB0BEC5)),
    );
  }
}

String _conversationStatusKhmer(String status) {
  return switch (status.toUpperCase()) {
    'PENDING' || 'SEARCHING' => 'កំពុងរង់ចាំ',
    'ACCEPTED' => 'បានទទួលយក',
    'ARRIVED_AT_PICKUP' => 'បានមកដល់ទីតាំងទទួល',
    'IN_TRANSIT' => 'កំពុងដឹកជញ្ជូន',
    'ARRIVED_AT_DROPOFF' => 'បានមកដល់ទីតាំងប្រគល់',
    'DELIVERED' || 'COMPLETED' => 'បានដឹកជញ្ជូន',
    'CANCELLED' || 'CANCELED' => 'បានបោះបង់',
    'FAILED' => 'មិនបានសម្រេច',
    _ => 'កំពុងដំណើរការ',
  };
}
