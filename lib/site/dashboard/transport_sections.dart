part of '../../main_site.dart';

class FindTransportSection extends StatefulWidget {
  final UserModel user;
  final List<TransportModel> transports;
  final Function(UserModel) onOpenProfile;
  final Function(UserModel) onOpenChat;

  const FindTransportSection({
    super.key,
    required this.user,
    required this.transports,
    required this.onOpenProfile,
    required this.onOpenChat,
  });

  @override
  State<FindTransportSection> createState() => _FindTransportSectionState();
}

class _FindTransportSectionState extends State<FindTransportSection> {
  String _query = '';
  String? _bodyType;
  double? _minCapacity;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.transports.where((t) {
      if (_bodyType != null && t.bodyType != _bodyType) return false;
      if (_minCapacity != null && t.capacityTons < _minCapacity!) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        return t.ownerName.toLowerCase().contains(q) ||
            t.brand?.toLowerCase().contains(q) == true ||
            t.model?.toLowerCase().contains(q) == true ||
            t.loadingPoints.any((p) => p.toLowerCase().contains(q)) ||
            t.unloadingPoints.any((p) => p.toLowerCase().contains(q));
      }
      return true;
    }).toList();

    return Column(
      children: [
        _buildFilters(context),
        Expanded(
          child: filtered.isEmpty
              ? const AppEmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: 'Транспорт не найден',
                  message: 'Попробуйте изменить параметры поиска или фильтры.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 500,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    mainAxisExtent: 380,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => TransportOfferCard(
                    transport: filtered[index],
                    onChat: () => _handleChat(filtered[index]),
                    onPropose: () => _handlePropose(filtered[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: AppTextField(
              hint: 'Поиск по городу, имени или модели...',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AppDropdown<String>(
              value: _bodyType,
              hint: 'Тип кузова',
              items: [
                const DropdownMenuItem(value: null, child: Text('Все типы')),
                ...TruckBodyTypes.labels.entries.map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    )),
              ],
              onChanged: (v) => setState(() => _bodyType = v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: AppTextField(
              hint: 'Мин. тонн',
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() => _minCapacity = double.tryParse(v)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleChat(TransportModel t) {
    UserRepository.instance.getUser(t.ownerId).then((user) {
      if (user != null) widget.onOpenChat(user);
    });
  }

  void _handlePropose(TransportModel t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Предложение отправлено ${t.ownerName}')),
    );
  }
}

class MyTransportSection extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAddTransport;
  final Function(UserModel) onOpenProfile;

  const MyTransportSection({
    super.key,
    required this.user,
    required this.onAddTransport,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransportModel>>(
      stream: TransportRepository.instance.watchUserTransport(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState();
        }
        if (snapshot.hasError) {
          return AppErrorState(message: snapshot.error.toString());
        }
        final transports = snapshot.data ?? [];
        if (transports.isEmpty) {
          return AppEmptyState(
            icon: Icons.commute_rounded,
            title: 'У вас пока нет транспорта',
            message: 'Добавьте свои машины, чтобы грузовладельцы и логисты могли вас найти.',
            action: AppButton(
              label: 'Добавить транспорт',
              onPressed: onAddTransport,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: transports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final t = transports[index];
            return AppCard(
              child: ListTile(
                leading: const Icon(Icons.local_shipping_rounded, size: 40),
                title: Text('${t.brand ?? 'Машина'} ${t.model ?? ''} (${t.plateNumber ?? 'Без номера'})'),
                subtitle: Text('${t.bodyTypeLabel} · ${t.capacityTons} т · ${t.volumeM3} м³'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () {}, // TODO: Edit transport
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () => TransportRepository.instance.deleteTransport(t.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class TransportOfferCard extends StatelessWidget {
  final TransportModel transport;
  final VoidCallback onChat;
  final VoidCallback onPropose;

  const TransportOfferCard({
    super.key,
    required this.transport,
    required this.onChat,
    required this.onPropose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: transport.ownerPhotoUrl != null
                    ? NetworkImage(transport.ownerPhotoUrl!)
                    : null,
                child: transport.ownerPhotoUrl == null
                    ? const Icon(Icons.person_rounded)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transport.ownerName,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('5.0', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${transport.capacityTons} т',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.route_rounded, 'Маршрут', transport.preferredDirections.isEmpty ? 'Любое направление' : transport.preferredDirections.join(' - ')),
          _buildInfoRow(Icons.calendar_today_rounded, 'Доступен', transport.availableFrom != null ? DateFormat('dd.MM.yyyy').format(transport.availableFrom!) : 'Сейчас'),
          _buildInfoRow(Icons.view_in_ar_rounded, 'Кузов', '${transport.bodyTypeLabel} · ${transport.volumeM3} м³'),
          if (transport.dimensionsLabel.isNotEmpty)
            _buildInfoRow(Icons.straighten_rounded, 'Габариты', transport.dimensionsLabel),
          
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (transport.hasAdr) const AppStatusBadge(label: 'ADR', color: Colors.orange),
              if (transport.hasGps) const AppStatusBadge(label: 'GPS', color: Colors.blue),
              if (transport.hasTir) const AppStatusBadge(label: 'TIR', color: Colors.green),
              if (transport.allowsReload) const AppStatusBadge(label: 'Догруз', color: Colors.purple),
            ],
          ),
          
          const Spacer(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Предложить груз',
                  onPressed: onPropose,
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
