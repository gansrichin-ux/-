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
  final _price = TextEditingController();
  final _carCount = TextEditingController(text: '1');
  
  var _isSaving = false;
  String? _bodyType;
  String? _truckType;
  String? _shipmentType = 'full';
  String _currency = '₸';
  DateTime? _loadingDate;
  bool _isUrgent = false;
  bool _isHumanitarian = false;
  bool _isReady = true;

  final List<XFile> _selectedPhotos = [];
  
  List<String> get bodyTypes => TruckBodyTypes.labels.values.toList();

  @override
  void dispose() {
    _title.dispose();
    _from.dispose();
    _to.dispose();
    _description.dispose();
    _weight.dispose();
    _volume.dispose();
    _price.dispose();
    _carCount.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _selectedPhotos.addAll(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 1. Create cargo model
      final cargo = CargoModel(
        id: '',
        title: _title.text.trim(),
        from: _from.text.trim(),
        to: _to.text.trim(),
        status: CargoStatus.published,
        ownerId: widget.ownerId,
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        weightKg: _parseDouble(_weight.text),
        volumeM3: _parseDouble(_volume.text),
        price: _parseDouble(_price.text),
        currency: _currency,
        bodyType: _bodyType,
        truckType: _truckType,
        shipmentType: _shipmentType,
        carCount: int.tryParse(_carCount.text) ?? 1,
        loadingDate: _loadingDate,
        isUrgent: _isUrgent,
        isHumanitarian: _isHumanitarian,
        isReady: _isReady,
        createdAt: DateTime.now(),
      );

      // 2. Save to Firestore to get ID
      final docRef = await FirebaseFirestore.instance.collection('cargos').add(cargo.toFirestoreMap());
      final cargoId = docRef.id;

      // 3. Upload photos if any
      if (_selectedPhotos.isNotEmpty) {
        final photoUrls = <String>[];
        for (var i = 0; i < _selectedPhotos.length; i++) {
          final file = _selectedPhotos[i];
          final bytes = await file.readAsBytes();
          final url = await CargoRepository.instance.uploadPhoto(
            cargoId,
            bytes,
            'photo_$i.jpg',
          );
          photoUrls.add(url);
        }
        await docRef.update({'photos': photoUrls});
      }

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
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width < 900 ? width - 48 : 860),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Основная информация'),
                      _ResponsiveFields(
                        children: [
                          TextFormField(
                            controller: _title,
                            decoration: const InputDecoration(
                              labelText: 'Что везем? (напр. Овощи, Стройматериалы)',
                              prefixIcon: Icon(Icons.inventory_2_rounded),
                            ),
                            validator: _required,
                          ),
                          _buildTruckTypeDropdown(),
                          TextFormField(
                            controller: _from,
                            decoration: const InputDecoration(
                              labelText: 'Пункт погрузки',
                              prefixIcon: Icon(Icons.trip_origin_rounded),
                            ),
                            validator: _required,
                          ),
                          TextFormField(
                            controller: _to,
                            decoration: const InputDecoration(
                              labelText: 'Пункт выгрузки',
                              prefixIcon: Icon(Icons.location_on_rounded),
                            ),
                            validator: _required,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Параметры груза и транспорта'),
                      _ResponsiveFields(
                        children: [
                          TextFormField(
                            controller: _weight,
                            decoration: const InputDecoration(
                              labelText: 'Вес, тонн',
                              prefixIcon: Icon(Icons.scale_rounded),
                            ),
                            keyboardType: TextInputType.number,
                            validator: _optionalNumber,
                          ),
                          TextFormField(
                            controller: _volume,
                            decoration: const InputDecoration(
                              labelText: 'Объем, м³',
                              prefixIcon: Icon(Icons.view_in_ar_rounded),
                            ),
                            keyboardType: TextInputType.number,
                            validator: _optionalNumber,
                          ),
                          _buildBodyTypeDropdown(),
                          TextFormField(
                            controller: _carCount,
                            decoration: const InputDecoration(
                              labelText: 'Кол-во машин',
                              prefixIcon: Icon(Icons.numbers_rounded),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          _buildShipmentTypeDropdown(),
                          _buildLoadingDateButton(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Оплата и условия'),
                      _ResponsiveFields(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _price,
                                  decoration: const InputDecoration(
                                    labelText: 'Ставка',
                                    prefixIcon: Icon(Icons.payments_rounded),
                                    hintText: '0 - договорная',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _currency,
                                  decoration: const InputDecoration(labelText: 'Валюта'),
                                  items: ['₸', '₽', '\$', '€']
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _currency = v!),
                                ),
                              ),
                            ],
                          ),
                          _buildBadgesRow(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Подробности и фото'),
                      TextFormField(
                        controller: _description,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Дополнительные сведения',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPhotoSection(colors),
                    ],
                  ),
                ),
              ),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_box_rounded, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            'Опубликовать груз',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton(
            label: 'Отмена',
            variant: AppButtonVariant.secondary,
            onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: _isSaving ? 'Сохранение...' : 'Опубликовать груз',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTruckTypeDropdown() {
    return AppDropdown<String>(
      label: 'Тип транспорта',
      value: _truckType,
      items: ['Автовоз', 'Газель', 'Трал', 'Микроавтобус', 'Легковая']
          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
          .toList(),
      onChanged: (v) => setState(() => _truckType = v),
    );
  }

  Widget _buildBodyTypeDropdown() {
    return AppDropdown<String>(
      label: 'Тип кузова',
      value: _bodyType,
      items: bodyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _bodyType = v),
    );
  }

  Widget _buildShipmentTypeDropdown() {
    return AppDropdown<String>(
      label: 'Погрузка',
      value: _shipmentType,
      items: const [
        DropdownMenuItem(value: 'full', child: Text('Полная машина')),
        DropdownMenuItem(value: 'partial', child: Text('Догруз')),
      ],
      onChanged: (v) => setState(() => _shipmentType = v),
    );
  }

  Widget _buildLoadingDateButton() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Дата погрузки',
          prefixIcon: Icon(Icons.event_available_rounded),
        ),
        child: Text(
          _loadingDate == null ? 'Выберите дату' : DateFormat('dd.MM.yyyy').format(_loadingDate!),
          style: TextStyle(
            color: _loadingDate == null ? Colors.grey : null,
            fontWeight: _loadingDate == null ? null : FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgesRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: _isUrgent,
                title: const Text('Срочно', style: TextStyle(fontSize: 14)),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _isUrgent = v!),
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                value: _isHumanitarian,
                title: const Text('Гумпомощь', style: TextStyle(fontSize: 14)),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _isHumanitarian = v!),
              ),
            ),
          ],
        ),
        CheckboxListTile(
          value: _isReady,
          title: const Text('Готов к погрузке сейчас', style: TextStyle(fontSize: 14)),
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _isReady = v!),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.camera_alt_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Фото груза (рекомендуется)',
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Добавить'),
            ),
          ],
        ),
        if (_selectedPhotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _selectedPhotos[index].path,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: colors.error,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, size: 14, color: Colors.white),
                          onPressed: () => setState(() => _selectedPhotos.removeAt(index)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _loadingDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
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
