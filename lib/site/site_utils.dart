part of '../main_site.dart';

class CargoStatsView {
  final List<CargoModel> cargos;

  CargoStatsView(this.cargos);

  int get total => cargos.length;
  int get active => cargos.where((cargo) => cargo.isActive).length;
  int get inTransit => cargos.where((cargo) => cargo.status == CargoStatus.inTransit).length;
  int get waitingConfirmation => cargos.where((cargo) => cargo.status == CargoStatus.waitingConfirmation).length;
  int get waitingLoading => cargos.where((cargo) => cargo.status == CargoStatus.waitingLoading).length;
  int get waitingPayment => cargos.where((cargo) => cargo.status == CargoStatus.waitingPayment).length;
  int get inDispute => cargos.where((cargo) => cargo.status == CargoStatus.dispute).length;
  int get closed => cargos.where((cargo) => cargo.status == CargoStatus.closed).length;
  double get revenue => cargos.fold<double>(0, (sum, cargo) => sum + (cargo.price ?? 0));

  int get newCount => cargos.where((cargo) => cargo.status == CargoStatus.published).length;
  int get unassigned => cargos.where((cargo) => cargo.status == CargoStatus.published && cargo.driverId == null).length;
  double get distance => cargos.fold<double>(0, (sum, cargo) => sum + (cargo.distanceKm ?? 0));
}

class CargoFilters {
  final String from;
  final String to;
  final String bodyType;
  final String? truckType;
  final String? shipmentType;
  final int? carCount;
  final double? minWeight;
  final double? maxWeight;
  final double? minVolume;
  final double? maxVolume;
  final double? minPrice;
  final double? maxPrice;
  final String? currency;
  final bool onlyWithoutDriver;
  final bool onlyActive;
  final bool isUrgent;
  final bool isHumanitarian;
  final bool hasPhoto;
  final bool? isReady;
  final DateTime? loadingDate;

  const CargoFilters({
    this.from = '',
    this.to = '',
    this.bodyType = '',
    this.truckType,
    this.shipmentType,
    this.carCount,
    this.minWeight,
    this.maxWeight,
    this.minVolume,
    this.maxVolume,
    this.minPrice,
    this.maxPrice,
    this.currency,
    this.onlyWithoutDriver = false,
    this.onlyActive = false,
    this.isUrgent = false,
    this.isHumanitarian = false,
    this.hasPhoto = false,
    this.isReady,
    this.loadingDate,
  });

  static const empty = CargoFilters();

  bool get isActive =>
      from.trim().isNotEmpty ||
      to.trim().isNotEmpty ||
      bodyType.trim().isNotEmpty ||
      truckType != null ||
      shipmentType != null ||
      carCount != null ||
      minWeight != null ||
      maxWeight != null ||
      minVolume != null ||
      maxVolume != null ||
      minPrice != null ||
      maxPrice != null ||
      currency != null ||
      onlyWithoutDriver ||
      onlyActive ||
      isUrgent ||
      isHumanitarian ||
      hasPhoto ||
      isReady != null ||
      loadingDate != null;

