import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/cargo_providers.dart';
import '../core/config/cargo_statuses.dart';

class SearchFilterBar extends ConsumerStatefulWidget {
  const SearchFilterBar({super.key});

  @override
  ConsumerState<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends ConsumerState<SearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _minDistanceController = TextEditingController();
  final TextEditingController _maxDistanceController = TextEditingController();
  final TextEditingController _minWeightController = TextEditingController();
  final TextEditingController _maxWeightController = TextEditingController();
  final TextEditingController _minVolumeController = TextEditingController();
  final TextEditingController _maxVolumeController = TextEditingController();
  final TextEditingController _minLengthController = TextEditingController();
  final TextEditingController _maxLengthController = TextEditingController();
  final TextEditingController _minHeightController = TextEditingController();
  final TextEditingController _maxHeightController = TextEditingController();
  final TextEditingController _minWidthController = TextEditingController();
  final TextEditingController _maxWidthController = TextEditingController();

  String? _selectedStatus;
  String? _selectedBodyType;
  String? _selectedLoadingType;
  String? _selectedPaymentType;
  DateTime? _loadingDateFrom;
  DateTime? _loadingDateTo;
  bool _showAdvancedFilters = false;

  final List<String> _statusOptions = [
    'Все',
    ...CargoStatus.values,
  ];

  final List<String> _bodyTypeOptions = [
    'Все',
    'Фура',
    'Тент',
    'Рефрижератор',
    'Цистерна',
    'Самосвал',
    'Открытый',
  ];

  final List<String> _loadingTypeOptions = [
    'Все',
    'Задняя',
    'Боковая',
    'Верхняя',
  ];

  final List<String> _paymentTypeOptions = [
    'Все',
    'Наличные',
    'Безналичный',
    'Смешанный',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fromController.addListener(_onFromChanged);
    _toController.addListener(_onToChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _fromController.removeListener(_onFromChanged);
    _toController.removeListener(_onToChanged);
    _searchController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _minDistanceController.dispose();
    _maxDistanceController.dispose();
    _minWeightController.dispose();
    _maxWeightController.dispose();
    _minVolumeController.dispose();
    _maxVolumeController.dispose();
    _minLengthController.dispose();
    _maxLengthController.dispose();
    _minHeightController.dispose();
    _maxHeightController.dispose();
    _minWidthController.dispose();
    _maxWidthController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref
        .read(cargoSearchFilterProvider.notifier)
        .setQuery(_searchController.text);
  }

  void _onFromChanged() {
    ref.read(cargoSearchFilterProvider.notifier).setFrom(_fromController.text);
  }

  void _onToChanged() {
    ref.read(cargoSearchFilterProvider.notifier).setTo(_toController.text);
  }

  void _onStatusChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    final filterStatus = status == 'Все' ? null : status;
    ref.read(cargoSearchFilterProvider.notifier).setStatus(filterStatus);
  }

  void _onBodyTypeChanged(String? bodyType) {
    setState(() {
      _selectedBodyType = bodyType;
    });
    final filterBodyType = bodyType == 'Все' ? null : bodyType;
    ref.read(cargoSearchFilterProvider.notifier).setBodyType(filterBodyType);
  }

  void _onLoadingTypeChanged(String? loadingType) {
    setState(() {
      _selectedLoadingType = loadingType;
    });
    final filterLoadingType = loadingType == 'Все' ? null : loadingType;
    ref
        .read(cargoSearchFilterProvider.notifier)
        .setLoadingType(filterLoadingType);
  }

  void _onPaymentTypeChanged(String? paymentType) {
    setState(() {
      _selectedPaymentType = paymentType;
    });
    final filterPaymentType = paymentType == 'Все' ? null : paymentType;
    ref
        .read(cargoSearchFilterProvider.notifier)
        .setPaymentType(filterPaymentType);
  }

  void _onDistanceRangeChanged() {
    final min = double.tryParse(_minDistanceController.text);
    final max = double.tryParse(_maxDistanceController.text);
    ref.read(cargoSearchFilterProvider.notifier).setDistanceRange(min, max);
  }

  void _onWeightRangeChanged() {
    final min = double.tryParse(_minWeightController.text);
    final max = double.tryParse(_maxWeightController.text);
    ref.read(cargoSearchFilterProvider.notifier).setWeightRange(min, max);
  }

  void _onVolumeRangeChanged() {
    final min = double.tryParse(_minVolumeController.text);
    final max = double.tryParse(_maxVolumeController.text);
    ref.read(cargoSearchFilterProvider.notifier).setVolumeRange(min, max);
  }

  void _onLengthRangeChanged() {
    final min = double.tryParse(_minLengthController.text);
    final max = double.tryParse(_maxLengthController.text);
    ref.read(cargoSearchFilterProvider.notifier).setLengthRange(min, max);
  }

  void _onHeightRangeChanged() {
    final min = double.tryParse(_minHeightController.text);
    final max = double.tryParse(_maxHeightController.text);
    ref.read(cargoSearchFilterProvider.notifier).setHeightRange(min, max);
  }

