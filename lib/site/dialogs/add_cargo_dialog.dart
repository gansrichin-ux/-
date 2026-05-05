part of '../../main_site.dart';

class AddCargoDialog extends StatefulWidget {
  final String ownerId;

  const AddCargoDialog({super.key, required this.ownerId});

  @override
  State<AddCargoDialog> createState() => _AddCargoDialogState();
}

class _AddCargoDialogState extends State<AddCargoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _description = TextEditingController();
  final _weight = TextEditingController();
  final _volume = TextEditingController();
  final _distance = TextEditingController();
  final _price = TextEditingController();
  var _isSaving = false;
  String? _bodyType;
  DateTime? _loadingDate;

  @override
  void initState() {
    super.initState();
    _distance.addListener(_calculateRecommendedPrice);
    _weight.addListener(_calculateRecommendedPrice);
    _volume.addListener(_calculateRecommendedPrice);
  }

  void _calculateRecommendedPrice() {
    if (_price.text.isNotEmpty && !_price.text.contains('(Рек)')) return;
    
    final d = _parseDouble(_distance.text) ?? 0;
    final w = _parseDouble(_weight.text) ?? 0;
    final v = _parseDouble(_volume.text) ?? 0;
    
    if (d == 0) return;
    
    // Base rate: 300 KZT per km. Plus 50 KZT per ton per km, plus 10 KZT per m3 per km.
    final baseRatePerKm = 300.0;
    final weightRatePerKm = 50.0 * w;
    final volumeRatePerKm = 10.0 * v;
    
    final totalPerKm = baseRatePerKm + weightRatePerKm + volumeRatePerKm;
    final recommended = d * totalPerKm;
    
    if (recommended > 0) {
      _price.text = recommended.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _from.dispose();
    _to.dispose();
    _description.dispose();
    _weight.dispose();
    _volume.dispose();
    _distance.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      await CargoRepository.instance.addCargo(
        CargoModel(
          id: '',
          title: _title.text.trim(),
          from: _from.text.trim(),
          to: _to.text.trim(),
          status: 'Новый',
          ownerId: widget.ownerId,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          weightKg: _parseDouble(_weight.text),
          volumeM3: _parseDouble(_volume.text),
          distanceKm: _parseDouble(_distance.text),
          price: _parseDouble(_price.text),
          bodyType: _bodyType,
          loadingDate: _loadingDate,
        ),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось создать груз: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width < 720 ? width - 48 : 720),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Новый груз',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Закрыть',
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ResponsiveFields(
                  children: [
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Название',
                        prefixIcon: Icon(Icons.inventory_2_rounded),
                      ),
                      validator: _required,
                    ),
                    DropdownButtonFormField<String>(
                      value: _bodyType,
                      decoration: const InputDecoration(
                        labelText: 'Кузов',
                        prefixIcon: Icon(Icons.local_shipping_rounded),
                      ),
                      items:
                          const [
                                'Фура',
                                'Тент',
                                'Рефрижератор',
                                'Цистерна',
                                'Самосвал',
                                'Открытый',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) => setState(() => _bodyType = value),
                    ),
                    TextFormField(
                      controller: _from,
                      decoration: InputDecoration(
                        labelText: 'Откуда',
                        prefixIcon: const Icon(Icons.trip_origin_rounded),
                        suffixIcon: IconButton(
                          tooltip: 'Поменять местами',
                          icon: const Icon(Icons.swap_vert_rounded),
                          onPressed: () {
                            final temp = _from.text;
                            _from.text = _to.text;
                            _to.text = temp;
                          },
                        ),
                      ),
                      validator: _required,
                    ),
                    TextFormField(
                      controller: _to,
                      decoration: const InputDecoration(
                        labelText: 'Куда',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                      validator: _required,
                    ),
                    TextFormField(
                      controller: _weight,
                      decoration: const InputDecoration(
                        labelText: 'Вес, т',
                        prefixIcon: Icon(Icons.scale_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _optionalNumber,
                    ),
                    TextFormField(
                      controller: _volume,
                      decoration: const InputDecoration(
                        labelText: 'Объем, м3',
                        prefixIcon: Icon(Icons.view_in_ar_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _optionalNumber,
                    ),
                    TextFormField(
                      controller: _distance,
                      decoration: const InputDecoration(
                        labelText: 'Дистанция, км',
                        prefixIcon: Icon(Icons.route_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _optionalNumber,
                    ),
                    TextFormField(
                      controller: _price,
                      decoration: const InputDecoration(
                        labelText: 'Стоимость, ₸',
                        prefixIcon: Icon(Icons.payments_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _optionalNumber,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Дата погрузки',
                      prefixIcon: Icon(Icons.event_available_rounded),
                    ),
                    child: Text(
                      _loadingDate == null
                          ? 'Не выбрана'
                          : DateFormat('dd.MM.yyyy').format(_loadingDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Комментарий',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('Создать'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _loadingDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _loadingDate = picked);
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Заполните поле';
    return null;
  }

  String? _optionalNumber(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (_parseDouble(text) == null) return 'Введите число';
    return null;
  }
}

class _ResponsiveFields extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveFields({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 620;
        if (!twoColumns) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: child,
                  ),
                )
                .toList(),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
