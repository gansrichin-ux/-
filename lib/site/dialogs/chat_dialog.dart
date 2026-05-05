part of '../../main_site.dart';

class SiteChatDialog extends StatefulWidget {
  final CargoModel cargo;
  final UserModel user;

  const SiteChatDialog({super.key, required this.cargo, required this.user});

  @override
  State<SiteChatDialog> createState() => _SiteChatDialogState();
}

class _SiteChatDialogState extends State<SiteChatDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    await ChatRepository.instance.sendMessage(
      widget.cargo.id,
      MessageModel(
        id: '',
        text: text,
        senderId: widget.user.uid,
        senderName:
            '${widget.user.displayName} (${widget.user.displayUsername})',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Чат по грузу',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${widget.cargo.title}: ${widget.cargo.from} -> ${widget.cargo.to}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: ChatRepository.instance.watchMessages(widget.cargo.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? const <MessageModel>[];
                  if (messages.isEmpty) {
                    return const Center(
                      child: _StatePanel(
                        icon: Icons.forum_outlined,
                        title: 'Сообщений пока нет',
                        message:
                            'Начните обсуждение маршрута, погрузки или документов.',
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(18),
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
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter): () =>
                            _send(),
                      },
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          hintText: 'Написать сообщение...',
                          prefixIcon: Icon(Icons.message_outlined),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Отправить',
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SiteMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _SiteMessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bubbleColor = isMe
        ? colors.primary.withOpacity(0.14)
        : colors.surfaceContainerHighest.withOpacity(0.72);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.sizeOf(context).width < 760 ? null : 420,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMe
                ? colors.primary.withOpacity(0.22)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.senderName,
              style: TextStyle(
                color: isMe ? colors.primary : colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            if (message.mediaUrl?.isNotEmpty == true) ...[
              _MessageMedia(message: message),
              if (message.text.isNotEmpty) const SizedBox(height: 8),
            ],
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            if (message.timestamp != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat('dd.MM HH:mm').format(message.timestamp!),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageMedia extends StatelessWidget {
  final MessageModel message;

  const _MessageMedia({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mediaUrl = message.mediaUrl!;
    final mediaType = message.mediaType ?? '';
    final name = message.mediaName ?? 'Медиа';
    final isImage = mediaType.startsWith('image/');

    if (isImage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showMediaPreview(context, message),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 220,
                errorBuilder: (context, error, stackTrace) => _MediaFallback(
                  name: name,
                  url: mediaUrl,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _MediaActions(name: name, url: mediaUrl),
        ],
      );
    }

    return _MediaFallback(name: name, url: mediaUrl, color: colors.primary);
  }
}

void _openMediaUrl(String url) {
  web.window.open(url, '_blank');
}

void _downloadMediaUrl(String url, String name) {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..target = '_blank'
    ..rel = 'noopener';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}

void _showMediaPreview(BuildContext context, MessageModel message) {
  final url = message.mediaUrl;
  if (url == null || url.isEmpty) return;
  final name = message.mediaName ?? 'media';
  final mediaType = message.mediaType ?? '';

  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 620),
        child: mediaType.startsWith('image/')
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                ),
              )
            : _MediaFallback(
                name: name,
                url: url,
                color: Theme.of(context).colorScheme.primary,
              ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _openMediaUrl(url),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Открыть'),
        ),
        FilledButton.icon(
          onPressed: () => _downloadMediaUrl(url, name),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Скачать'),
        ),
      ],
    ),
  );
}

class _MediaActions extends StatelessWidget {
  final String name;
  final String url;

  const _MediaActions({required this.name, required this.url});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _openMediaUrl(url),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Открыть'),
        ),
        OutlinedButton.icon(
          onPressed: () => _downloadMediaUrl(url, name),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Скачать'),
        ),
      ],
    );
  }
}

class _MediaFallback extends StatelessWidget {
  final String name;
  final String url;
  final Color color;

  const _MediaFallback({
    required this.name,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  url,
                  maxLines: 1,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Открыть',
            onPressed: () => _openMediaUrl(url),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
          IconButton(
            tooltip: 'Скачать',
            onPressed: () => _downloadMediaUrl(url, name),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
    );
  }
}
