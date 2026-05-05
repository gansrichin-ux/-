import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/chat_repository.dart';
import '../repositories/user_repository.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String cargoId;
  const ChatScreen({super.key, required this.cargoId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String _currentUserName = 'Пользователь';

  static const _bgColor = Color(0xFF0F172A);
  static const _surfaceColor = Color(0xFF1E293B);
  static const _myBubble = Color(0xFF1D4ED8);
  static const _theirBubble = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = await UserRepository.instance.getUser(_currentUserId);
    if (user != null && mounted) {
      setState(() => _currentUserName = user.displayName);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final message = MessageModel(
      id: '',
      text: text,
      senderId: _currentUserId,
      senderName: _currentUserName,
    );
    await ChatRepository.instance.sendMessage(widget.cargoId, message);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Чат по заявке'),
            Text(
              'Логист и водитель',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: ChatRepository.instance.watchMessages(widget.cargoId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Ошибка загрузки'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 56, color: Color(0xFF334155)),
                        const SizedBox(height: 12),
                        const Text(
                          'Пока нет сообщений',
                          style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Напишите первым!',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _currentUserId;
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      myBubbleColor: _myBubble,
                      theirBubbleColor: _theirBubble,
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _messageController,
            onSend: _sendMessage,
            surfaceColor: _surfaceColor,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final Color myBubbleColor;
  final Color theirBubbleColor;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.myBubbleColor,
    required this.theirBubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = message.timestamp != null
        ? DateFormat('HH:mm').format(message.timestamp!)
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? myBubbleColor : theirBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe
              ? null
              : Border.all(color: const Color(0xFF334155), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              message.text,
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeString,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Color surfaceColor;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        border:
            const Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Введите сообщение...',
                hintStyle:
                    const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
