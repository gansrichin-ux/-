part of '../../main_site.dart';

class AddTransportDialog extends StatefulWidget {
  final UserModel owner;

  const AddTransportDialog({super.key, required this.owner});

  @override
  State<AddTransportDialog> createState() => _AddTransportDialogState();
}

class _AddTransportDialogState extends State<AddTransportDialog> {
  final _formKey = GlobalKey<FormState>();

  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _capacityController = TextEditingController(text: '1.5');
  final _volumeController = TextEditingController(text: '10.0');
  final _directionsController = TextEditingController();

  String _type = 'hitch';
  String _bodyType = TruckBodyTypes.truck;
  String _paymentType = 'cash';

  bool _hasAdr = false;
  bool _hasGps = false;
  bool _hasTir = false;
  bool _allowsReload = true;

  DateTime? _availableFrom;
  bool _isSaving = false;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _capacityController.dispose();
    _volumeController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: AppCard(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_rounded, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Добавить транспорт',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 24),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AppDropdown<String>(
                          label: 'Тип ТС',
                          value: _type,
                          items: const [
                            DropdownMenuItem(
                                value: 'hitch', child: Text('Сцепка')),
                            DropdownMenuItem(
                                value: 'solo', child: Text('Одиночка')),
                          ],
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppDropdown<String>(
                          label: 'Тип кузова',
                          value: _bodyType,
                          items: TruckBodyTypes.labels.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _bodyType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Марка',
                          hint: 'Напр. Mercedes',
                          controller: _brandController,
                          validator: (v) =>
                              v?.isEmpty == true ? 'Укажите марку' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          label: 'Модель',
                          hint: 'Напр. Sprinter',
                          controller: _modelController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Гос. номер',
                          hint: '001ABC01',
                          controller: _plateController,
                          validator: (v) =>
                              v?.isEmpty == true ? 'Укажите номер' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppDropdown<String>(
                          label: 'Оплата',
                          value: _paymentType,
                          items: const [
                            DropdownMenuItem(
                                value: 'cash', child: Text('Наличные')),
                            DropdownMenuItem(
                                value: 'cashless', child: Text('Безнал')),
                            DropdownMenuItem(
                                value: 'to_card', child: Text('На карту')),
                          ],
                          onChanged: (v) => setState(() => _paymentType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Грузоподъемность (т)',
                          controller: _capacityController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          label: 'Объем (м³)',
                          controller: _volumeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Дополнительные опции',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    children: [
                      _buildSwitch(
                          'ADR', _hasAdr, (v) => setState(() => _hasAdr = v)),
                      _buildSwitch(
                          'GPS', _hasGps, (v) => setState(() => _hasGps = v)),
                      _buildSwitch(
                          'TIR', _hasTir, (v) => setState(() => _hasTir = v)),
                      _buildSwitch('Догруз', _allowsReload,
                          (v) => setState(() => _allowsReload = v)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'Предпочтительные направления',
                    hint: 'Алматы, Астана, Шымкент (через запятую)',
                    controller: _directionsController,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Доступен с даты',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(_availableFrom == null
                        ? 'Сейчас'
                        : DateFormat('dd.MM.yyyy').format(_availableFrom!)),
                    trailing: AppButton(
                      label: 'Выбрать',
                      onPressed: _selectDate,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: _isSaving ? 'Сохранение...' : 'Создать транспорт',
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _save,
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _availableFrom = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final directions = _directionsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final transport = TransportModel(
        id: '',
        ownerId: widget.owner.uid,
        ownerName: widget.owner.displayName,
        ownerPhotoUrl: widget.owner.avatarUrl,
        type: _type,
        brand: _brandController.text,
        model: _modelController.text,
        plateNumber: _plateController.text,
        bodyType: _bodyType,
        capacityTons: double.tryParse(_capacityController.text) ?? 0,
        volumeM3: double.tryParse(_volumeController.text) ?? 0,
        hasAdr: _hasAdr,
        hasGps: _hasGps,
        hasTir: _hasTir,
        paymentType: _paymentType,
        allowsReload: _allowsReload,
        preferredDirections: directions,
        availableFrom: _availableFrom ?? DateTime.now(),
        status: 'available',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await TransportRepository.instance.createTransport(transport);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
