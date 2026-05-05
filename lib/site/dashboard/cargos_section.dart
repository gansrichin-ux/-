part of '../../main_site.dart';

class CargosSection extends StatelessWidget {
  final List<CargoModel> cargos;
  final List<CargoModel> allCargos;
  final List<UserModel> drivers;
  final UserModel user;
  final String query;
  final String? status;
  final CargoFilters filters;
  final String? title;
  final String? emptyTitle;
  final String? emptyMessage;
  final bool showAddButton;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<CargoFilters> onFiltersChanged;
  final VoidCallback onAddCargo;
  final Future<void> Function(CargoModel cargo, UserModel driver)
      onAssignDriver;
  final Future<void> Function(CargoModel cargo, String status) onChangeStatus;
  final Future<void> Function(CargoModel cargo) onOpenChat;
  final Future<void> Function(UserModel user) onOpenProfile;
  final Set<String> favoriteCargoIds;
  final Future<void> Function(CargoModel cargo, bool favorite) onToggleFavorite;
  final List<CargoApplicationModel> applications;
  final Future<void> Function(CargoModel cargo, String note) onApplyToCargo;
  final Future<void> Function(
    CargoApplicationModel application,
    CargoModel cargo,
    bool accepted,
  ) onApplicationDecision;

  const CargosSection({
    super.key,
    required this.cargos,
    required this.allCargos,
    required this.drivers,
    required this.user,
    required this.query,
    required this.status,
    required this.filters,
    this.title,
    this.emptyTitle,
    this.emptyMessage,
    this.showAddButton = true,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onFiltersChanged,
    required this.onAddCargo,
    required this.onAssignDriver,
    required this.onChangeStatus,
    required this.onOpenChat,
    required this.onOpenProfile,
    required this.favoriteCargoIds,
    required this.onToggleFavorite,
    required this.applications,
    required this.onApplyToCargo,
    required this.onApplicationDecision,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CargoToolbar(
          query: query,
          status: status,
          filters: filters,
          bodyTypes: allCargos
              .map((cargo) => cargo.bodyType?.trim())
              .whereType<String>()
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort(),
          onQueryChanged: onQueryChanged,
          onStatusChanged: onStatusChanged,
          onFiltersChanged: onFiltersChanged,
          onAddCargo: user.isDriver || !showAddButton ? null : onAddCargo,
        ),
        if (title != null)
          _CargoSectionHeader(
            title: title!,
            total: allCargos.length,
            shown: cargos.length,
          ),
        Expanded(
          child: cargos.isEmpty
              ? Center(
                  child: _StatePanel(
                    icon: Icons.search_off_rounded,
                    title: allCargos.isEmpty
                        ? (emptyTitle ?? 'Нет грузов')
                        : 'Ничего не найдено',
                    message: allCargos.isEmpty
                        ? (emptyMessage ?? 'Создайте первую заявку.')
                        : 'Измените поиск или статус.',
                    actionLabel: user.isDriver ? null : 'Новый груз',
                    onAction:
                        user.isDriver || !showAddButton ? null : onAddCargo,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 96),
                  itemCount: cargos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cargo = cargos[index];
                    return CargoWebCard(
                      cargo: cargo,
                      drivers: drivers,
                      user: user,
                      onAssignDriver: onAssignDriver,
                      onChangeStatus: onChangeStatus,
                      onOpenChat: onOpenChat,
                      onOpenProfile: onOpenProfile,
                      isFavorite: favoriteCargoIds.contains(cargo.id),
                      onToggleFavorite: onToggleFavorite,
                      applications: applications
                          .where((item) => item.cargoId == cargo.id)
                          .toList(),
                      onApplyToCargo: onApplyToCargo,
                      onApplicationDecision: onApplicationDecision,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CargoSectionHeader extends StatelessWidget {
  final String title;
  final int total;
  final int shown;

  const _CargoSectionHeader({
    required this.title,
    required this.total,
    required this.shown,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Text(
            '$title ($shown)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            'Всего в разделе: $total',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CargoToolbar extends StatelessWidget {
  final String query;
  final String? status;
  final CargoFilters filters;
  final List<String> bodyTypes;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<CargoFilters> onFiltersChanged;
  final VoidCallback? onAddCargo;

  const _CargoToolbar({
    required this.query,
    required this.status,
    required this.filters,
    required this.bodyTypes,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onFiltersChanged,
    this.onAddCargo,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 860;
    final topControls = isWide
        ? Row(
            children: [
              Expanded(child: _buildSearch()),
              const SizedBox(width: 14),
              _StatusChips(status: status, onChanged: onStatusChanged),
              if (onAddCargo != null) ...[
                const SizedBox(width: 14),
                FilledButton.icon(
                  onPressed: onAddCargo,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Новый груз'),
                ),
              ],
            ],
          )
        : Column(
            children: [
              _buildSearch(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatusChips(
                      status: status,
                      onChanged: onStatusChanged,
                    ),
                  ),
                  if (onAddCargo != null) ...[
                    const SizedBox(width: 10),
                    IconButton.filled(
                      tooltip: 'Новый груз',
                      onPressed: onAddCargo,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ],
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          topControls,
          const SizedBox(height: 10),
          _AdvancedCargoFilters(
            filters: filters,
            bodyTypes: bodyTypes,
            onChanged: onFiltersChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: onQueryChanged,
      decoration: const InputDecoration(
        hintText: 'Поиск по грузу, маршруту или водителю',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }
}

// ignore: unused_element
class _StatusFilter extends StatelessWidget {
  final String? status;
  final ValueChanged<String?> onChanged;

  const _StatusFilter({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: status ?? 'Все',
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.tune_rounded),
        labelText: 'Статус',
      ),
      items: [
        const DropdownMenuItem<String>(value: 'Все', child: Text('Все')),
        ...cargoStatuses.map(
          (status) =>
              DropdownMenuItem<String>(value: status, child: Text(status)),
        ),
      ],
      onChanged: (value) => onChanged(value == 'Все' ? null : value),
    );
  }
}

class _StatusChips extends StatefulWidget {
  final String? status;
  final ValueChanged<String?> onChanged;

  const _StatusChips({required this.status, required this.onChanged});

  @override
  State<_StatusChips> createState() => _StatusChipsState();
}

class _StatusChipsState extends State<_StatusChips> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = <String?>[null, ...cargoStatuses];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: options.map((value) {
              final selected = value == widget.status;
              final label = value ?? 'Все';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: selected
                      ? Icon(Icons.check_rounded, size: 16, color: colors.primary)
                      : null,
                  label: Text(label),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => widget.onChanged(value),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _AdvancedCargoFilters extends StatelessWidget {
  final CargoFilters filters;
  final List<String> bodyTypes;
  final ValueChanged<CargoFilters> onChanged;

  const _AdvancedCargoFilters({
    required this.filters,
    required this.bodyTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: filters.isActive,
      leading: Icon(Icons.tune_rounded, color: colors.primary),
      title: Text(
        filters.isActive
            ? 'Расширенные фильтры включены'
            : 'Расширенные фильтры',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      trailing: filters.isActive
          ? TextButton.icon(
              onPressed: () => onChanged(CargoFilters.empty),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Сбросить'),
            )
          : const Icon(Icons.expand_more_rounded),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final fields = [
              TextFormField(
                key: ValueKey('from_${filters.from}_${filters.to}'),
                initialValue: filters.from,
                decoration: InputDecoration(
                  labelText: 'Место погрузки',
                  prefixIcon: const Icon(Icons.upload_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Поменять местами',
                    icon: const Icon(Icons.swap_vert_rounded),
                    onPressed: () => onChanged(
                      filters.copyWith(from: filters.to, to: filters.from),
                    ),
                  ),
                ),
                onChanged: (value) => onChanged(filters.copyWith(from: value)),
              ),
              TextFormField(
                key: ValueKey('to_${filters.from}_${filters.to}'),
                initialValue: filters.to,
                decoration: const InputDecoration(
                  labelText: 'Место разгрузки',
                  prefixIcon: Icon(Icons.download_rounded),
                ),
                onChanged: (value) => onChanged(filters.copyWith(to: value)),
              ),
              DropdownButtonFormField<String>(
                value: filters.bodyType.isEmpty ? '' : filters.bodyType,
                decoration: const InputDecoration(
                  labelText: 'Тип кузова',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Любой')),
                  ...bodyTypes.map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  ),
                ],
                onChanged: (value) =>
                    onChanged(filters.copyWith(bodyType: value ?? '')),
              ),
              TextFormField(
                initialValue: filters.minWeight?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Тоннаж от'),
                onChanged: (value) => onChanged(
                  filters.copyWith(
                    minWeight: _parseDouble(value),
                    clearMinWeight: value.trim().isEmpty,
                  ),
                ),
              ),
              TextFormField(
                initialValue: filters.maxWeight?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Тоннаж до'),
                onChanged: (value) => onChanged(
                  filters.copyWith(
                    maxWeight: _parseDouble(value),
                    clearMaxWeight: value.trim().isEmpty,
                  ),
                ),
              ),
              TextFormField(
                initialValue: filters.minPrice?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Цена от'),
                onChanged: (value) => onChanged(
                  filters.copyWith(
                    minPrice: _parseDouble(value),
                    clearMinPrice: value.trim().isEmpty,
                  ),
                ),
              ),
              TextFormField(
                initialValue: filters.maxPrice?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Цена до'),
                onChanged: (value) => onChanged(
                  filters.copyWith(
                    maxPrice: _parseDouble(value),
                    clearMaxPrice: value.trim().isEmpty,
                  ),
                ),
              ),
            ];

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: compact ? 1 : 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: compact ? 5.2 : 3.4,
                    children: fields,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: filters.onlyWithoutDriver,
                    onChanged: (value) => onChanged(
                      filters.copyWith(onlyWithoutDriver: value),
                    ),
                    title: const Text(
                      'Только грузы без исполнителя',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class CargoWebCard extends StatelessWidget {
  final CargoModel cargo;
  final List<UserModel> drivers;
  final UserModel user;
  final Future<void> Function(CargoModel cargo, UserModel driver)
      onAssignDriver;
  final Future<void> Function(CargoModel cargo, String status) onChangeStatus;
  final Future<void> Function(CargoModel cargo) onOpenChat;
  final Future<void> Function(UserModel user) onOpenProfile;
  final bool isFavorite;
  final Future<void> Function(CargoModel cargo, bool favorite) onToggleFavorite;
  final List<CargoApplicationModel> applications;
  final Future<void> Function(CargoModel cargo, String note) onApplyToCargo;
  final Future<void> Function(
    CargoApplicationModel application,
    CargoModel cargo,
    bool accepted,
  ) onApplicationDecision;

  const CargoWebCard({
    super.key,
    required this.cargo,
    required this.drivers,
    required this.user,
    required this.onAssignDriver,
    required this.onChangeStatus,
    required this.onOpenChat,
    required this.onOpenProfile,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.applications,
    required this.onApplyToCargo,
    required this.onApplicationDecision,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = _statusColor(cargo.status);
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_shipping_rounded, color: statusColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cargo.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${cargo.from} -> ${cargo.to}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: isFavorite
                      ? 'Убрать из отмеченных'
                      : 'Добавить в отмеченные',
                  onPressed: () => onToggleFavorite(cargo, !isFavorite),
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFavorite ? colors.tertiary : colors.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                _StatusPill(label: cargo.status, color: statusColor),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (cargo.createdAt != null)
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat('dd.MM.yyyy').format(cargo.createdAt!),
                  ),
                if (cargo.loadingDate != null)
                  _InfoChip(
                    icon: Icons.event_available_rounded,
                    label:
                        'Погрузка ${DateFormat('dd.MM.yyyy').format(cargo.loadingDate!)}',
                  ),
                if (cargo.weightKg != null)
                  _InfoChip(
                    icon: Icons.scale_rounded,
                    label: '${cargo.weightKg!.toStringAsFixed(1)} т',
                  ),
                if (cargo.volumeM3 != null)
                  _InfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${cargo.volumeM3!.toStringAsFixed(1)} м3',
                  ),
                if (cargo.bodyType?.isNotEmpty == true)
                  _InfoChip(
                    icon: Icons.local_shipping_outlined,
                    label: cargo.bodyType!,
                  ),
                if (cargo.distanceKm != null)
                  _InfoChip(
                    icon: Icons.route_rounded,
                    label: '${cargo.distanceKm!.toStringAsFixed(0)} км',
                  ),
                if (cargo.price != null)
                  _InfoChip(
                    icon: Icons.payments_rounded,
                    label: _formatMoney(cargo.price!),
                  ),
                if (cargo.driverName?.isNotEmpty == true)
                  _InfoChip(
                    icon: Icons.badge_rounded,
                    label: cargo.driverName!,
                  ),
              ],
            ),
            if (cargo.description?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                cargo.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _actions(context),
                  )
                : Row(children: [const Spacer(), ..._actions(context)]),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final canManage = cargo.ownerId == user.uid || cargo.driverId == user.uid;
    final myApplication =
        applications.cast<CargoApplicationModel?>().firstWhere(
              (item) => item?.applicantId == user.uid,
              orElse: () => null,
            );
    final pendingCount = applications.where((item) => item.isPending).length;
    final widgets = <Widget>[
      OutlinedButton.icon(
        onPressed: () => onOpenChat(cargo),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Чат'),
      ),
      const SizedBox(width: 10, height: 10),
      OutlinedButton.icon(
        onPressed: () => _showDocumentsDialog(context),
        icon: const Icon(Icons.attach_file_rounded),
        label: const Text('Документы'),
      ),
    ];

    if (user.isDriver && cargo.ownerId != user.uid && cargo.driverId == null) {
      widgets.add(const SizedBox(width: 10, height: 10));
      if (myApplication == null) {
        widgets.add(
          FilledButton.icon(
            onPressed: () => _showApplyDialog(context),
            icon: const Icon(Icons.how_to_reg_rounded),
            label: const Text('Откликнуться'),
          ),
        );
      } else {
        widgets.add(
          _StatusPill(
            label: _applicationStatusLabel(myApplication.status),
            color: _applicationStatusColor(myApplication.status),
          ),
        );
      }
    }

    if (!user.isDriver && cargo.ownerId == user.uid && pendingCount > 0) {
      widgets.addAll([
        const SizedBox(width: 10, height: 10),
        FilledButton.tonalIcon(
          onPressed: () => _showApplicationsDialog(context),
          icon: const Icon(Icons.how_to_reg_rounded),
          label: Text('Отклики ($pendingCount)'),
        ),
      ]);
    }

    if (canManage) {
      widgets.addAll([
        const SizedBox(width: 10, height: 10),
        OutlinedButton.icon(
          onPressed: () => _showStatusDialog(context),
          icon: const Icon(Icons.swap_horiz_rounded),
          label: const Text('Статус'),
        ),
      ]);
    }

    if (!user.isDriver && drivers.isNotEmpty && cargo.ownerId == user.uid) {
      widgets.addAll([
        const SizedBox(width: 10, height: 10),
        FilledButton.icon(
          onPressed: () => _showDriverDialog(context),
          icon: const Icon(Icons.assignment_ind_rounded),
          label: const Text('Назначить'),
        ),
      ]);
    }

    return widgets;
  }

  Future<void> _showApplyDialog(BuildContext context) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => const _ApplyCargoDialog(),
    );
    if (note == null) return;
    await onApplyToCargo(cargo, note);
  }

  Future<void> _showApplicationsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ApplicationsDialog(
        cargo: cargo,
        applications: applications,
        onDecision: onApplicationDecision,
      ),
    );
  }

  Future<void> _showDocumentsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CargoDocumentsDialog(cargo: cargo, user: user),
    );
  }

  Future<void> _showStatusDialog(BuildContext context) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Изменить статус'),
        children: cargoStatuses
            .map(
              (status) => ListTile(
                leading: Icon(
                  status == cargo.status
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                title: Text(status),
                onTap: () => Navigator.pop(context, status),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null && selected != cargo.status) {
      await onChangeStatus(cargo, selected);
    }
  }

  Future<void> _showDriverDialog(BuildContext context) async {
    final driver = await showDialog<UserModel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Назначить водителя'),
        children: drivers
            .map(
              (driver) => ListTile(
                leading: const Icon(Icons.badge_rounded),
                title: Text(driver.displayName),
                subtitle: Text(driver.car ?? 'Бригада / транспорт не указаны'),
                trailing: IconButton(
                  tooltip: 'Профиль',
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () => onOpenProfile(driver),
                ),
                onTap: () => Navigator.pop(context, driver),
              ),
            )
            .toList(),
      ),
    );

    if (driver != null) await onAssignDriver(cargo, driver);
  }
}

class _ApplyCargoDialog extends StatefulWidget {
  const _ApplyCargoDialog();

  @override
  State<_ApplyCargoDialog> createState() => _ApplyCargoDialogState();
}

class _ApplyCargoDialogState extends State<_ApplyCargoDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Откликнуться на груз'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Комментарий для логиста',
            hintText: 'Например: свободен сегодня, есть бригада 3 человека',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          icon: const Icon(Icons.send_rounded),
          label: const Text('Отправить'),
        ),
      ],
    );
  }
}

class _ApplicationsDialog extends StatelessWidget {
  final CargoModel cargo;
  final List<CargoApplicationModel> applications;
  final Future<void> Function(
    CargoApplicationModel application,
    CargoModel cargo,
    bool accepted,
  ) onDecision;

  const _ApplicationsDialog({
    required this.cargo,
    required this.applications,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    final pending = applications.where((item) => item.isPending).toList();
    return AlertDialog(
      title: Text('Отклики: ${cargo.title}'),
      content: SizedBox(
        width: 560,
        child: pending.isEmpty
            ? const _ProfileEmpty(
                icon: Icons.how_to_reg_outlined,
                title: 'Нет новых откликов',
                message: 'Новые кандидаты появятся здесь.',
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: pending.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final application = pending[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${application.applicantName} ${application.applicantUsername}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        if (application.note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(application.note),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                await onDecision(application, cargo, false);
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.close_rounded),
                              label: const Text('Отклонить'),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: () async {
                                await onDecision(application, cargo, true);
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Принять'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

class _CargoDocumentsDialog extends StatefulWidget {
  final CargoModel cargo;
  final UserModel user;

  const _CargoDocumentsDialog({required this.cargo, required this.user});

  @override
  State<_CargoDocumentsDialog> createState() => _CargoDocumentsDialogState();
}

class _CargoDocumentsDialogState extends State<_CargoDocumentsDialog> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Документы и изображения',
          extensions: [
            'pdf',
            'doc',
            'docx',
            'xls',
            'xlsx',
            'jpg',
            'jpeg',
            'png',
            'webp'
          ],
        ),
      ],
    );
    if (file == null || _isUploading) return;

    setState(() => _isUploading = true);
    try {
      await SiteWorkflowRepository.instance.uploadCargoDocument(
        cargo: widget.cargo,
        uploader: widget.user,
        file: file,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Документ прикреплен')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить документ: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Документы: ${widget.cargo.title}'),
      content: SizedBox(
        width: 640,
        height: 460,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _isUploading ? null : _pickAndUpload,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: const Text('Прикрепить файл'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<DocumentModel>>(
                stream: SiteWorkflowRepository.instance.watchCargoDocuments(
                  widget.cargo.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data ?? const <DocumentModel>[];
                  if (docs.isEmpty) {
                    return const _ProfileEmpty(
                      icon: Icons.description_outlined,
                      title: 'Документов нет',
                      message:
                          'Прикрепите договор, накладную, чек или фото груза.',
                    );
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _CargoDocumentTile(document: docs[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

class _CargoDocumentTile extends StatelessWidget {
  final DocumentModel document;

  const _CargoDocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    final color = document.documentType.color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${document.documentType.displayName} · ${document.fileSizeFormatted} · ${DateFormat('dd.MM.yyyy HH:mm').format(document.createdAt)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  document.fileUrl,
                  maxLines: 1,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Открыть',
            onPressed: () => _openMediaUrl(document.fileUrl),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
          IconButton(
            tooltip: 'Скачать',
            onPressed: () =>
                _downloadMediaUrl(document.fileUrl, document.fileName),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
    );
  }
}
