import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../../../global/base_url.dart';
import '../../../shared/colors/app_colors.dart';
import '../../auth/tokens/token_storage.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
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

  MqttServerClient? _mqtt;
  String? _token;
  bool _loading = true;
  bool _connected = false;

  String get _messagesTopic => 'chonchoun/chat/${widget.packageId}/messages';
  String get _outboxTopic => 'chonchoun/chat/${widget.packageId}/outbox';

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
    _token = token;

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

    await _connectMqtt();
  }

  Future<void> _connectMqtt() async {
    final clientId =
        'app-${widget.currentUserId}-${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient.withPort(mqttHost, clientId, mqttPort);
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.autoReconnect = true;
    client.onConnected = () {
      if (mounted) setState(() => _connected = true);
      client.subscribe(_messagesTopic, MqttQos.atLeastOnce);
    };
    client.onDisconnected = () {
      if (mounted) setState(() => _connected = false);
    };
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    client.updates?.listen(_onMqttUpdates);

    try {
      await client.connect();
    } catch (e) {
      debugPrint('mqtt connect error: $e');
      client.disconnect();
      return;
    }
    _mqtt = client;
  }

  void _onMqttUpdates(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final event in events) {
      final recv = event.payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recv.payload.message);
      Map<String, dynamic> data;
      try {
        data = json.decode(payload) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final msg = ChatMessage.fromJson(data);
      if (msg.packageId != widget.packageId) continue;
      if (_seenIds.contains(msg.id)) continue;
      if (!mounted) return;
      setState(() {
        _seenIds.add(msg.id);
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
    }
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    final token = _token;
    if (text.isEmpty || _mqtt == null || token == null) return;
    if (_mqtt!.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }
    setState(() {
      _messages.add(ChatMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        packageId: widget.packageId,
        senderId: widget.currentUserId,
        text: text,
        createdAt: DateTime.now(),
      ));
    });
    final builder = MqttClientPayloadBuilder();
    builder.addString(json.encode({'token': token, 'text': text}));
    _mqtt!.publishMessage(_outboxTopic, MqttQos.atLeastOnce, builder.payload!);
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
    _mqtt?.disconnect();
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
