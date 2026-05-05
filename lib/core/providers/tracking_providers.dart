import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tracking_service.dart';
import '../../models/cargo_tracking_model.dart';

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ СЃРµСЂРІРёСЃР° РѕС‚СЃР»РµР¶РёРІР°РЅРёСЏ
final trackingServiceProvider = Provider<TrackingService>((ref) {
  return TrackingService();
});

/// РџСЂРѕРІР°Р№РґРµСЂ С‚РµРєСѓС‰РµРіРѕ РјРµСЃС‚РѕРїРѕР»РѕР¶РµРЅРёСЏ РіСЂСѓР·Р°
final cargoLocationProvider =
    StreamProvider.family<CargoTrackingModel?, String>((ref, cargoId) {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.getCurrentLocation(cargoId);
});

/// РџСЂРѕРІР°Р№РґРµСЂ РёСЃС‚РѕСЂРёРё РѕС‚СЃР»РµР¶РёРІР°РЅРёСЏ РіСЂСѓР·Р°
final cargoTrackingHistoryProvider =
    StreamProvider.family<List<TrackingHistoryPoint>, String>((ref, cargoId) {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.getTrackingHistory(cargoId);
});

/// РџСЂРѕРІР°Р№РґРµСЂ РІСЃРµС… Р°РєС‚РёРІРЅС‹С… РѕС‚СЃР»РµР¶РёРІР°РЅРёР№
final allActiveTrackingProvider =
    StreamProvider<List<CargoTrackingModel>>((ref) {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.getAllActiveTracking();
});

/// РџСЂРѕРІР°Р№РґРµСЂ РѕС‚СЃР»РµР¶РёРІР°РЅРёР№ РґР»СЏ РєРѕРЅРєСЂРµС‚РЅРѕРіРѕ РІРѕРґРёС‚РµР»СЏ
final driverTrackingProvider =
    StreamProvider.family<List<CargoTrackingModel>, String>((ref, driverId) {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.getDriverActiveTracking(driverId);
});

/// РџСЂРѕРІР°Р№РґРµСЂ СЃС‚Р°С‚РёСЃС‚РёРєРё РѕС‚СЃР»РµР¶РёРІР°РЅРёСЏ РіСЂСѓР·Р°
final cargoTrackingStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, cargoId) async {
  final trackingService = ref.watch(trackingServiceProvider);
  return await trackingService.getCargoTrackingStats(cargoId);
});

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ СЂР°СЃС‡РµС‚Р° ETA (РІСЂРµРјРµРЅРё РїСЂРёР±С‹С‚РёСЏ)
final cargoETAProvider =
    FutureProvider.family<DateTime?, String>((ref, cargoId) async {
  final trackingService = ref.watch(trackingServiceProvider);
  final location = await ref.watch(cargoLocationProvider(cargoId).future);

  if (location == null) return null;

  // Р—РґРµСЃСЊ РЅСѓР¶РЅРѕ РїРѕР»СѓС‡РёС‚СЊ РєРѕРѕСЂРґРёРЅР°С‚С‹ РЅР°Р·РЅР°С‡РµРЅРёСЏ РёР· РіСЂСѓР·Р°
  // Р’ СЂРµР°Р»СЊРЅРѕРј РїСЂРёР»РѕР¶РµРЅРёРё СЌС‚Рѕ Р±СѓРґРµС‚ РїРѕР»СѓС‡РµРЅРѕ РёР· CargoModel
  // РџРѕРєР° РёСЃРїРѕР»СЊР·СѓРµРј Р·Р°РіР»СѓС€РєСѓ
  return trackingService.calculateETA(
    currentLat: location.latitude,
    currentLon: location.longitude,
    destinationLat: 55.7558, // РњРѕСЃРєРІР° (Р·Р°РіР»СѓС€РєР°)
    destinationLon: 37.6176,
    averageSpeed: 60.0, // 60 РєРј/С‡ (Р·Р°РіР»СѓС€РєР°)
  );
});

/// РљРѕРјР±РёРЅРёСЂРѕРІР°РЅРЅС‹Р№ РїСЂРѕРІР°Р№РґРµСЂ РґР»СЏ РґРµС‚Р°Р»СЊРЅРѕР№ РёРЅС„РѕСЂРјР°С†РёРё РѕР± РѕС‚СЃР»РµР¶РёРІР°РЅРёРё
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

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ РѕС‚СЃР»РµР¶РёРІР°РЅРёСЏ РЅРµСЃРєРѕР»СЊРєРёС… РіСЂСѓР·РѕРІ
final multiCargoTrackingProvider =
    Provider.family<Map<String, CargoTrackingInfo>, List<String>>(
        (ref, cargoIds) {
  final Map<String, CargoTrackingInfo> trackingInfo = {};

  for (final cargoId in cargoIds) {
    trackingInfo[cargoId] = ref.watch(cargoTrackingInfoProvider(cargoId));
  }

  return trackingInfo;
});

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ С„РёР»СЊС‚СЂР°С†РёРё Р°РєС‚РёРІРЅС‹С… РіСЂСѓР·РѕРІ РїРѕ СЃС‚Р°С‚СѓСЃСѓ
enum TrackingFilter {
  all, // Р’СЃРµ
  inTransit, // Р’ РїСѓС‚Рё
  stopped, // РћСЃС‚Р°РЅРѕРІР»РµРЅС‹
  delayed, // Р—Р°РґРµСЂР¶Р°РЅС‹
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

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ РїРѕРґСЃС‡РµС‚Р° РіСЂСѓР·РѕРІ РїРѕ СЃС‚Р°С‚СѓСЃР°Рј
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
