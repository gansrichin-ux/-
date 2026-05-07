import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/cargo_statuses.dart';
import '../../repositories/cargo_repository.dart';
import '../../models/cargo_model.dart';
import 'auth_providers.dart';

// Cargo repository provider
final cargoRepositoryProvider = Provider<CargoRepository>((ref) {
  return CargoRepository.instance;
});

// All cargos stream
final allCargosProvider = StreamProvider<List<CargoModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(const <CargoModel>[]);
  return ref.watch(cargoRepositoryProvider).watchAllCargos(ownerId: user.uid);
});

// Available cargos (new + no driver assigned)
final availableCargosProvider = StreamProvider<List<CargoModel>>((ref) {
  return ref.watch(cargoRepositoryProvider).watchAvailableCargos();
});

// Driver's cargos
final driverCargosProvider = StreamProvider.family<List<CargoModel>, String>((
  ref,
  driverId,
) {
  return ref.watch(cargoRepositoryProvider).watchDriverCargos(driverId);
});

// Single cargo
final cargoProvider = StreamProvider.family<CargoModel?, String>((
  ref,
  cargoId,
) {
  return ref.watch(cargoRepositoryProvider).watchCargo(cargoId);
});

// Search and filter state
final cargoSearchFilterProvider =
    StateNotifierProvider<CargoSearchFilterNotifier, CargoSearchFilter>((ref) {
  return CargoSearchFilterNotifier();
});

