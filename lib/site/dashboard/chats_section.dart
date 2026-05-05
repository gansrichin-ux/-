part of '../../main_site.dart';

class ChatsSection extends StatefulWidget {
  final List<UserModel> users;
  final UserModel user;
  final UserModel? initialPeer;

  const ChatsSection({
    super.key,
    required this.users,
    required this.user,
    this.initialPeer,
  });

  @override
  State<ChatsSection> createState() => _ChatsSectionState();
}

class _ChatsSectionState extends State<ChatsSection> {
  UserModel? _selectedPeer;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedPeer = widget.initialPeer;
  }

  @override
  void didUpdateWidget(covariant ChatsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPeer?.uid != oldWidget.initialPeer?.uid) {
      _selectedPeer = widget.initialPeer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final peers = widget.users.where((user) {
      if (user.uid == widget.user.uid) return false;
      final query = _query.trim().toLowerCase().replaceFirst('@', '');
      if (query.isEmpty) return true;
      return user.displayName.toLowerCase().contains(query) ||
          user.displayUsername.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    if (peers.isEmpty) {
      return const Center(
        child: _StatePanel(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Нет собеседников',
          message: 'Когда появятся другие пользователи, диалоги будут здесь.',
        ),
      );
    }

    if (!isWide && _selectedPeer != null) {
      return _buildActiveChat(context, _selectedPeer!);
    }

    return Row(
      children: [
        SizedBox(
          width: isWide ? 340 : double.infinity,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.forum_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Чаты между пользователями',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Найти логиста или водителя',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: peers.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                  itemBuilder: (context, index) {
                    final peer = peers[index];
                    final isSelected = _selectedPeer?.uid == peer.uid;
                    return ListTile(
                      selected: isSelected,
                      leading: _ChatAvatar(user: peer),
                      title: Text(
                        peer.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${peer.displayUsername} · ${peer.displayRole}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _RatingStars(
                        value: peer.rating.round().clamp(0, 5).toInt(),
                      ),
                      onTap: () => setState(() => _selectedPeer = peer),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (isWide) ...[
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: _selectedPeer == null
                ? const Center(
                    child: _StatePanel(
                      icon: Icons.chat_outlined,
                      title: 'Выберите пользователя',
                      message: 'Откройте собеседника слева и начните диалог.',
                    ),
                  )
                : _buildActiveChat(context, _selectedPeer!),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveChat(BuildContext context, UserModel peer) {
    final colors = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final conversationId = ChatRepository.instance.directConversationId(
      widget.user.uid,
      peer.uid,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              if (!isWide)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _selectedPeer = null),
                ),
              _ChatAvatar(user: peer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peer.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${peer.displayUsername} · ${peer.displayRole}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Профиль',
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => context.push(
                  '/profile/${peer.profileSlug}/${ProfileSection.account.path}',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: ChatRepository.instance.watchDirectMessages(conversationId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: _StatePanel(
                    icon: Icons.error_outline_rounded,
                    title: 'Ошибка загрузки',
                    message: snapshot.error.toString(),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data ?? const <MessageModel>[];
              if (messages.isEmpty) {
                return const Center(
                  child: _StatePanel(
                    icon: Icons.mark_chat_unread_outlined,
                    title: 'Сообщений пока нет',
                    message: 'Напишите первым или отправьте фото из файлов.',
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message.senderId == widget.user.uid;
                  return _SiteMessageBubble(message: message, isMe: isMe);
                },
              );
            },
          ),
        ),
        _DirectChatInput(user: widget.user, peer: peer),
      ],
    );
  }
}

class _DirectChatInput extends StatefulWidget {
  final UserModel user;
  final UserModel peer;

  const _DirectChatInput({required this.user, required this.peer});

  @override
  State<_DirectChatInput> createState() => _DirectChatInputState();
}

class _DirectChatInputState extends State<_DirectChatInput> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      _controller.clear();
      await ChatRepository.instance.sendDirectMessage(
        sender: widget.user,
        peer: widget.peer,
        text: text,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendMedia() async {
    if (_isSending) return;
    final media = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Медиа и документы',
          extensions: [
            'jpg',
            'jpeg',
            'png',
            'webp',
            'gif',
            'mp4',
            'mov',
            'pdf',
            'doc',
            'docx',
            'xls',
            'xlsx',
            'txt'
          ],
        ),
      ],
    );
    if (media == null) return;

    final text = _controller.text.trim();
    setState(() => _isSending = true);
    try {
      _controller.clear();
      await ChatRepository.instance.sendDirectMessage(
        sender: widget.user,
        peer: widget.peer,
        text: text,
        media: media,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Прикрепить медиа',
            onPressed: _isSending ? null : _sendMedia,
            icon: const Icon(Icons.attach_file_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): () =>
                    _sendText(),
              },
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Написать сообщение...',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            onPressed: _isSending ? null : _sendText,
          ),
        ],
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final UserModel user;

  const _ChatAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final roleColor = user.isDriver ? colors.tertiary : colors.primary;
    return _UserAvatar(user: user, color: roleColor, radius: 22);
  }
}