  CargoFilters copyWith({
    String? from,
    String? to,
    String? bodyType,
    String? truckType,
    String? shipmentType,
    int? carCount,
    double? minWeight,
    double? maxWeight,
    double? minVolume,
    double? maxVolume,
    double? minPrice,
    double? maxPrice,
    String? currency,
    bool? onlyWithoutDriver,
    bool? onlyActive,
    bool? isUrgent,
    bool? isHumanitarian,
    bool? hasPhoto,
    bool? isReady,
    DateTime? loadingDate,
    bool clearMinWeight = false,
    bool clearMaxWeight = false,
    bool clearMinVolume = false,
    bool clearMaxVolume = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearTruckType = false,
    bool clearShipmentType = false,
    bool clearCarCount = false,
    bool clearIsReady = false,
    bool clearLoadingDate = false,
  }) {
    return CargoFilters(
      from: from ?? this.from,
      to: to ?? this.to,
      bodyType: bodyType ?? this.bodyType,
      truckType: clearTruckType ? null : truckType ?? this.truckType,
      shipmentType: clearShipmentType ? null : shipmentType ?? this.shipmentType,
      carCount: clearCarCount ? null : carCount ?? this.carCount,
      minWeight: clearMinWeight ? null : minWeight ?? this.minWeight,
      maxWeight: clearMaxWeight ? null : maxWeight ?? this.maxWeight,
      minVolume: clearMinVolume ? null : minVolume ?? this.minVolume,
      maxVolume: clearMaxVolume ? null : maxVolume ?? this.maxVolume,
      minPrice: clearMinPrice ? null : minPrice ?? this.minPrice,
      maxPrice: clearMaxPrice ? null : maxPrice ?? this.maxPrice,
      currency: currency ?? this.currency,
      onlyWithoutDriver: onlyWithoutDriver ?? this.onlyWithoutDriver,
      onlyActive: onlyActive ?? this.onlyActive,
      isUrgent: isUrgent ?? this.isUrgent,
      isHumanitarian: isHumanitarian ?? this.isHumanitarian,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      isReady: clearIsReady ? null : isReady ?? this.isReady,
      loadingDate: clearLoadingDate ? null : loadingDate ?? this.loadingDate,
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case CargoStatus.draft:
      return const Color(0xFF64748B); // Slate
    case CargoStatus.published:
      return const Color(0xFF2563EB); // Blue
    case CargoStatus.hasApplications:
      return const Color(0xFF3B82F6); // Lighter Blue
    case CargoStatus.executorSelected:
      return const Color(0xFF8B5CF6); // Violet
    case CargoStatus.waitingConfirmation:
      return const Color(0xFFEAB308); // Yellow
    case CargoStatus.confirmed:
      return const Color(0xFF10B981); // Emerald
    case CargoStatus.waitingLoading:
      return const Color(0xFFF59E0B); // Amber
    case CargoStatus.loading:
      return const Color(0xFFD97706); // Darker Amber
    case CargoStatus.loaded:
      return const Color(0xFF14B8A6); // Teal
    case CargoStatus.inTransit:
      return const Color(0xFF0891B2); // Cyan
    case CargoStatus.unloading:
      return const Color(0xFF0284C7); // Light Blue
    case CargoStatus.delivered:
      return const Color(0xFF22C55E); // Green
    case CargoStatus.waitingDocuments:
      return const Color(0xFFF43F5E); // Rose
    case CargoStatus.waitingPayment:
      return const Color(0xFFEC4899); // Pink
    case CargoStatus.closed:
      return const Color(0xFF16A34A); // Darker Green
    case CargoStatus.cancelled:
      return const Color(0xFFDC2626); // Red
    case CargoStatus.dispute:
      return const Color(0xFF991B1B); // Dark Red
    case CargoStatus.expired:
      return const Color(0xFF475569); // Dark Slate
    default:
      return const Color(0xFF64748B);
  }
}

double? _parseDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String _formatMoney(double value) {
  final formatted = NumberFormat.decimalPattern('ru').format(value.round());
  return '$formatted ₸';
}

String _userInitial(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'L';
  return trimmed.substring(0, 1).toUpperCase();
}

String translateAuthError(Object error) {
  final errStr = error.toString();
  if (errStr.contains('email-already-in-use')) {
    return 'Этот email уже зарегистрирован. Пожалуйста, войдите или используйте другой email.';
  } else if (errStr.contains('invalid-email')) {
    return 'Неверный формат email адреса.';
  } else if (errStr.contains('weak-password')) {
    return 'Пароль слишком слабый. Используйте минимум 6 символов.';
  } else if (errStr.contains('user-not-found')) {
    return 'Пользователь с таким email не найден.';
  } else if (errStr.contains('wrong-password') || errStr.contains('invalid-credential')) {
    return 'Неверный email или пароль.';
  } else if (errStr.contains('network-request-failed')) {
    return 'Ошибка сети. Проверьте подключение к интернету.';
  } else if (errStr.contains('too-many-requests')) {
    return 'Слишком много попыток входа. Пожалуйста, подождите немного.';
  }
  return errStr;
}

void showSiteError(BuildContext context, String message) {
  final overlayState = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return Positioned(
        top: 24,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.errorContainer.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.error.withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: colors.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            if (entry.mounted) entry.remove();
                          },
                          child: Icon(Icons.close_rounded, size: 20, color: colors.onErrorContainer),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlayState.insert(entry);
  Future.delayed(const Duration(seconds: 4), () {
    if (entry.mounted) entry.remove();
  });
}
