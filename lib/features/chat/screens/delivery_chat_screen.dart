import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../global/base_url.dart';
import '../../../shared/colors/app_colors.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

/// Real-time chat for a single delivery, shared by customer and driver.
/// Loads history over REST, then streams live messages over socket.io.
class DeliveryChatScreen extends StatefulWidget {
  final String packageId;
  final String currentUserId;
  final String peerName;

  const DeliveryChatScreen({
    super.key,
    required this.packageId,
    required this.currentUserId,
    required this.peerName,
  });

  @override
  State<DeliveryChatScreen> createState() => _DeliveryChatScreenState();
}

class _DeliveryChatScreenState extends State<DeliveryChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  final Set<String> _seenIds = {}; // server ids already rendered (de-dupe)

  io.Socket? _socket;
  bool _loading = true;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // 1) Load history
    try {
      final history = await _chatService.getHistory(widget.packageId, token);
      if (mounted) {
        setState(() {
          _messages.addAll(history);
          _seenIds.addAll(history.map((m) => m.id));
        });
      }
    } catch (e) {
      debugPrint('chat history error: $e');
    }
    if (mounted) setState(() => _loading = false);
    _scrollToBottom();

    // 2) Connect socket + join the delivery room
    final socket = io.io(
      '$socketBaseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      if (mounted) setState(() => _connected = true);
      socket.emit('room:join', {'packageId': widget.packageId});
    });
    socket.onDisconnect((_) {
      if (mounted) setState(() => _connected = false);
    });
    socket.on('chat:message', (data) {
      if (data is! Map) return;
      final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data));
      if (msg.packageId != widget.packageId) return;
      if (_seenIds.contains(msg.id)) return; // already rendered
      if (!mounted) return;
      setState(() {
        _seenIds.add(msg.id);
        // If this is the server echo of a message we sent optimistically,
        // replace the local placeholder instead of adding a duplicate.
        if (msg.senderId == widget.currentUserId) {
          final i = _messages.indexWhere(
            (m) => m.id.startsWith('local-') && m.text == msg.text,
          );
          if (i != -1) {
            _messages[i] = msg;
            return;
          }
        }
        _messages.add(msg);
      });
      _scrollToBottom();
    });

    socket.connect();
    _socket = socket;
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _socket == null) return;
    // Render immediately (optimistic); the server echo will reconcile this
    // placeholder via its `local-` id in the chat:message handler.
    setState(() {
      _messages.add(ChatMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        packageId: widget.packageId,
        senderId: widget.currentUserId,
        text: text,
        createdAt: DateTime.now(),
      ));
    });
    _socket!.emit('chat:message', {'packageId': widget.packageId, 'text': text});
    _inputCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socket?.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FB),
      appBar: AppBar(
        backgroundColor: AppColors.blueDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text(_connected ? 'online' : 'connecting…',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.blue))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('មិនទាន់មានសារនៅឡើយទេ',
                            style: TextStyle(color: Color(0xFF8BA4C8))))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _Bubble(
                          message: _messages[i],
                          isMe: _messages[i].senderId == widget.currentUserId,
                        ),
                      ),
          ),
          _InputBar(controller: _inputCtrl, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _Bubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: isMe ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FB),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: 'សរសេរសារ...',
                    hintStyle: TextStyle(color: Color(0xFFB0BEC5)),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.blue),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