// Filtered cargos
final filteredCargosProvider = Provider<List<CargoModel>>((ref) {
  final allCargosAsync = ref.watch(allCargosProvider);
  final filter = ref.watch(cargoSearchFilterProvider);

  return allCargosAsync.when(
    data: (allCargos) {
      return allCargos.where((cargo) {
        // Status filter
        if (filter.status != null && cargo.status != filter.status) {
          return false;
        }

        // From filter
        if (filter.from != null && filter.from!.isNotEmpty) {
          if (!cargo.from.toLowerCase().contains(filter.from!.toLowerCase())) {
            return false;
          }
        }

        // To filter
        if (filter.to != null && filter.to!.isNotEmpty) {
          if (!cargo.to.toLowerCase().contains(filter.to!.toLowerCase())) {
            return false;
          }
        }

        // Distance filter
        if (filter.minDistanceKm != null && cargo.distanceKm != null) {
          if (cargo.distanceKm! < filter.minDistanceKm!) {
            return false;
          }
        }
        if (filter.maxDistanceKm != null && cargo.distanceKm != null) {
          if (cargo.distanceKm! > filter.maxDistanceKm!) {
            return false;
          }
        }

        // Weight filter
        if (filter.minWeightKg != null && cargo.weightKg != null) {
          if (cargo.weightKg! < filter.minWeightKg!) {
            return false;
          }
        }
        if (filter.maxWeightKg != null && cargo.weightKg != null) {
          if (cargo.weightKg! > filter.maxWeightKg!) {
            return false;
          }
        }

        // Volume filter
        if (filter.minVolumeM3 != null && cargo.volumeM3 != null) {
          if (cargo.volumeM3! < filter.minVolumeM3!) {
            return false;
          }
        }
        if (filter.maxVolumeM3 != null && cargo.volumeM3 != null) {
          if (cargo.volumeM3! > filter.maxVolumeM3!) {
            return false;
          }
        }

        // Body type filter
        if (filter.bodyType != null && filter.bodyType!.isNotEmpty) {
          if (cargo.bodyType != filter.bodyType) {
            return false;
          }
        }

        // Loading date filter
        if (filter.loadingDateFrom != null && cargo.loadingDate != null) {
          if (cargo.loadingDate!.isBefore(filter.loadingDateFrom!)) {
            return false;
          }
        }
        if (filter.loadingDateTo != null && cargo.loadingDate != null) {
          if (cargo.loadingDate!.isAfter(filter.loadingDateTo!)) {
            return false;
          }
        }

        // Loading type filter
        if (filter.loadingType != null && filter.loadingType!.isNotEmpty) {
          if (cargo.loadingType != filter.loadingType) {
            return false;
          }
        }

        // Payment type filter
        if (filter.paymentType != null && filter.paymentType!.isNotEmpty) {
          if (cargo.paymentType != filter.paymentType) {
            return false;
          }
        }

        // Length filter
        if (filter.minLengthM != null && cargo.lengthM != null) {
          if (cargo.lengthM! < filter.minLengthM!) {
            return false;
          }
        }
        if (filter.maxLengthM != null && cargo.lengthM != null) {
          if (cargo.lengthM! > filter.maxLengthM!) {
            return false;
          }
        }

        // Height filter
        if (filter.minHeightM != null && cargo.heightM != null) {
          if (cargo.heightM! < filter.minHeightM!) {
            return false;
          }
        }
        if (filter.maxHeightM != null && cargo.heightM != null) {
          if (cargo.heightM! > filter.maxHeightM!) {
            return false;
          }
        }

        // Width filter
        if (filter.minWidthM != null && cargo.widthM != null) {
          if (cargo.widthM! < filter.minWidthM!) {
            return false;
          }
        }
        if (filter.maxWidthM != null && cargo.widthM != null) {
          if (cargo.widthM! > filter.maxWidthM!) {
            return false;
          }
        }

        // Search query (title)
        if (filter.query.isNotEmpty) {
          final query = filter.query.toLowerCase();
          return cargo.title.toLowerCase().contains(query) ||
              (cargo.driverName?.toLowerCase().contains(query) ?? false);
        }

        return true;
      }).toList();
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

// Cargo statistics
final cargoStatsProvider = Provider<CargoStats>((ref) {
  final allCargosAsync = ref.watch(allCargosProvider);
  final allCargos = allCargosAsync.value ?? [];

  return CargoStats(
    total: allCargos.length,
    newCount: allCargos.where((c) => c.status == CargoStatus.published).length,
    inTransit: allCargos.where((c) => c.status == CargoStatus.inTransit).length,
    completed: allCargos.where((c) => c.status == CargoStatus.delivered).length,
    cancelled: allCargos.where((c) => c.status == CargoStatus.cancelled).length,
  );
});

class CargoSearchFilterNotifier extends StateNotifier<CargoSearchFilter> {
  CargoSearchFilterNotifier() : super(const CargoSearchFilter());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setStatus(String? status) {
    state = state.copyWith(status: status);
  }

  void setFrom(String? from) {
    state = state.copyWith(from: from);
  }

  void setTo(String? to) {
    state = state.copyWith(to: to);
  }

  void setDistanceRange(double? min, double? max) {
    state = state.copyWith(minDistanceKm: min, maxDistanceKm: max);
  }

  void setWeightRange(double? min, double? max) {
    state = state.copyWith(minWeightKg: min, maxWeightKg: max);
  }

  void setVolumeRange(double? min, double? max) {
    state = state.copyWith(minVolumeM3: min, maxVolumeM3: max);
  }

  void setBodyType(String? bodyType) {
    state = state.copyWith(bodyType: bodyType);
  }

  void setLoadingDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(loadingDateFrom: from, loadingDateTo: to);
  }

  void setLoadingType(String? loadingType) {
    state = state.copyWith(loadingType: loadingType);
  }

  void setPaymentType(String? paymentType) {
    state = state.copyWith(paymentType: paymentType);
  }

  void setLengthRange(double? min, double? max) {
    state = state.copyWith(minLengthM: min, maxLengthM: max);
  }

  void setHeightRange(double? min, double? max) {
    state = state.copyWith(minHeightM: min, maxHeightM: max);
  }

  void setWidthRange(double? min, double? max) {
    state = state.copyWith(minWidthM: min, maxWidthM: max);
  }

  void clearFilters() {
    state = const CargoSearchFilter();
  }
}

class CargoSearchFilter {
  final String query;
  final String? status;
  final String? from;
  final String? to;
  final double? minDistanceKm;
  final double? maxDistanceKm;
  final double? minWeightKg;
  final double? maxWeightKg;
  final double? minVolumeM3;
  final double? maxVolumeM3;
  final String? bodyType;
  final DateTime? loadingDateFrom;
  final DateTime? loadingDateTo;
  final String? loadingType;
  final String? paymentType;
  final double? minLengthM;
  final double? maxLengthM;
  final double? minHeightM;
  final double? maxHeightM;
  final double? minWidthM;
  final double? maxWidthM;

  const CargoSearchFilter({
    this.query = '',
    this.status,
    this.from,
    this.to,
    this.minDistanceKm,
    this.maxDistanceKm,
    this.minWeightKg,
    this.maxWeightKg,
    this.minVolumeM3,
    this.maxVolumeM3,
    this.bodyType,
    this.loadingDateFrom,
    this.loadingDateTo,
    this.loadingType,
    this.paymentType,
    this.minLengthM,
    this.maxLengthM,
    this.minHeightM,
    this.maxHeightM,
    this.minWidthM,
    this.maxWidthM,
  });

  CargoSearchFilter copyWith({
    String? query,
    String? status,
    String? from,
    String? to,
    double? minDistanceKm,
    double? maxDistanceKm,
    double? minWeightKg,
    double? maxWeightKg,
    double? minVolumeM3,
    double? maxVolumeM3,
    String? bodyType,
    DateTime? loadingDateFrom,
    DateTime? loadingDateTo,
    String? loadingType,
    String? paymentType,
    double? minLengthM,
    double? maxLengthM,
    double? minHeightM,
    double? maxHeightM,
    double? minWidthM,
    double? maxWidthM,
  }) {
    return CargoSearchFilter(
      query: query ?? this.query,
      status: status ?? this.status,
      from: from ?? this.from,
      to: to ?? this.to,
      minDistanceKm: minDistanceKm ?? this.minDistanceKm,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      minWeightKg: minWeightKg ?? this.minWeightKg,
      maxWeightKg: maxWeightKg ?? this.maxWeightKg,
      minVolumeM3: minVolumeM3 ?? this.minVolumeM3,
      maxVolumeM3: maxVolumeM3 ?? this.maxVolumeM3,
      bodyType: bodyType ?? this.bodyType,
      loadingDateFrom: loadingDateFrom ?? this.loadingDateFrom,
      loadingDateTo: loadingDateTo ?? this.loadingDateTo,
      loadingType: loadingType ?? this.loadingType,
      paymentType: paymentType ?? this.paymentType,
      minLengthM: minLengthM ?? this.minLengthM,
      maxLengthM: maxLengthM ?? this.maxLengthM,
      minHeightM: minHeightM ?? this.minHeightM,
      maxHeightM: maxHeightM ?? this.maxHeightM,
      minWidthM: minWidthM ?? this.minWidthM,
      maxWidthM: maxWidthM ?? this.maxWidthM,
    );
  }
}

class CargoStats {
  final int total;
  final int newCount;
  final int inTransit;
  final int completed;
  final int cancelled;
  final int pending;

  const CargoStats({
    required this.total,
    required this.newCount,
    required this.inTransit,
    required this.completed,
    required this.cancelled,
    this.pending = 0,
  });

  static const CargoStats empty = CargoStats(
    total: 0,
    newCount: 0,
    inTransit: 0,
    completed: 0,
    cancelled: 0,
  );

  double get completionRate => total > 0 ? completed / total : 0.0;
  double get activeRate => total > 0 ? (newCount + inTransit) / total : 0.0;
}
