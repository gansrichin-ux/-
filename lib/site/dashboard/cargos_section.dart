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
          user: user,
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
                        ? (emptyTitle ?? 'РќРµС‚ РіСЂСѓР·РѕРІ')
                        : 'РќРёС‡РµРіРѕ РЅРµ РЅР°Р№РґРµРЅРѕ',
                    message: allCargos.isEmpty
                        ? (emptyMessage ?? 'РЎРѕР·РґР°Р№С‚Рµ РїРµСЂРІСѓСЋ Р·Р°СЏРІРєСѓ.')
                        : 'РР·РјРµРЅРёС‚Рµ РїРѕРёСЃРє РёР»Рё СЃС‚Р°С‚СѓСЃ.',
                    actionLabel: user.canCreateCargo ? 'РќРѕРІС‹Р№ РіСЂСѓР·' : null,
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
            'Р’СЃРµРіРѕ РІ СЂР°Р·РґРµР»Рµ: $total',
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
  final UserModel user;
  final CargoFilters filters;
  final List<String> bodyTypes;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<CargoFilters> onFiltersChanged;
  final VoidCallback? onAddCargo;

  const _CargoToolbar({
    required this.query,
    required this.status,
    required this.user,
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
              _StatusChips(status: status, user: user, onChanged: onStatusChanged),
              if (onAddCargo != null) ...[
                const SizedBox(width: 14),
                FilledButton.icon(
                  onPressed: onAddCargo,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('РќРѕРІС‹Р№ РіСЂСѓР·'),
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
                      user: user,
                      onChanged: onStatusChanged,
                    ),
                  ),
                  if (onAddCargo != null) ...[
                    const SizedBox(width: 10),
                    IconButton.filled(
                      tooltip: 'РќРѕРІС‹Р№ РіСЂСѓР·',
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
        hintText: 'РџРѕРёСЃРє РїРѕ РіСЂСѓР·Сѓ, РјР°СЂС€СЂСѓС‚Сѓ РёР»Рё РІРѕРґРёС‚РµР»СЋ',
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
      value: status ?? 'Р’СЃРµ',
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.tune_rounded),
        labelText: 'РЎС‚Р°С‚СѓСЃ',
      ),
      items: [
        const DropdownMenuItem<String>(value: 'Р’СЃРµ', child: Text('Р’СЃРµ')),
        ...CargoStatus.values.map(
          (status) =>
              DropdownMenuItem<String>(value: status, child: Text(CargoStatus.getDisplayStatus(status))),
        ),
      ],
      onChanged: (value) => onChanged(value == 'Р’СЃРµ' ? null : value),
    );
  }
}

class _StatusChips extends StatefulWidget {
  final String? status;
  final UserModel user;
  final ValueChanged<String?> onChanged;

