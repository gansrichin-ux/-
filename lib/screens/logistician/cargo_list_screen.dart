import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cargo_model.dart';
import '../../core/router/app_router.dart';
import 'cargo_tracking_screen.dart';
import '../../widgets/search_filter_bar.dart';
import '../../core/providers/cargo_providers.dart';

class AppRoutes {
  static const String addCargo = '/add-cargo';
  static const String cargoDetails = '/cargo-details';
}

class CargoListScreen extends ConsumerStatefulWidget {
  const CargoListScreen({super.key});

  @override
  ConsumerState<CargoListScreen> createState() => _CargoListScreenState();
}

class _CargoListScreenState extends ConsumerState<CargoListScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    final filteredCargos = ref.watch(filteredCargosProvider);
    final filter = ref.watch(cargoSearchFilterProvider);
    final hasActiveFilters = filter.query.isNotEmpty || filter.status != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          ref.invalidate(filteredCargosProvider);
        },
        child: Column(
          children: [
            const SearchFilterBar(),
            Expanded(
              child: filteredCargos.isEmpty
                  ? hasActiveFilters
                      ? _EmptyFilterState(
                          onClear: () => ref
                              .read(cargoSearchFilterProvider.notifier)
                              .clearFilters(),
                        )
                      : _EmptyState(onAdd: () => _openAddCargo(context))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: filteredCargos.length,
                      itemBuilder: (context, index) {
                        final cargo = filteredCargos[index];
                        return _CargoCard(cargo: cargo);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddCargo(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _openAddCargo(BuildContext context) async {
    await AppRouter.toAddCargo(context);
    // Обновляем список после возвращения с экрана добавления
    ref.invalidate(filteredCargosProvider);
  }
}

class _CargoCard extends StatelessWidget {
  final CargoModel cargo;

  const _CargoCard({required this.cargo});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(cargo.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          AppRouter.toCargoDetails(context, cargo.id);
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
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cargo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cargo.from} → ${cargo.to}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (cargo.createdAt != null)
                          _buildInfoChip(
                            Icons.calendar_today,
                            _formatDate(cargo.createdAt!),
                          ),
                        if (cargo.weightKg != null)
                          _buildInfoChip(
                            Icons.scale,
                            '${cargo.weightKg!.toStringAsFixed(1)} т',
                          ),
                        if (cargo.bodyType != null)
                          _buildInfoChip(Icons.local_shipping, cargo.bodyType!),
                        if (cargo.volumeM3 != null)
                          _buildInfoChip(
                            Icons.inventory_2,
                            '${cargo.volumeM3!.toStringAsFixed(1)} м³',
                          ),
                        if (cargo.price != null)
                          _buildInfoChip(
                            Icons.attach_money,
                            '${cargo.price!.toStringAsFixed(0)} ₸',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                      cargo.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: const Icon(Icons.location_on_rounded, size: 20),
                    color: const Color(0xFF3B82F6),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 32,
                    ),
                    tooltip: 'Отследить груз',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CargoTrackingScreen(
                            cargoId: cargo.id,
                            cargoTitle: cargo.title,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Новый':
        return const Color(0xFF22C55E);
      case 'В пути':
        return const Color(0xFF3B82F6);
      case 'Доставлен':
        return const Color(0xFF10B981);
      case 'Отменен':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Нет грузов',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFFCBD5E1),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: onAdd, child: const Text('Добавить груз')),
        ],
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptyFilterState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Ничего не найдено',
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFFCBD5E1),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onClear,
            child: const Text('Очистить фильтры'),
          ),
        ],
      ),
    );
  }
}
