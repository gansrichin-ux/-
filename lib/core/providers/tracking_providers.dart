import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tracking_service.dart';
import '../../models/cargo_tracking_model.dart';

/// Провайдер для сервиса отслеживания
final trackingServiceProvider = Provider<TrackingService>((ref) {
  return TrackingService();
});

/// Провайдер текущего местоположения груза
final cargoLocationProvider =
    StreamProvider.family<CargoTrackingModel?, String>((ref, cargoId) {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.getCurrentLocation(cargoId);
});

/// Провайдер истории отслеживания груза
final cargoTrackingHistoryProvider =
    StreamProvider.family<List<TrackingHistoryPoint>, String>((ref, cargoId) {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.getTrackingHistory(cargoId);
});

/// Провайдер всех активных отслеживаний
final allActiveTrackingProvider =
    StreamProvider<List<CargoTrackingModel>>((ref) {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.getAllActiveTracking();
});

/// Провайдер отслеживаний для конкретного водителя
final driverTrackingProvider =
    StreamProvider.family<List<CargoTrackingModel>, String>((ref, driverId) {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.getDriverActiveTracking(driverId);
});

/// Провайдер статистики отслеживания груза
final cargoTrackingStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, cargoId) async {
  final trackingService = ref.watch(trackingServiceProvider);
  return await trackingService.getCargoTrackingStats(cargoId);
});

/// Провайдер для расчета ETA (времени прибытия)
final cargoETAProvider =
    FutureProvider.family<DateTime?, String>((ref, cargoId) async {
  final trackingService = ref.watch(trackingServiceProvider);
  final location = await ref.watch(cargoLocationProvider(cargoId).future);

  if (location == null) return null;

  // Здесь нужно получить координаты назначения из груза
  // В реальном приложении это будет получено из CargoModel
  // Пока используем заглушку
  return trackingService.calculateETA(
    currentLat: location.latitude,
    currentLon: location.longitude,
    destinationLat: 55.7558, // Москва (заглушка)
    destinationLon: 37.6176,
    averageSpeed: 60.0, // 60 км/ч (заглушка)
  );
});

/// Комбинированный провайдер для детальной информации об отслеживании
class CargoTrackingInfo {
  final CargoTrackingModel? currentLocation;
  final List<TrackingHistoryPoint> history;
  final Map<String, dynamic>? stats;
  final DateTime? eta;
  final bool isLoading;
  final Object? error;

  const CargoTrackingInfo({
    this.currentLocation,
    this.history = const [],
    this.stats,
    this.eta,
    this.isLoading = false,
    this.error,
  });
}

final cargoTrackingInfoProvider =
    Provider.family<CargoTrackingInfo, String>((ref, cargoId) {
  final currentLocationAsync = ref.watch(cargoLocationProvider(cargoId));
  final historyAsync = ref.watch(cargoTrackingHistoryProvider(cargoId));
  final statsAsync = ref.watch(cargoTrackingStatsProvider(cargoId));
  final etaAsync = ref.watch(cargoETAProvider(cargoId));

  final isLoading = currentLocationAsync.isLoading ||
      historyAsync.isLoading ||
      statsAsync.isLoading ||
      etaAsync.isLoading;

  final error = currentLocationAsync.error ??
      historyAsync.error ??
      statsAsync.error ??
      etaAsync.error;

  if (isLoading) {
    return const CargoTrackingInfo(isLoading: true);
  }

  if (error != null) {
    return CargoTrackingInfo(error: error);
  }

  return CargoTrackingInfo(
    currentLocation: currentLocationAsync.value,
    history: historyAsync.value ?? [],
    stats: statsAsync.value,
    eta: etaAsync.value,
  );
});

/// Провайдер для отслеживания нескольких грузов
final multiCargoTrackingProvider =
    Provider.family<Map<String, CargoTrackingInfo>, List<String>>(
        (ref, cargoIds) {
  final Map<String, CargoTrackingInfo> trackingInfo = {};

  for (final cargoId in cargoIds) {
    trackingInfo[cargoId] = ref.watch(cargoTrackingInfoProvider(cargoId));
  }

  return trackingInfo;
});

/// Провайдер для фильтрации активных грузов по статусу
enum TrackingFilter {
  all, // Все
  inTransit, // В пути
  stopped, // Остановлены
  delayed, // Задержаны
}

final filteredTrackingProvider =
    Provider.family<List<CargoTrackingModel>, TrackingFilter>((ref, filter) {
  final allTrackingAsync = ref.watch(allActiveTrackingProvider);

  return allTrackingAsync.when(
    data: (tracking) {
      if (filter == TrackingFilter.all) return tracking;

      return tracking.where((item) {
        switch (filter) {
          case TrackingFilter.inTransit:
            return item.status == TrackingStatus.inTransit;
          case TrackingFilter.stopped:
            return item.status == TrackingStatus.stopped;
          case TrackingFilter.delayed:
            return item.status == TrackingStatus.delayed;
          case TrackingFilter.all:
            return true;
        }
      }).toList();
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

/// Провайдер для подсчета грузов по статусам
final trackingCountByStatusProvider = Provider<Map<TrackingStatus, int>>((ref) {
  final allTrackingAsync = ref.watch(allActiveTrackingProvider);

  return allTrackingAsync.when(
    data: (tracking) {
      final Map<TrackingStatus, int> counts = {};

      for (final status in TrackingStatus.values) {
        counts[status] = tracking.where((item) => item.status == status).length;
      }

      return counts;
    },
    loading: () => {},
    error: (error, stackTrace) => {},
  );
});