  const _StatusChips({required this.status, required this.user, required this.onChanged});

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
    final isAdmin = widget.user.isAdmin;
    final publicStatuses = [
      CargoStatus.published,
      CargoStatus.confirmed,
      CargoStatus.delivered,
      CargoStatus.cancelled,
    ];
    final options = <String?>[null, ...(isAdmin ? CargoStatus.values : publicStatuses)];

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
              final label = value ?? 'Р’СЃРµ';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: selected
                      ? Icon(Icons.check_rounded, size: 16, color: colors.primary)
                      : null,
                  label: Text(value == null ? 'Р’СЃРµ' : CargoStatus.getDisplayStatus(value)),
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
        filters.isActive ? 'Активные фильтры (настроено)' : 'Расширенные фильтры',
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
                _buildRouteRow(context, compact),
                const SizedBox(height: 16),
                _buildGrid(
                  context,
                  compact ? 1 : 4,
                  [
                    _dropdownField(
                      label: 'Тип кузова',
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
                    _dropdownField(
                      label: 'Погрузка',
                      icon: Icons.layers_outlined,
                      value: filters.shipmentType ?? '',
                      items: ['', 'full', 'partial', 'reload_possible', 'only_separate'],
                      onChanged: (v) => onChanged(filters.copyWith(
                        shipmentType: v?.isEmpty == true ? null : v,
                        clearShipmentType: v?.isEmpty == true,
                      )),
                      itemBuilder: (v) => v.isEmpty ? 'Любая' : _shipmentLabel(v),
                    ),
                    _filterField(
                      label: 'Кол-во машин',
                      icon: Icons.numbers_rounded,
                      value: filters.carCount?.toString() ?? '',
                      onChanged: (v) => onChanged(filters.copyWith(
                        carCount: int.tryParse(v),
                        clearCarCount: v.isEmpty,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGrid(
                  context,
                  compact ? 1 : 4,
                  [
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
                    _switch('Без исполнителя', filters.onlyWithoutDriver, (v) => onChanged(filters.copyWith(onlyWithoutDriver: v))),
                    _switch('Актуальные', filters.onlyActive, (v) => onChanged(filters.copyWith(onlyActive: v))),
                    _switch('Срочные', filters.isUrgent, (v) => onChanged(filters.copyWith(isUrgent: v))),
                    _switch('Гумпомощь', filters.isHumanitarian, (v) => onChanged(filters.copyWith(isHumanitarian: v))),
                    _switch('С фото', filters.hasPhoto, (v) => onChanged(filters.copyWith(hasPhoto: v))),
                    _switch('Договорная цена', filters.priceNegotiable, (v) => onChanged(filters.copyWith(priceNegotiable: v))),
                    _switch('Готов', filters.isReady == true, (v) => onChanged(filters.copyWith(isReady: v, clearIsReady: !v))),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRouteRow(BuildContext context, bool compact) {
    return Row(
      children: [
        Expanded(
          child: _filterField(
            label: 'Откуда',
            icon: Icons.trip_origin_rounded,
            value: filters.from,
            onChanged: (v) => onChanged(filters.copyWith(from: v)),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Поменять местами',
          onPressed: () => onChanged(filters.copyWith(
            from: filters.to,
            to: filters.from,
          )),
          icon: const Icon(Icons.swap_horiz_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterField(
            label: 'Куда',
            icon: Icons.location_on_rounded,
            value: filters.to,
            onChanged: (v) => onChanged(filters.copyWith(to: v)),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 16),
          _switch('В обе стороны', filters.isTwoWaySearch, (v) => onChanged(filters.copyWith(isTwoWaySearch: v))),
        ],
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
    String Function(String)? itemBuilder,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : '',
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      items: items.map((t) => DropdownMenuItem(
        value: t, 
        child: Text(itemBuilder != null ? itemBuilder(t) : (t.isEmpty ? 'Любой' : t)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  String _shipmentLabel(String type) {
    switch (type) {
      case 'full': return 'Полная машина';
      case 'partial': return 'Догруз';
      case 'reload_possible': return 'Возможен догруз';
      case 'only_separate': return 'Только отдельная';
      default: return type;
    }
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
                          _badge('РЎР РћР§РќРћ', Colors.red),
                        ],
                        if (cargo.isHumanitarian) ...[
                          const SizedBox(width: 8),
                          _badge('Р“РЈРњРџРћРњРћР©Р¬', Colors.green),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (applications.isNotEmpty)
                        _InfoChip(
                          icon: Icons.people_outline_rounded,
                          label: '${applications.length} РѕС‚РєР»РёРєРѕРІ',
                          color: colors.primary,
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: isFavorite
                            ? 'РЈР±СЂР°С‚СЊ РёР· РѕС‚РјРµС‡РµРЅРЅС‹С…'
                            : 'Р”РѕР±Р°РІРёС‚СЊ РІ РѕС‚РјРµС‡РµРЅРЅС‹Рµ',
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
                        label: '${cargo.weightKg!.toStringAsFixed(1)} С‚',
                      ),
                    if (cargo.volumeM3 != null)
                      _InfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: '${cargo.volumeM3!.toStringAsFixed(1)} РјВі',
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
                    if (cargo.carCount != null)
                      _InfoChip(
                        icon: Icons.numbers_rounded,
                        label: '${cargo.carCount} Р°РІС‚Рѕ',
                      ),
                    if (cargo.loadingType != null)
                      _InfoChip(
                        icon: Icons.move_to_inbox_rounded,
                        label: cargo.loadingType!,
                      ),
                    if (cargo.isReady)
                      _InfoChip(
                        icon: Icons.task_alt_rounded,
                        label: 'Р“РѕС‚РѕРІ СЃРµР№С‡Р°СЃ',
                        color: Colors.green,
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
          color: colors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.primary.withOpacity(0.2)),
        ),
        child: Text(
          'Р¦РµРЅР° РґРѕРіРѕРІРѕСЂРЅР°СЏ',
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
          '$formattedPrice ${cargo.currency ?? 'в‚ё'}',
          style: AppTextStyles.titleLarge.copyWith(
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
        return 'РџРѕР»РЅР°СЏ РјР°С€РёРЅР°';
      case 'partial':
        return 'Р”РѕРіСЂСѓР·';
      case 'reload_possible':
        return 'Р’РѕР·РјРѕР¶РµРЅ РїРµСЂРµРіСЂСѓР·';
      case 'only_separate':
        return 'РўРѕР»СЊРєРѕ РѕС‚РґРµР»СЊРЅР°СЏ';
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
        label: 'Р§Р°С‚',
        icon: Icons.chat_bubble_outline_rounded,
        variant: AppButtonVariant.secondary,
        onPressed: () => onOpenChat(cargo),
      ),
      const SizedBox(width: 12, height: 12),
      AppButton(
        label: cargo.photos.isNotEmpty ? 'Р¤РѕС‚Рѕ (${cargo.photos.length})' : 'Р¤РѕС‚Рѕ РіСЂСѓР·Р°',
        icon: Icons.photo_library_outlined,
        variant: AppButtonVariant.secondary,
        onPressed: () => _showPhotosDialog(context),
      ),
    ];

    // If I'm a driver and it's a public cargo (no driver assigned yet)
    if (user.canApplyToCargo && !isOwner && cargo.driverId == null) {
      widgets.add(const SizedBox(width: 12, height: 12));
      if (myApplication == null) {
        widgets.add(
          AppButton(
            label: 'РћС‚РєР»РёРєРЅСѓС‚СЊСЃСЏ',
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
            label: 'РћС‚РєР»РёРєРё ($pendingCount)',
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
            label: 'РќР°Р·РЅР°С‡РёС‚СЊ',
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
          label: 'РЎС‚Р°С‚СѓСЃ',
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

  Future<void> _showPhotosDialog(BuildContext context) async {
    if (cargo.photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('РЈ СЌС‚РѕРіРѕ РіСЂСѓР·Р° РЅРµС‚ С„РѕС‚РѕРіСЂР°С„РёР№')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => _CargoPhotosDialog(cargo: cargo),
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
        title: const Text('РР·РјРµРЅРёС‚СЊ СЃС‚Р°С‚СѓСЃ'),
        children: (user.isAdmin
                ? CargoStatus.values
                : [
                    CargoStatus.published,
                    CargoStatus.delivered,
                    CargoStatus.confirmed,
                    CargoStatus.cancelled,
                  ])
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
        title: const Text('РќР°Р·РЅР°С‡РёС‚СЊ РІРѕРґРёС‚РµР»СЏ'),
        children: drivers
            .map(
              (driver) => ListTile(
                leading: const Icon(Icons.badge_rounded),
                title: Text(driver.displayName),
                subtitle: Text(driver.car ?? 'Р‘СЂРёРіР°РґР° / С‚СЂР°РЅСЃРїРѕСЂС‚ РЅРµ СѓРєР°Р·Р°РЅС‹'),
                trailing: IconButton(
                  tooltip: 'РџСЂРѕС„РёР»СЊ',
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
      title: const Text('РћС‚РєР»РёРєРЅСѓС‚СЊСЃСЏ РЅР° РіСЂСѓР·'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'РљРѕРјРјРµРЅС‚Р°СЂРёР№ РґР»СЏ Р»РѕРіРёСЃС‚Р°',
            hintText: 'РќР°РїСЂРёРјРµСЂ: СЃРІРѕР±РѕРґРµРЅ СЃРµРіРѕРґРЅСЏ, РµСЃС‚СЊ Р±СЂРёРіР°РґР° 3 С‡РµР»РѕРІРµРєР°',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('РћС‚РјРµРЅР°'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          icon: const Icon(Icons.send_rounded),
          label: const Text('РћС‚РїСЂР°РІРёС‚СЊ'),
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
      title: Text('РћС‚РєР»РёРєРё: ${cargo.title}'),
      content: SizedBox(
        width: 560,
        child: pending.isEmpty
            ? const _ProfileEmpty(
                icon: Icons.how_to_reg_outlined,
                title: 'РќРµС‚ РЅРѕРІС‹С… РѕС‚РєР»РёРєРѕРІ',
                message: 'РќРѕРІС‹Рµ РєР°РЅРґРёРґР°С‚С‹ РїРѕСЏРІСЏС‚СЃСЏ Р·РґРµСЃСЊ.',
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
                              label: const Text('РћС‚РєР»РѕРЅРёС‚СЊ'),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: () async {
                                await onDecision(application, cargo, true);
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('РџСЂРёРЅСЏС‚СЊ'),
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
          child: const Text('Р—Р°РєСЂС‹С‚СЊ'),
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
          label: 'Р”РѕРєСѓРјРµРЅС‚С‹ Рё РёР·РѕР±СЂР°Р¶РµРЅРёСЏ',
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
        const SnackBar(content: Text('Р”РѕРєСѓРјРµРЅС‚ РїСЂРёРєСЂРµРїР»РµРЅ')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('РќРµ СѓРґР°Р»РѕСЃСЊ Р·Р°РіСЂСѓР·РёС‚СЊ РґРѕРєСѓРјРµРЅС‚: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Р”РѕРєСѓРјРµРЅС‚С‹: ${widget.cargo.title}'),
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
                label: const Text('РџСЂРёРєСЂРµРїРёС‚СЊ С„Р°Р№Р»'),
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
                      title: 'Р”РѕРєСѓРјРµРЅС‚РѕРІ РЅРµС‚',
                      message:
                          'РџСЂРёРєСЂРµРїРёС‚Рµ РґРѕРіРѕРІРѕСЂ, РЅР°РєР»Р°РґРЅСѓСЋ, С‡РµРє РёР»Рё С„РѕС‚Рѕ РіСЂСѓР·Р°.',
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
          child: const Text('Р—Р°РєСЂС‹С‚СЊ'),
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
                  '${document.documentType.displayName} В· ${document.fileSizeFormatted} В· ${DateFormat('dd.MM.yyyy HH:mm').format(document.createdAt)}',
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
            tooltip: 'РћС‚РєСЂС‹С‚СЊ',
            onPressed: () => _openMediaUrl(document.fileUrl),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
          IconButton(
            tooltip: 'РЎРєР°С‡Р°С‚СЊ',
            onPressed: () =>
                _downloadMediaUrl(document.fileUrl, document.fileName),
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
    );
  }
}


class _CargoPhotosDialog extends StatelessWidget {
  final CargoModel cargo;

  const _CargoPhotosDialog({required this.cargo});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Фото груза: '),
      content: SizedBox(
        width: 800,
        height: 500,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cargo.photos.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () => _openMediaUrl(cargo.photos[index]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  cargo.photos[index],
                  fit: BoxFit.cover,
                ),
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
