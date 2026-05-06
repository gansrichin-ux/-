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
          onAddCargo: !user.canCreateCargo || !showAddButton ? null : onAddCargo,
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
                    actionLabel: user.canCreateCargo ? 'Новый груз' : null,
                    onAction:
                        !user.canCreateCargo || !showAddButton ? null : onAddCargo,
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
        ...CargoStatus.values.map(
          (status) =>
              DropdownMenuItem<String>(value: status, child: Text(CargoStatus.getDisplayStatus(status))),
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
    final options = <String?>[null, ...CargoStatus.values];

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
                  label: Text(value == null ? 'Все' : CargoStatus.getDisplayStatus(value)),
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
      childrenPadding: const EdgeInsets.only(bottom: 24),
      initiallyExpanded: filters.isActive,
      leading: Icon(Icons.tune_rounded, color: colors.primary),
      title: Text(
        filters.isActive ? 'Расширенные фильтры включены' : 'Расширенные фильтры',
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
            final compact = constraints.maxWidth < 900;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildGrid(
                  context,
                  compact ? 1 : 4,
                  [
                    _filterField(
                      label: 'Откуда',
                      icon: Icons.upload_rounded,
                      value: filters.from,
                      onChanged: (v) => onChanged(filters.copyWith(from: v)),
                    ),
                    _filterField(
                      label: 'Куда',
                      icon: Icons.download_rounded,
                      value: filters.to,
                      onChanged: (v) => onChanged(filters.copyWith(to: v)),
                    ),
                    _dropdownField(
                      label: 'Кузов',
                      icon: Icons.local_shipping_outlined,
                      value: filters.bodyType,
                      items: ['', ...bodyTypes],
                      onChanged: (v) => onChanged(filters.copyWith(bodyType: v ?? '')),
                    ),
                    _dropdownField(
                      label: 'Тип транспорта',
                      icon: Icons.local_shipping_rounded,
                      value: filters.truckType ?? '',
                      items: ['', 'Автовоз', 'Газель', 'Трал', 'Микроавтобус', 'Легковая'],
                      onChanged: (v) => onChanged(filters.copyWith(
                        truckType: v?.isEmpty == true ? null : v,
                        clearTruckType: v?.isEmpty == true,
                      )),
                    ),
                    _rangeField(
                      labelFrom: 'Вес от, т',
                      labelTo: 'до',
                      valFrom: filters.minWeight,
                      valTo: filters.maxWeight,
                      onFrom: (v) => onChanged(filters.copyWith(minWeight: v, clearMinWeight: v == null)),
                      onTo: (v) => onChanged(filters.copyWith(maxWeight: v, clearMaxWeight: v == null)),
                    ),
                    _rangeField(
                      labelFrom: 'Объем от, м³',
                      labelTo: 'до',
                      valFrom: filters.minVolume,
                      valTo: filters.maxVolume,
                      onFrom: (v) => onChanged(filters.copyWith(minVolume: v, clearMinVolume: v == null)),
                      onTo: (v) => onChanged(filters.copyWith(maxVolume: v, clearMaxVolume: v == null)),
                    ),
                    _rangeField(
                      labelFrom: 'Цена от',
                      labelTo: 'до',
                      valFrom: filters.minPrice,
                      valTo: filters.maxPrice,
                      onFrom: (v) => onChanged(filters.copyWith(minPrice: v, clearMinPrice: v == null)),
                      onTo: (v) => onChanged(filters.copyWith(maxPrice: v, clearMaxPrice: v == null)),
                    ),
                    _datePickerField(context),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: [
                    _switch('Без водителя', filters.onlyWithoutDriver, (v) => onChanged(filters.copyWith(onlyWithoutDriver: v))),
                    _switch('Активные', filters.onlyActive, (v) => onChanged(filters.copyWith(onlyActive: v))),
                    _switch('Срочные', filters.isUrgent, (v) => onChanged(filters.copyWith(isUrgent: v))),
                    _switch('Гумпомощь', filters.isHumanitarian, (v) => onChanged(filters.copyWith(isHumanitarian: v))),
                    _switch('С фото', filters.hasPhoto, (v) => onChanged(filters.copyWith(hasPhoto: v))),
                    _switch('Готов сейчас', filters.isReady ?? false, (v) => onChanged(filters.copyWith(isReady: v))),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, int count, List<Widget> children) {
    return GridView.count(
      crossAxisCount: count,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: count == 1 ? 6.5 : 3.8,
      children: children,
    );
  }

  Widget _filterField({
    required String label,
    required IconData icon,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: onChanged,
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : '',
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      items: items.map((t) => DropdownMenuItem(value: t, child: Text(t.isEmpty ? 'Любой' : t))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _rangeField({
    required String labelFrom,
    required String labelTo,
    double? valFrom,
    double? valTo,
    required ValueChanged<double?> onFrom,
    required ValueChanged<double?> onTo,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: valFrom?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: labelFrom),
            onChanged: (v) => onFrom(_parseDouble(v)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: valTo?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: labelTo),
            onChanged: (v) => onTo(_parseDouble(v)),
          ),
        ),
      ],
    );
  }

  Widget _datePickerField(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: filters.loadingDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onChanged(filters.copyWith(loadingDate: picked, clearLoadingDate: picked == null));
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Дата погрузки',
          prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
        ),
        child: Text(
          filters.loadingDate == null ? 'Любая' : DateFormat('dd.MM.yyyy').format(filters.loadingDate!),
        ),
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          width: 40,
          child: Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
    final compact = MediaQuery.sizeOf(context).width < 800;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cargo.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (cargo.isUrgent) ...[
                          const SizedBox(width: 8),
                          _badge('СРОЧНО', Colors.red),
                        ],
                        if (cargo.isHumanitarian) ...[
                          const SizedBox(width: 8),
                          _badge('ГУМПОМОЩЬ', Colors.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    RouteBadge(
                      from: cargo.from,
                      to: cargo.to,
                      fontSize: 15,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CargoStatusBadge(status: cargo.status),
                  const SizedBox(height: 8),
                  IconButton(
                    tooltip: isFavorite
                        ? 'Убрать из отмеченных'
                        : 'Добавить в отмеченные',
                    onPressed: () => onToggleFavorite(cargo, !isFavorite),
                    icon: Icon(
                      isFavorite
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                      color: isFavorite
                          ? colors.primary
                          : colors.onSurfaceVariant.withOpacity(0.4),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (cargo.loadingDate != null)
                      _InfoChip(
                        icon: Icons.event_available_rounded,
                        label: DateFormat('dd.MM.yyyy').format(cargo.loadingDate!),
                      ),
                    if (cargo.weightKg != null)
                      _InfoChip(
                        icon: Icons.scale_rounded,
                        label: '${cargo.weightKg!.toStringAsFixed(1)} т',
                      ),
                    if (cargo.volumeM3 != null)
                      _InfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: '${cargo.volumeM3!.toStringAsFixed(1)} м³',
                      ),
                    if (cargo.bodyType?.isNotEmpty == true)
                      TruckBodyTypeBadge(bodyType: cargo.bodyType!),
                    if (cargo.truckType?.isNotEmpty == true)
                      _InfoChip(
                        icon: Icons.local_shipping_rounded,
                        label: cargo.truckType!,
                      ),
                    if (cargo.shipmentType != null)
                      _InfoChip(
                        icon: Icons.layers_outlined,
                        label: _shipmentLabel(cargo.shipmentType!),
                      ),
                    if (cargo.carCount != null && cargo.carCount! > 1)
                      _InfoChip(
                        icon: Icons.numbers_rounded,
                        label: '${cargo.carCount} авто',
                      ),
                    if (cargo.loadingType != null)
                      _InfoChip(
                        icon: Icons.move_to_inbox_rounded,
                        label: cargo.loadingType!,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              _buildPriceDisplay(colors),
            ],
          ),
          if (cargo.description?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.outlineVariant.withOpacity(0.2)),
              ),
              child: Text(
                cargo.description!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onSurface.withOpacity(0.85),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _actions(context),
                )
              : Row(children: [const Spacer(), ..._actions(context)]),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(ColorScheme colors) {
    if (cargo.price == null || cargo.price == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.secondaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Договорная',
          style: AppTextStyles.titleMedium.copyWith(
            color: colors.onSecondaryContainer,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    final formattedPrice = NumberFormat.decimalPattern('ru').format(cargo.price);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$formattedPrice ${cargo.currency ?? '₸'}',
          style: AppTextStyles.headlineSmall.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        if (cargo.paymentType != null)
          Text(
            cargo.paymentType!,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _shipmentLabel(String type) {
    switch (type) {
      case 'full':
        return 'Полная машина';
      case 'partial':
        return 'Догруз';
      case 'reload_possible':
        return 'Возможен перегруз';
      case 'only_separate':
        return 'Только отдельная';
      default:
        return type;
    }
  }

  List<Widget> _actions(BuildContext context) {
    final isOwner = cargo.ownerId == user.uid;
    final isAssignedDriver = cargo.driverId == user.uid;
    final canManage = isOwner || isAssignedDriver;

    final myApplication = applications.cast<CargoApplicationModel?>().firstWhere(
          (item) => item?.applicantId == user.uid,
          orElse: () => null,
        );
    final pendingCount = applications.where((item) => item.isPending).length;

    final widgets = <Widget>[
      AppButton(
        label: 'Чат',
        icon: Icons.chat_bubble_outline_rounded,
        variant: AppButtonVariant.secondary,
        onPressed: () => onOpenChat(cargo),
      ),
      const SizedBox(width: 12, height: 12),
      AppButton(
        label: cargo.photos.isNotEmpty ? 'Фото (${cargo.photos.length})' : 'Фото',
        icon: Icons.photo_library_outlined,
        variant: AppButtonVariant.secondary,
        onPressed: () => _showDocumentsDialog(context),
      ),
    ];

    // If I'm a driver and it's a public cargo (no driver assigned yet)
    if (user.canApplyToCargo && !isOwner && cargo.driverId == null) {
      widgets.add(const SizedBox(width: 12, height: 12));
      if (myApplication == null) {
        widgets.add(
          AppButton(
            label: 'Откликнуться',
            icon: Icons.how_to_reg_rounded,
            onPressed: () => _showApplyDialog(context),
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

    // Owner specific actions
    if (isOwner) {
      if (pendingCount > 0) {
        widgets.addAll([
          const SizedBox(width: 12, height: 12),
          AppButton(
            label: 'Отклики ($pendingCount)',
            icon: Icons.how_to_reg_rounded,
            variant: AppButtonVariant.primary,
            onPressed: () => _showApplicationsDialog(context),
          ),
        ]);
      }

      if (drivers.isNotEmpty && cargo.driverId == null) {
        widgets.addAll([
          const SizedBox(width: 12, height: 12),
          AppButton(
            label: 'Назначить',
            icon: Icons.assignment_ind_rounded,
            variant: AppButtonVariant.primary,
            onPressed: () => _showDriverDialog(context),
          ),
        ]);
      }
    }

    // Common management action
    if (canManage) {
      widgets.addAll([
        const SizedBox(width: 12, height: 12),
        AppButton(
          label: 'Статус',
          icon: Icons.swap_horiz_rounded,
          variant: AppButtonVariant.outlined,
          onPressed: () => _showStatusDialog(context),
        ),
      ]);
    }

    return widgets;
  }

  Color _applicationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
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
        children: CargoStatus.values
            .map(
              (status) => ListTile(
                leading: Icon(
                  status == cargo.status
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
                title: Text(CargoStatus.getDisplayStatus(status)),
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
