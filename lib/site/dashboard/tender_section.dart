part of '../../main_site.dart';

class TenderSection extends StatefulWidget {
  final UserModel user;
  const TenderSection({super.key, required this.user});

  @override
  State<TenderSection> createState() => _TenderSectionState();
}

class _TenderSectionState extends State<TenderSection> {
  String _filter = 'all'; // all, my, active, awarded
  final _filterScrollController = ScrollController();

  @override
  void dispose() {
    _filterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StreamBuilder<List<TenderModel>>(
      stream: TenderRepository.instance.watchAllTenders(),
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        final tenders = _applyFilter(all);

        return Column(
          children: [
            _buildHeader(context, colors, all),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting && all.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : tenders.isEmpty
                      ? _buildEmpty(context)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: tenders.length,
                          itemBuilder: (_, i) => _TenderCard(
                            tender: tenders[i],
                            currentUser: widget.user,
                            onTap: () => _openDetail(context, tenders[i]),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  List<TenderModel> _applyFilter(List<TenderModel> list) {
    switch (_filter) {
      case 'my':
        return list.where((t) => t.ownerId == widget.user.uid).toList();
      case 'active':
        return list.where((t) => t.isActive && !t.isExpired).toList();
      case 'awarded':
        return list.where((t) => t.isAwarded).toList();
      default:
        return list;
    }
  }

  Widget _buildHeader(BuildContext ctx, ColorScheme colors, List<TenderModel> all) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(ctx).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(ctx).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _filterScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _filterScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    _FilterChip(label: 'Все (${all.length})', value: 'all', current: _filter, onTap: (v) => setState(() => _filter = v)),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Активные', value: 'active', current: _filter, onTap: (v) => setState(() => _filter = v)),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Мои', value: 'my', current: _filter, onTap: (v) => setState(() => _filter = v)),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Завершённые', value: 'awarded', current: _filter, onTap: (v) => setState(() => _filter = v)),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.user.isDriver) ...[
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(ctx),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Тендер'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gavel_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('Тендеров пока нет', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            widget.user.isDriver ? 'Когда логисты создадут тендеры, они появятся здесь.' : 'Создайте первый тендер — нажмите кнопку выше.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, TenderModel tender) {
    showDialog(
      context: context,
      builder: (_) => _TenderDetailDialog(tender: tender, currentUser: widget.user),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateTenderDialog(owner: widget.user),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label, value, current;
  final ValueChanged<String> onTap;
  const _FilterChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(color: selected ? colors.onPrimary : colors.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

// ─── Tender Card ──────────────────────────────────────────────────────────────

class _TenderCard extends StatelessWidget {
  final TenderModel tender;
  final UserModel currentUser;
  final VoidCallback onTap;
  const _TenderCard({required this.tender, required this.currentUser, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(tender.status, colors);
    final statusLabel = _statusLabel(tender);
    final daysLeft = tender.deadlineAt.difference(DateTime.now()).inDays;
    final isOwner = tender.ownerId == currentUser.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(tender.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: statusColor.withOpacity(0.3))),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.route_rounded, size: 15, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(child: Text('${tender.from} → ${tender.to}', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _InfoBadge(icon: Icons.attach_money_rounded, text: 'от ${tender.startingPrice.toStringAsFixed(0)} ${tender.currency}'),
                  const SizedBox(width: 8),
                  _InfoBadge(icon: Icons.how_to_reg_rounded, text: '${tender.bidCount} ставок'),
                  const SizedBox(width: 8),
                  if (tender.isActive)
                    _InfoBadge(
                      icon: Icons.timer_outlined,
                      text: daysLeft > 0 ? '$daysLeft дн.' : 'Истекает сегодня',
                      color: daysLeft <= 1 ? colors.error : null,
                    ),
                  if (isOwner) ...[const SizedBox(width: 8), _InfoBadge(icon: Icons.person_rounded, text: 'Мой тендер', color: colors.primary)],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status, ColorScheme colors) {
    switch (status) {
      case tenderStatusAwarded: return colors.secondary;
      case tenderStatusClosed: return colors.error;
      default: return colors.primary;
    }
  }

  String _statusLabel(TenderModel t) {
    if (t.isExpired) return 'Истёк';
    switch (t.status) {
      case tenderStatusAwarded: return 'Победитель выбран';
      case tenderStatusClosed: return 'Закрыт';
      default: return 'Активен';
    }
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoBadge({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: c),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ─── Create Tender Dialog ─────────────────────────────────────────────────────

class _CreateTenderDialog extends StatefulWidget {
  final UserModel owner;
  const _CreateTenderDialog({required this.owner});

  @override
  State<_CreateTenderDialog> createState() => _CreateTenderDialogState();
}

class _CreateTenderDialogState extends State<_CreateTenderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));
  String _currency = '₸';
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _fromCtrl.dispose();
    _toCtrl.dispose(); _priceCtrl.dispose(); _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await TenderRepository.instance.createTender(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        from: _fromCtrl.text.trim(),
        to: _toCtrl.text.trim(),
        startingPrice: double.tryParse(_priceCtrl.text) ?? 0,
        currency: _currency,
        deadlineAt: _deadline,
        owner: widget.owner,
        weightKg: double.tryParse(_weightCtrl.text),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новый тендер', style: TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Название тендера *', prefixIcon: Icon(Icons.gavel_rounded)), validator: (v) => (v?.trim().isEmpty ?? true) ? 'Обязательное поле' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Описание', prefixIcon: Icon(Icons.description_outlined)), maxLines: 2),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _fromCtrl, decoration: const InputDecoration(labelText: 'Откуда *', prefixIcon: Icon(Icons.location_on_outlined)), validator: (v) => (v?.trim().isEmpty ?? true) ? 'Укажите' : null)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _toCtrl, decoration: const InputDecoration(labelText: 'Куда *', prefixIcon: Icon(Icons.flag_outlined)), validator: (v) => (v?.trim().isEmpty ?? true) ? 'Укажите' : null)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Начальная цена *', prefixIcon: Icon(Icons.attach_money_rounded)),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Введите число' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(labelText: 'Валюта'),
                    items: const ['₸', '\$', '₽'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Вес груза (т)', prefixIcon: Icon(Icons.scale_outlined))),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Срок подачи ставок', prefixIcon: Icon(Icons.event_rounded)),
                  child: Text(DateFormat('dd.MM.yyyy').format(_deadline), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded),
          label: Text(_loading ? 'Создаём...' : 'Создать'),
        ),
      ],
    );
  }
}

// ─── Tender Detail Dialog ────────────────────────────────────────────────────

class _TenderDetailDialog extends StatefulWidget {
  final TenderModel tender;
  final UserModel currentUser;
  const _TenderDetailDialog({required this.tender, required this.currentUser});

  @override
  State<_TenderDetailDialog> createState() => _TenderDetailDialogState();
}

class _TenderDetailDialogState extends State<_TenderDetailDialog> {
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _bidLoading = false;
  bool _showBidForm = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _isOwner => widget.tender.ownerId == widget.currentUser.uid;
  bool get _isDriver => widget.currentUser.isDriver;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = widget.tender;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Expanded(child: Text(t.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 4),
              Text('${t.from} → ${t.to}', style: TextStyle(color: colors.onSurfaceVariant)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _InfoBadge(icon: Icons.attach_money_rounded, text: 'от ${t.startingPrice.toStringAsFixed(0)} ${t.currency}'),
                _InfoBadge(icon: Icons.how_to_reg_rounded, text: '${t.bidCount} ставок'),
                _InfoBadge(icon: Icons.event_rounded, text: 'до ${DateFormat('dd.MM.yyyy').format(t.deadlineAt)}'),
                if (t.weightKg != null) _InfoBadge(icon: Icons.scale_outlined, text: '${t.weightKg} т'),
                _InfoBadge(icon: Icons.person_rounded, text: t.ownerName),
              ]),
              if (t.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(t.description, style: TextStyle(color: colors.onSurfaceVariant)),
              ],
              if (t.isAwarded && t.winnerName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.secondary.withOpacity(0.3))),
                  child: Row(children: [
                    Icon(Icons.emoji_events_rounded, color: colors.secondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Победитель: ${t.winnerName} — ${t.winnerPrice?.toStringAsFixed(0)} ${t.currency}', style: TextStyle(fontWeight: FontWeight.w700, color: colors.secondary))),
                  ]),
                ),
              ],
              const Divider(height: 24),
              // Bids list
              Expanded(
                child: StreamBuilder<List<TenderBidModel>>(
                  stream: TenderRepository.instance.watchBidsForTender(t.id),
                  builder: (ctx, snap) {
                    final bids = snap.data ?? [];
                    if (bids.isEmpty) {
                      return Center(child: Text('Ставок пока нет', style: TextStyle(color: colors.onSurfaceVariant)));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ставки (${bids.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: bids.length,
                            itemBuilder: (_, i) => _BidTile(
                              bid: bids[i],
                              tender: t,
                              isOwner: _isOwner,
                              currentUser: widget.currentUser,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Driver: My bid / bid form
              if (_isDriver && t.isActive && !t.isExpired) ...[
                const Divider(height: 16),
                StreamBuilder<TenderBidModel?>(
                  stream: TenderRepository.instance.watchMyBid(t.id, widget.currentUser.uid),
                  builder: (ctx, snap) {
                    final myBid = snap.data;
                    if (myBid != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: colors.primaryContainer.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          Icon(Icons.check_circle_outline_rounded, color: colors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Ваша ставка: ${myBid.price.toStringAsFixed(0)} ${t.currency}', style: TextStyle(fontWeight: FontWeight.w700, color: colors.primary))),
                          Text(_bidStatusLabel(myBid.status), style: TextStyle(color: _bidStatusColor(myBid.status, colors), fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      );
                    }
                    if (_showBidForm) {
                      return _buildBidForm(colors, t);
                    }
                    return FilledButton.icon(
                      onPressed: () => setState(() => _showBidForm = true),
                      icon: const Icon(Icons.gavel_rounded),
                      label: const Text('Подать ставку'),
                    );
                  },
                ),
              ],
              // Owner: close tender button
              if (_isOwner && t.isActive) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await TenderRepository.instance.closeTender(t.id);
                    if (mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Закрыть тендер'),
                  style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBidForm(ColorScheme colors, TenderModel t) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(
          child: TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Ваша цена (${t.currency})', prefixIcon: const Icon(Icons.attach_money_rounded)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Комментарий', prefixIcon: Icon(Icons.comment_outlined)),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => setState(() => _showBidForm = false), child: const Text('Отмена')),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _bidLoading ? null : _submitBid,
          icon: _bidLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 16),
          label: Text(_bidLoading ? 'Отправка...' : 'Отправить'),
        ),
      ]),
    ]);
  }

  Future<void> _submitBid() async {
    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите корректную цену')));
      return;
    }
    setState(() => _bidLoading = true);
    try {
      await TenderRepository.instance.placeBid(
        tender: widget.tender,
        bidder: widget.currentUser,
        price: price,
        note: _noteCtrl.text.trim(),
      );
      if (mounted) setState(() => _showBidForm = false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _bidLoading = false);
    }
  }

  String _bidStatusLabel(String status) {
    switch (status) {
      case bidStatusAccepted: return '✓ Принята';
      case bidStatusRejected: return '✗ Отклонена';
      default: return 'На рассмотрении';
    }
  }

  Color _bidStatusColor(String status, ColorScheme colors) {
    switch (status) {
      case bidStatusAccepted: return colors.secondary;
      case bidStatusRejected: return colors.error;
      default: return colors.onSurfaceVariant;
    }
  }
}

// ─── Bid Tile ─────────────────────────────────────────────────────────────────

class _BidTile extends StatelessWidget {
  final TenderBidModel bid;
  final TenderModel tender;
  final bool isOwner;
  final UserModel currentUser;
  const _BidTile({required this.bid, required this.tender, required this.isOwner, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isMe = bid.bidderId == currentUser.uid;
    Color statusColor = bid.isAccepted ? colors.secondary : bid.isRejected ? colors.error : colors.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: colors.primaryContainer, child: Text(bid.bidderName.isNotEmpty ? bid.bidderName[0].toUpperCase() : '?', style: TextStyle(color: colors.onPrimaryContainer, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${bid.bidderName} ${isMe ? "(вы)" : ""}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              if (bid.note.isNotEmpty) Text(bid.note, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Text('${bid.price.toStringAsFixed(0)} ${tender.currency}', style: TextStyle(fontWeight: FontWeight.w900, color: colors.primary, fontSize: 15)),
          const SizedBox(width: 8),
          if (bid.isPending && isOwner && tender.isActive && !tender.isExpired)
            IconButton(
              tooltip: 'Принять ставку',
              icon: Icon(Icons.check_circle_rounded, color: colors.secondary),
              onPressed: () async {
                await TenderRepository.instance.acceptBid(tender: tender, bid: bid);
                if (context.mounted) Navigator.pop(context);
              },
            )
          else
            Text(
              bid.isAccepted ? '✓' : bid.isRejected ? '✗' : '…',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w900),
            ),
        ]),
      ),
    );
  }
}
