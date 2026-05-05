import 'package:flutter/material.dart';
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
  final _distanceController = TextEditingController();
  final _lengthController = TextEditingController();
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedBodyType;
  String? _selectedLoadingType;
  String? _selectedPaymentType;
  DateTime? _loadingDate;

  bool _isLoading = false;

  final List<String> _bodyTypeOptions = [
    'Фура',
    'Тент',
    'Рефрижератор',
    'Цистерна',
    'Самосвал',
    'Открытый',
  ];

  final List<String> _loadingTypeOptions = ['Задняя', 'Боковая', 'Верхняя'];

  final List<String> _paymentTypeOptions = [
    'Наличные',
    'Безналичный',
    'Смешанный',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _distanceController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveCargo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final ownerId = AuthRepository.instance.currentUser?.uid;
      if (ownerId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final weight = double.tryParse(_weightController.text.trim());
      final volume = double.tryParse(_volumeController.text.trim());
      final distance = double.tryParse(_distanceController.text.trim());
      final length = double.tryParse(_lengthController.text.trim());
      final height = double.tryParse(_heightController.text.trim());
      final width = double.tryParse(_widthController.text.trim());
      final price = double.tryParse(_priceController.text.trim());

      final cargo = CargoModel(
        id: '',
        title: _titleController.text.trim(),
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
        status: 'Новый',
        ownerId: ownerId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        weightKg: weight,
        volumeM3: volume,
        distanceKm: distance,
        bodyType: _selectedBodyType,
        loadingDate: _loadingDate,
        loadingType: _selectedLoadingType,
        paymentType: _selectedPaymentType,
        lengthM: length,
        heightM: height,
        widthM: width,
        price: price,
      );
      await CargoRepository.instance.addCargo(cargo);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLoadingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loadingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _loadingDate = picked;
      });
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
                  labelText: 'Название груза *',
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Укажите название' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание / комментарий',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Вес, т',
                  prefixIcon: Icon(Icons.scale_rounded),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) return 'Введите число';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _volumeController,
                decoration: const InputDecoration(
                  labelText: 'Объем, м³',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) return 'Введите число';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Расстояние, км',
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) return 'Введите число';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Стоимость, ₸',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) return 'Введите число';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              _label('Маршрут'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fromController,
                decoration: const InputDecoration(
                  labelText: 'Откуда (город или адрес) *',
                  prefixIcon: Icon(
                    Icons.trip_origin_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Укажите пункт отправления'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'Куда (город или адрес) *',
                  prefixIcon: Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Укажите пункт назначения'
                    : null,
              ),
              const SizedBox(height: 28),
              _label('Характеристики груза'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedBodyType,
                decoration: const InputDecoration(
                  labelText: 'Тип кузова',
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                items: _bodyTypeOptions.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBodyType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLoadingType,
                decoration: const InputDecoration(
                  labelText: 'Тип загрузки',
                  prefixIcon: Icon(Icons.upload),
                ),
                items: _loadingTypeOptions.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLoadingType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPaymentType,
                decoration: const InputDecoration(
                  labelText: 'Оплата',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _paymentTypeOptions.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectLoadingDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дата погрузки',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _loadingDate != null
                        ? '${_loadingDate!.day}.${_loadingDate!.month}.${_loadingDate!.year}'
                        : 'Выберите дату',
                    style: TextStyle(
                      color: _loadingDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _label('Габариты (м)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lengthController,
                      decoration: const InputDecoration(
                        labelText: 'Длина',
                        prefixIcon: Icon(Icons.height),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (double.tryParse(v.trim()) == null) {
                          return 'Введите число';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Высота',
                        prefixIcon: Icon(Icons.vertical_align_top),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (double.tryParse(v.trim()) == null) {
                          return 'Введите число';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      decoration: const InputDecoration(
                        labelText: 'Ширина',
                        prefixIcon: Icon(Icons.width_wide),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (double.tryParse(v.trim()) == null) {
                          return 'Введите число';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
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
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
