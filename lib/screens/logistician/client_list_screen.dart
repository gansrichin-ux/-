import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/client_providers.dart';
import '../../core/services/client_service.dart';
import '../../models/client_model.dart';
import '../../repositories/auth_repository.dart';

const _bg = Color(0xFF0B1220);
const _surface = Color(0xFF111827);
const _outline = Color(0xFF263247);
const _mutedText = Color(0xFF94A3B8);

enum _ClientAction { edit, delete }

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allClientsAsync = ref.watch(allClientsProvider);
    final filteredClients = ref.watch(filteredClientsProvider);
    final stats = ref.watch(clientStatsProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: allClientsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: _mutedText),
              const SizedBox(height: 16),
              const Text(
                'Ошибка загрузки клиентов',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 14, color: _mutedText),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (clients) => _buildClientList(filteredClients, stats),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClientScreen()),
          );
          if (!mounted) return;
          ref.invalidate(allClientsProvider);
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildClientList(
    List<ClientModel> clients,
    Map<String, dynamic> stats,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allClientsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildClientToolbar(),

            // Статистика
            if (stats.isNotEmpty) _buildStatsSection(stats),

            // Список клиентов
            if (clients.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return _ClientCard(client: client);
                },
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildClientToolbar() {
    final filter = ref.watch(clientSearchFilterProvider);
    final hasActiveFilters = filter.query.isNotEmpty || filter.isActive != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск клиентов...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: hasActiveFilters
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(clientSearchFilterProvider.notifier).state =
                              const ClientSearchFilter();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(clientSearchFilterProvider.notifier).state = ref
                    .read(clientSearchFilterProvider)
                    .copyWith(query: value);
              },
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.tune_rounded, color: Color(0xFF3B82F6)),
              onSelected: (value) {
                switch (value) {
                  case 'active':
                    ref.read(clientSearchFilterProvider.notifier).state =
                        const ClientSearchFilter(isActive: true);
                    break;
                  case 'inactive':
                    ref.read(clientSearchFilterProvider.notifier).state =
                        const ClientSearchFilter(isActive: false);
                    break;
                  case 'all':
                    ref.read(clientSearchFilterProvider.notifier).state =
                        const ClientSearchFilter();
                    _searchController.clear();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'all', child: Text('Все клиенты')),
                const PopupMenuItem(value: 'active', child: Text('Активные')),
                const PopupMenuItem(
                  value: 'inactive',
                  child: Text('Неактивные'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Статистика клиентов',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Всего клиентов',
                  '${stats['totalClients'] ?? 0}',
                  Icons.people,
                  const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Активные',
                  '${stats['activeClients'] ?? 0}',
                  Icons.check_circle,
                  const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Общий доход',
                  '${(stats['totalRevenue'] ?? 0.0).toStringAsFixed(0)} ₽',
                  Icons.attach_money,
                  const Color(0xFF8B5CF6),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Всего заказов',
                  '${stats['totalOrders'] ?? 0}',
                  Icons.shopping_cart,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _mutedText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Клиенты не найдены',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFFCBD5E1),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте первого клиента или измените параметры поиска',
            style: const TextStyle(fontSize: 14, color: _mutedText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends ConsumerWidget {
  final ClientModel client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = client.isActive
        ? const Color(0xFF22C55E)
        : const Color(0xFF94A3B8);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientDetailsScreen(client: client),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_rounded, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (client.company != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        client.company!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _mutedText, fontSize: 13),
                      ),
                    ],
                    if (client.phone != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        client.phone!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: statusColor.withOpacity(0.28),
                          ),
                        ),
                        child: Text(
                          client.isActive ? 'Активен' : 'Неактивен',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: PopupMenuButton<_ClientAction>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          tooltip: 'Действия',
                          onSelected: (action) =>
                              _handleAction(context, ref, action),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _ClientAction.edit,
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Редактировать'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: _ClientAction.delete,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 18,
                                    color: Color(0xFFEF4444),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Удалить'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${client.totalOrders} заказов',
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _ClientAction action,
  ) async {
    switch (action) {
      case _ClientAction.edit:
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => EditClientScreen(client: client),
          ),
        );
        if (changed == true) {
          ref.invalidate(allClientsProvider);
        }
        break;
      case _ClientAction.delete:
        await _confirmAndDelete(context, ref);
        break;
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить клиента?'),
        content: Text(
          'Клиент "${client.name}" будет удален без восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = await ClientService.instance.deleteClient(client.id);
    if (!context.mounted) return;

    ref.invalidate(allClientsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(deleted ? 'Клиент удален' : 'Не удалось удалить клиента'),
        backgroundColor: deleted
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444),
      ),
    );
  }
}

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('Новый клиент')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя клиента *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя клиента';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Компания',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Адрес',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Заметки',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveClient,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Сохранить клиента',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveClient() async {
    if (_formKey.currentState!.validate()) {
      final ownerId = AuthRepository.instance.currentUser?.uid;
      if (ownerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пользователь не авторизован'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      final client = ClientModel(
        id: '', // Будет сгенерирован в сервисе
        name: _nameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        company: _companyController.text.isNotEmpty
            ? _companyController.text
            : null,
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        ownerId: ownerId,
        createdAt: DateTime.now(),
        isActive: true,
      );

      try {
        // Здесь будет вызов сервиса для сохранения клиента
        final clientService = ClientService.instance;
        await clientService.createClient(client);

        if (!mounted) return;

        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Клиент успешно добавлен'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}

class EditClientScreen extends StatefulWidget {
  final ClientModel client;

  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _companyController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    _nameController = TextEditingController(text: client.name);
    _phoneController = TextEditingController(text: client.phone ?? '');
    _emailController = TextEditingController(text: client.email ?? '');
    _companyController = TextEditingController(text: client.company ?? '');
    _addressController = TextEditingController(text: client.address ?? '');
    _notesController = TextEditingController(text: client.notes ?? '');
    _isActive = client.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('Редактировать клиента')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя клиента *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя клиента';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Компания',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Адрес',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Заметки',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _outline),
                ),
                child: SwitchListTile(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: const Text('Активный клиент'),
                  subtitle: const Text('Показывать клиента как активного'),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveClient,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Сохранить изменения',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    final client = ClientModel(
      id: widget.client.id,
      name: _nameController.text.trim(),
      phone: _emptyToNull(_phoneController.text),
      email: _emptyToNull(_emailController.text),
      company: _emptyToNull(_companyController.text),
      address: _emptyToNull(_addressController.text),
      notes: _emptyToNull(_notesController.text),
      ownerId: widget.client.ownerId,
      createdAt: widget.client.createdAt,
      lastContactDate: widget.client.lastContactDate,
      totalOrders: widget.client.totalOrders,
      totalRevenue: widget.client.totalRevenue,
      isActive: _isActive,
    );

    final updated = await ClientService.instance.updateClient(client);
    if (!mounted) return;

    if (updated) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Клиент обновлен'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить изменения'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class ClientDetailsScreen extends ConsumerWidget {
  final ClientModel client;

  const ClientDetailsScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Редактировать',
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditClientScreen(client: client),
                ),
              );
              if (changed != true || !context.mounted) return;
              ref.invalidate(allClientsProvider);
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            color: const Color(0xFFEF4444),
            tooltip: 'Удалить',
            onPressed: () => _confirmAndDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard('Основная информация', [
              _buildInfoItem('Имя', client.name),
              if (client.company != null)
                _buildInfoItem('Компания', client.company!),
              if (client.phone != null)
                _buildInfoItem('Телефон', client.phone!),
              if (client.email != null) _buildInfoItem('Email', client.email!),
              if (client.address != null)
                _buildInfoItem('Адрес', client.address!),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Статистика', [
              _buildInfoItem('Всего заказов', '${client.totalOrders}'),
              _buildInfoItem(
                'Общий доход',
                '${client.totalRevenue.toStringAsFixed(2)} ₽',
              ),
              _buildInfoItem(
                'Статус',
                client.isActive ? 'Активен' : 'Неактивен',
              ),
              _buildInfoItem(
                'Дата регистрации',
                '${client.createdAt.day}.${client.createdAt.month}.${client.createdAt.year}',
              ),
            ]),
            if (client.notes != null && client.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Заметки', [Text(client.notes!)]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: _mutedText, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить клиента?'),
        content: Text('Клиент "$client.name" будет удален без восстановления.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = await ClientService.instance.deleteClient(client.id);
    if (!context.mounted) return;

    ref.invalidate(allClientsProvider);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(deleted ? 'Клиент удален' : 'Не удалось удалить клиента'),
        backgroundColor: deleted
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444),
      ),
    );
  }
}