  void _onWidthRangeChanged() {
    final min = double.tryParse(_minWidthController.text);
    final max = double.tryParse(_maxWidthController.text);
    ref.read(cargoSearchFilterProvider.notifier).setWidthRange(min, max);
  }

  void _clearFilters() {
    _searchController.clear();
    _fromController.clear();
    _toController.clear();
    _minDistanceController.clear();
    _maxDistanceController.clear();
    _minWeightController.clear();
    _maxWeightController.clear();
    _minVolumeController.clear();
    _maxVolumeController.clear();
    _minLengthController.clear();
    _maxLengthController.clear();
    _minHeightController.clear();
    _maxHeightController.clear();
    _minWidthController.clear();
    _maxWidthController.clear();

    setState(() {
      _selectedStatus = 'Все';
      _selectedBodyType = 'Все';
      _selectedLoadingType = 'Все';
      _selectedPaymentType = 'Все';
      _loadingDateFrom = null;
      _loadingDateTo = null;
    });

    ref.read(cargoSearchFilterProvider.notifier).clearFilters();
  }

  Future<void> _selectLoadingDateFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loadingDateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _loadingDateFrom = picked;
      });
      ref
          .read(cargoSearchFilterProvider.notifier)
          .setLoadingDateRange(_loadingDateFrom, _loadingDateTo);
    }
  }

  Future<void> _selectLoadingDateTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loadingDateTo ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _loadingDateTo = picked;
      });
      ref
          .read(cargoSearchFilterProvider.notifier)
          .setLoadingDateRange(_loadingDateFrom, _loadingDateTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(cargoSearchFilterProvider);
    final hasActiveFilters =
        filter.query.isNotEmpty ||
        filter.status != null ||
        filter.from != null ||
        filter.to != null ||
        filter.minDistanceKm != null ||
        filter.maxDistanceKm != null ||
        filter.minWeightKg != null ||
        filter.maxWeightKg != null ||
        filter.minVolumeM3 != null ||
        filter.maxVolumeM3 != null ||
        filter.bodyType != null ||
        filter.loadingDateFrom != null ||
        filter.loadingDateTo != null ||
        filter.loadingType != null ||
        filter.paymentType != null ||
        filter.minLengthM != null ||
        filter.maxLengthM != null ||
        filter.minHeightM != null ||
        filter.maxHeightM != null ||
        filter.minWidthM != null ||
        filter.maxWidthM != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск по названию груза...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasActiveFilters
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearFilters,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Basic filters
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _fromController,
                  'Откуда',
                  Icons.location_on,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  _toController,
                  'Куда',
                  Icons.location_on_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Статус',
                  _selectedStatus ?? 'Все',
                  _statusOptions,
                  _onStatusChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  'Тип кузова',
                  _selectedBodyType ?? 'Все',
                  _bodyTypeOptions,
                  _onBodyTypeChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Advanced filters toggle
          InkWell(
            onTap: () {
              setState(() {
                _showAdvancedFilters = !_showAdvancedFilters;
              });
            },
            child: Row(
              children: [
                Icon(
                  _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Дополнительные фильтры',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Advanced filters
          if (_showAdvancedFilters) ...[
            _buildRangeFilter(
              'Расстояние (км)',
              _minDistanceController,
              _maxDistanceController,
              _onDistanceRangeChanged,
            ),
            const SizedBox(height: 12),

            _buildRangeFilter(
              'Вес (т)',
              _minWeightController,
              _maxWeightController,
              _onWeightRangeChanged,
            ),
            const SizedBox(height: 12),

            _buildRangeFilter(
              'Объем (м³)',
              _minVolumeController,
              _maxVolumeController,
              _onVolumeRangeChanged,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Тип загрузки',
                    _selectedLoadingType ?? 'Все',
                    _loadingTypeOptions,
                    _onLoadingTypeChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    'Оплата',
                    _selectedPaymentType ?? 'Все',
                    _paymentTypeOptions,
                    _onPaymentTypeChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date range
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Дата погрузки с',
                    _loadingDateFrom,
                    _selectLoadingDateFrom,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateField(
                    'Дата погрузки по',
                    _loadingDateTo,
                    _selectLoadingDateTo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dimensions
            _buildRangeFilter(
              'Длина (м)',
              _minLengthController,
              _maxLengthController,
              _onLengthRangeChanged,
            ),
            const SizedBox(height: 12),

            _buildRangeFilter(
              'Высота (м)',
              _minHeightController,
              _maxHeightController,
              _onHeightRangeChanged,
            ),
            const SizedBox(height: 12),

            _buildRangeFilter(
              'Ширина (м)',
              _minWidthController,
              _maxWidthController,
              _onWidthRangeChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: options.map((option) {
        final display = option == 'Все' ? option : CargoStatus.getDisplayStatus(option);
        return DropdownMenuItem(value: option, child: Text(display));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildRangeFilter(
    String label,
    TextEditingController minController,
    TextEditingController maxController,
    Function onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'От',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'До',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function onTap) {
    return InkWell(
      onTap: () => onTap(),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(
          date != null
              ? '${date.day}.${date.month}.${date.year}'
              : 'Выберите дату',
          style: TextStyle(color: date != null ? Colors.black : Colors.grey),
        ),
      ),
    );
  }
}
