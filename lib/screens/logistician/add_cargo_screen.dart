import 'package:flutter/material.dart';
import '../../core/config/cargo_statuses.dart';
import '../../repositories/cargo_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../models/cargo_model.dart';

class AddCargoScreen extends StatefulWidget {
  const AddCargoScreen({super.key});

  @override
  State<AddCargoScreen> createState() => _AddCargoScreenState();
}

class _AddCargoScreenState extends State<AddCargoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _volumeController = TextEditingController();
  final _carCountController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  String? _selectedBodyType;
  String? _selectedTruckType;
  String? _selectedShipmentType = 'full';
  String _selectedCurrency = '₸';
  DateTime? _loadingDate;
  bool _isUrgent = false;
  bool _isHumanitarian = false;
  bool _isReady = true;

  bool _isLoading = false;
  final List<XFile> _selectedPhotos = [];

  final List<String> _bodyTypeOptions = bodyTypes;
  final List<String> _truckTypeOptions = ['Автовоз', 'Газель', 'Трал', 'Микроавтобус', 'Легковая'];

  @override
  void dispose() {
    _titleController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _carCountController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _selectedPhotos.addAll(picked));
    }
  }

  Future<void> _saveCargo() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      final ownerId = AuthRepository.instance.currentUser?.uid;
      if (ownerId == null) throw Exception('Пользователь не авторизован');

      final cargo = CargoModel(
        id: '',
        title: _titleController.text.trim(),
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
        status: CargoStatus.published,
        ownerId: ownerId,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        weightKg: double.tryParse(_weightController.text),
        volumeM3: double.tryParse(_volumeController.text),
        price: double.tryParse(_priceController.text),
        currency: _selectedCurrency,
        bodyType: _selectedBodyType,
        truckType: _selectedTruckType,
        shipmentType: _selectedShipmentType,
        carCount: int.tryParse(_carCountController.text) ?? 1,
        loadingDate: _loadingDate,
        isUrgent: _isUrgent,
        isHumanitarian: _isHumanitarian,
        isReady: _isReady,
        createdAt: DateTime.now(),
      );

      // 1. Save cargo
      final docRef = await FirebaseFirestore.instance.collection('cargos').add(cargo.toFirestoreMap());
      final cargoId = docRef.id;

      // 2. Upload photos
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

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLoadingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loadingDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _loadingDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый груз')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Основная информация'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Что везем? *',
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите название' : null,
              ),
              const SizedBox(height: 12),
              _buildTruckTypeDropdown(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fromController,
                decoration: const InputDecoration(
                  labelText: 'Откуда *',
                  prefixIcon: Icon(Icons.trip_origin_rounded, color: Colors.blue),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите пункт погрузки' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'Куда *',
                  prefixIcon: Icon(Icons.location_on_rounded, color: Colors.orange),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите пункт выгрузки' : null,
              ),
              const SizedBox(height: 28),
              _label('Параметры груза'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Вес, т', prefixIcon: Icon(Icons.scale_rounded)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _volumeController,
                      decoration: const InputDecoration(labelText: 'Объем, м³', prefixIcon: Icon(Icons.view_in_ar_rounded)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildBodyTypeDropdown()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _carCountController,
                      decoration: const InputDecoration(labelText: 'Машин', prefixIcon: Icon(Icons.numbers_rounded)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildShipmentTypeDropdown(),
              const SizedBox(height: 12),
              _buildLoadingDateButton(),
              const SizedBox(height: 28),
              _label('Оплата'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Ставка', prefixIcon: Icon(Icons.payments_rounded)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: const InputDecoration(labelText: 'Валюта'),
                      items: ['₸', '₽', '$', '€'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCurrency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBadgesGrid(),
              const SizedBox(height: 28),
              _label('Дополнительно'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Дополнительные сведения',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildPhotoSection(),
              const SizedBox(height: 36),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveCargo,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Создать заявку'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ОТМЕНА', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTruckTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTruckType,
      decoration: const InputDecoration(labelText: 'Тип транспорта', prefixIcon: Icon(Icons.local_shipping_rounded)),
      items: _truckTypeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _selectedTruckType = v),
    );
  }

  Widget _buildBodyTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBodyType,
      decoration: const InputDecoration(labelText: 'Кузов', prefixIcon: Icon(Icons.inventory_rounded)),
      items: _bodyTypeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _selectedBodyType = v),
    );
  }

  Widget _buildShipmentTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedShipmentType,
      decoration: const InputDecoration(labelText: 'Погрузка', prefixIcon: Icon(Icons.move_to_inbox_rounded)),
      items: const [
        DropdownMenuItem(value: 'full', child: Text('Полная машина')),
        DropdownMenuItem(value: 'partial', child: Text('Догруз')),
      ],
      onChanged: (v) => setState(() => _selectedShipmentType = v),
    );
  }

  Widget _buildLoadingDateButton() {
    return InkWell(
      onTap: _selectLoadingDate,
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Дата погрузки', prefixIcon: Icon(Icons.calendar_today_rounded)),
        child: Text(_loadingDate == null ? 'Выберите дату' : DateFormat('dd.MM.yyyy').format(_loadingDate!)),
      ),
    );
  }

  Widget _buildBadgesGrid() {
    return Column(
      children: [
        CheckboxListTile(
          value: _isUrgent,
          title: const Text('Срочный груз'),
          onChanged: (v) => setState(() => _isUrgent = v!),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        CheckboxListTile(
          value: _isHumanitarian,
          title: const Text('Гуманитарная помощь'),
          onChanged: (v) => setState(() => _isHumanitarian = v!),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        CheckboxListTile(
          value: _isReady,
          title: const Text('Готов к погрузке сейчас'),
          onChanged: (v) => setState(() => _isReady = v!),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            const Text('Фото груза', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickPhotos,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Добавить'),
            ),
          ],
        ),
        if (_selectedPhotos.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(_selectedPhotos[index].path, width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPhotos.removeAt(index)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      );
}
