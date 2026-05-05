import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/tracking_providers.dart';
import '../../models/cargo_tracking_model.dart';

class CargoTrackingScreen extends ConsumerStatefulWidget {
  final String cargoId;
  final String? cargoTitle;

  const CargoTrackingScreen({
    super.key,
    required this.cargoId,
    this.cargoTitle,
  });

  @override
  ConsumerState<CargoTrackingScreen> createState() => _CargoTrackingScreenState();
}

class _CargoTrackingScreenState extends ConsumerState<CargoTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final trackingInfo = ref.watch(cargoTrackingInfoProvider(widget.cargoId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cargoTitle ?? 'Отслеживание груза',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          if (trackingInfo.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            );
          }

          if (trackingInfo.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки данных',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trackingInfo.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return _buildTrackingContent(trackingInfo);
        },
      ),
    );
  }

  Widget _buildTrackingContent(CargoTrackingInfo info) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(cargoLocationProvider(widget.cargoId));
        ref.invalidate(cargoTrackingHistoryProvider(widget.cargoId));
        ref.invalidate(cargoTrackingStatsProvider(widget.cargoId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Карточка текущего статуса
            if (info.currentLocation != null) ...[
              _buildCurrentLocationCard(info.currentLocation!),
              const SizedBox(height: 16),
            ],

            // Карточка статистики
            if (info.stats != null) ...[
              _buildStatsCard(info.stats!),
              const SizedBox(height: 16),
            ],

            // Карточка ETA
            if (info.eta != null) ...[
              _buildETACard(info.eta!),
              const SizedBox(height: 16),
            ],

            // История отслеживания
            _buildHistorySection(info.history),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationCard(CargoTrackingModel location) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(location.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(location.status),
                  color: _getStatusColor(location.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Текущий статус',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _getStatusText(location.status),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(location.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Координаты',
                  '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                  Icons.location_on,
                ),
              ),
              if (location.speed != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    'Скорость',
                    '${location.speed!.toStringAsFixed(1)} км/ч',
                    Icons.speed,
                  ),
                ),
              ],
            ],
          ),
          if (location.notes != null && location.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Последнее обновление: ${_formatDateTime(location.timestamp)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(0xFF8B5CF6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Статистика маршрута',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Пройдено',
                  '${(stats['totalDistance'] as double).toStringAsFixed(1)} км',
                  Icons.straighten,
                  const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Средняя скорость',
                  '${(stats['averageSpeed'] as double).toStringAsFixed(1)} км/ч',
                  Icons.speed,
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
                  'В пути',
                  _formatDuration(stats['totalTime'] as Duration),
                  Icons.access_time,
                  const Color(0xFFF59E0B),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Остановки',
                  '${stats['stopCount']}',
                  Icons.pause_circle,
                  const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildETACard(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);
    final isLate = difference.isNegative;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLate ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLate ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF22C55E).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isLate ? const Color(0xFFEF4444).withOpacity(0.1) : const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isLate ? Icons.access_time : Icons.schedule,
              color: isLate ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLate ? 'Опоздание' : 'Ожидаемое время прибытия',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _formatDateTime(eta),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isLate ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List<TrackingHistoryPoint> history) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'История перемещений',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'История пуста',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final point = history[index];
                return _buildHistoryItem(point, index == history.length - 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(TrackingHistoryPoint point, bool isLast) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getStatusColor(point.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getStatusIcon(point.status),
                color: _getStatusColor(point.status),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(point.status),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(point.status),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(point.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.only(left: 16),
            height: 20,
            width: 2,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.inTransit:
        return const Color(0xFF3B82F6);
      case TrackingStatus.stopped:
        return const Color(0xFFF59E0B);
      case TrackingStatus.loading:
        return const Color(0xFF8B5CF6);
      case TrackingStatus.unloading:
        return const Color(0xFF6366F1);
      case TrackingStatus.delayed:
        return const Color(0xFFEF4444);
      case TrackingStatus.arrived:
        return const Color(0xFF22C55E);
    }
  }

  IconData _getStatusIcon(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.inTransit:
        return Icons.local_shipping;
      case TrackingStatus.stopped:
        return Icons.pause_circle;
      case TrackingStatus.loading:
        return Icons.inventory_2;
      case TrackingStatus.unloading:
        return Icons.unarchive;
      case TrackingStatus.delayed:
        return Icons.access_time;
      case TrackingStatus.arrived:
        return Icons.check_circle;
    }
  }

  String _getStatusText(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.inTransit:
        return 'В пути';
      case TrackingStatus.stopped:
        return 'Остановлен';
      case TrackingStatus.loading:
        return 'Загрузка';
      case TrackingStatus.unloading:
        return 'Разгрузка';
      case TrackingStatus.delayed:
        return 'Задержка';
      case TrackingStatus.arrived:
        return 'Прибыл';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}ч ${duration.inMinutes % 60}мин';
    } else {
      return '${duration.inMinutes}мин';
    }
  }
}
