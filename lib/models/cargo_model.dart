import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/cargo_statuses.dart';

class CargoModel {
  final String id;
  final String title;
  final String from;
  final String to;
  final String status;
  final String? driverId;
  final String? driverName;
  final String? ownerId;
  final List<String> photos;
  final DateTime? createdAt;
  final String? description;
  final double? weightKg;
  final double? volumeM3;
  final String? bodyType;
  final DateTime? loadingDate;
  final String? loadingType;
  final String? paymentType;
  final double? lengthM;
  final double? heightM;
  final double? widthM;
  final double? distanceKm;
  final double? price;
  final String? currency;
  final bool isUrgent;
  final bool isHumanitarian;
  final String? paymentStatus;
  final int? carCount;
  final String? truckType;
  final String? shipmentType; // full, partial, reload_possible, only_separate
  final bool isReady;
  final String? cargoType;

  bool get isDraft => status == CargoStatus.draft;
  bool get isPublished => status == CargoStatus.published;
  bool get hasApplications => status == CargoStatus.hasApplications;
  /// True when a specific executor (driver/forwarder) has been chosen.
  /// Covers all stages from executorSelected onward, OR when driverId is set.
  bool get hasExecutor =>
      (driverId != null && driverId!.isNotEmpty) ||
      const [
        CargoStatus.executorSelected,
        CargoStatus.waitingConfirmation,
        CargoStatus.confirmed,
        CargoStatus.waitingLoading,
        CargoStatus.loading,
        CargoStatus.loaded,
        CargoStatus.inTransit,
        CargoStatus.unloading,
        CargoStatus.delivered,
        CargoStatus.waitingDocuments,
        CargoStatus.waitingPayment,
        CargoStatus.closed,
        CargoStatus.dispute,
      ].contains(status);
  bool get isActive => const [
        CargoStatus.published,
        CargoStatus.hasApplications,
        CargoStatus.executorSelected,
        CargoStatus.waitingConfirmation,
        CargoStatus.confirmed,
        CargoStatus.waitingLoading,
        CargoStatus.loading,
        CargoStatus.loaded,
        CargoStatus.inTransit,
        CargoStatus.unloading,
        CargoStatus.waitingDocuments,
        CargoStatus.waitingPayment,
        CargoStatus.dispute,
      ].contains(status);
  bool get isFinished => status == CargoStatus.delivered || status == CargoStatus.closed;
  bool get isCancelled => status == CargoStatus.cancelled;
  bool get isInDispute => status == CargoStatus.dispute;
  bool get isClosed => status == CargoStatus.closed;
  double get pricePerKm => (price != null && distanceKm != null && distanceKm! > 0) ? price! / distanceKm! : 0.0;

    this.distanceKm,
    this.price,
    this.currency = 'KZT',
    this.isUrgent = false,
    this.isHumanitarian = false,
    this.paymentStatus,
    this.carCount = 1,
    this.truckType,
    this.shipmentType = 'full',
    this.isReady = true,
    this.cargoType,
  })  : id = id.isNotEmpty ? id : throw ArgumentError('Cargo id must not be empty'),
        title = title.isNotEmpty ? title : throw ArgumentError('Cargo title must not be empty'),
        from = from.isNotEmpty ? from : throw ArgumentError('Cargo origin must not be empty'),
        to = to.isNotEmpty ? to : throw ArgumentError('Cargo destination must not be empty'),
        status = status.isNotEmpty ? status : throw ArgumentError('Cargo status must not be empty'),
        assert(
          weightKg == null || weightKg > 0,
          'Cargo weight must be positive',
        );

  factory CargoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawStatus = data['status'] as String? ?? 'Новый';
    
    return CargoModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      from: data['from'] as String? ?? '',
      to: data['to'] as String? ?? '',
      status: CargoStatus.fromLegacy(rawStatus),
      driverId: data['driverId'] as String?,
      driverName: data['driverName'] as String?,
      ownerId: data['ownerId'] as String?,
      photos: List<String>.from(data['photos'] as List<dynamic>? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      description: data['description'] as String?,
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      volumeM3: (data['volumeM3'] as num?)?.toDouble(),
      bodyType: data['bodyType'] as String?,
      loadingDate: (data['loadingDate'] as Timestamp?)?.toDate(),
      loadingType: data['loadingType'] as String?,
      paymentType: data['paymentType'] as String?,
      lengthM: (data['lengthM'] as num?)?.toDouble(),
      heightM: (data['heightM'] as num?)?.toDouble(),
      widthM: (data['widthM'] as num?)?.toDouble(),
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      price: (data['price'] as num?)?.toDouble(),
      currency: data['currency'] as String? ?? 'KZT',
      isUrgent: data['isUrgent'] as bool? ?? false,
      isHumanitarian: data['isHumanitarian'] as bool? ?? false,
      paymentStatus: data['paymentStatus'] as String?,
      carCount: data['carCount'] as int? ?? 1,
      truckType: data['truckType'] as String?,
      shipmentType: data['shipmentType'] as String? ?? 'full',
      isReady: data['isReady'] as bool? ?? true,
      cargoType: data['cargoType'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'from': from,
      'to': to,
      'status': CargoStatus.toLegacy(status),
      if (driverId != null) 'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      if (ownerId != null) 'ownerId': ownerId,
      'photos': photos,
      'createdAt': FieldValue.serverTimestamp(),
      if (description != null) 'description': description,
      if (weightKg != null) 'weightKg': weightKg,
      if (volumeM3 != null) 'volumeM3': volumeM3,
      if (bodyType != null) 'bodyType': bodyType,
      if (loadingDate != null) 'loadingDate': Timestamp.fromDate(loadingDate!),
      if (loadingType != null) 'loadingType': loadingType,
      if (paymentType != null) 'paymentType': paymentType,
      if (lengthM != null) 'lengthM': lengthM,
      if (heightM != null) 'heightM': heightM,
      if (widthM != null) 'widthM': widthM,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (price != null) 'price': price,
      'currency': currency,
      'isUrgent': isUrgent,
      'isHumanitarian': isHumanitarian,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      'carCount': carCount,
      if (truckType != null) 'truckType': truckType,
      'shipmentType': shipmentType,
      'isReady': isReady,
      if (cargoType != null) 'cargoType': cargoType,
    };
  }

  CargoModel copyWith({
    String? title,
    String? from,
    String? to,
    String? status,
    String? driverId,
    String? driverName,
    String? ownerId,
    List<String>? photos,
    String? description,
    double? weightKg,
    double? volumeM3,
    String? bodyType,
    DateTime? loadingDate,
    String? loadingType,
    String? paymentType,
    double? lengthM,
    double? heightM,
    double? widthM,
    double? distanceKm,
    double? price,
    String? currency,
    bool? isUrgent,
    bool? isHumanitarian,
    String? paymentStatus,
    int? carCount,
    String? truckType,
    String? shipmentType,
    bool? isReady,
    String? cargoType,
  }) {
    return CargoModel(
      id: id,
      title: title ?? this.title,
      from: from ?? this.from,
      to: to ?? this.to,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      ownerId: ownerId ?? this.ownerId,
      photos: photos ?? this.photos,
      createdAt: createdAt,
      description: description ?? this.description,
      weightKg: weightKg ?? this.weightKg,
      volumeM3: volumeM3 ?? this.volumeM3,
      bodyType: bodyType ?? this.bodyType,
      loadingDate: loadingDate ?? this.loadingDate,
      loadingType: loadingType ?? this.loadingType,
      paymentType: paymentType ?? this.paymentType,
      lengthM: lengthM ?? this.lengthM,
      heightM: heightM ?? this.heightM,
      widthM: widthM ?? this.widthM,
      distanceKm: distanceKm ?? this.distanceKm,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isUrgent: isUrgent ?? this.isUrgent,
      isHumanitarian: isHumanitarian ?? this.isHumanitarian,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      carCount: carCount ?? this.carCount,
      truckType: truckType ?? this.truckType,
      shipmentType: shipmentType ?? this.shipmentType,
      isReady: isReady ?? this.isReady,
      cargoType: cargoType ?? this.cargoType,
    );
  }

  factory CargoModel.fromMap(Map<String, dynamic> map) {
    return CargoModel(
      id: map['id'] as String,
      title: map['title'] as String,
      from: map['from'] as String,
      to: map['to'] as String,
      status: map['status'] as String,
      driverId: map['driverId'] as String?,
      driverName: map['driverName'] as String?,
      ownerId: map['ownerId'] as String?,
      photos: List<String>.from(map['photos'] as List? ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      description: map['description'] as String?,
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      volumeM3: (map['volumeM3'] as num?)?.toDouble(),
      bodyType: map['bodyType'] as String?,
      loadingDate: map['loadingDate'] != null
          ? DateTime.parse(map['loadingDate'] as String)
          : null,
      loadingType: map['loadingType'] as String?,
      paymentType: map['paymentType'] as String?,
      lengthM: (map['lengthM'] as num?)?.toDouble(),
      heightM: (map['heightM'] as num?)?.toDouble(),
      widthM: (map['widthM'] as num?)?.toDouble(),
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      price: (map['price'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'KZT',
      isUrgent: map['isUrgent'] as bool? ?? false,
      isHumanitarian: map['isHumanitarian'] as bool? ?? false,
      paymentStatus: map['paymentStatus'] as String?,
      carCount: map['carCount'] as int? ?? 1,
      truckType: map['truckType'] as String?,
      shipmentType: map['shipmentType'] as String? ?? 'full',
      isReady: map['isReady'] as bool? ?? true,
      cargoType: map['cargoType'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'from': from,
      'to': to,
      'status': status,
      if (driverId != null) 'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      if (ownerId != null) 'ownerId': ownerId,
      'photos': photos,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (description != null) 'description': description,
      if (weightKg != null) 'weightKg': weightKg,
      if (volumeM3 != null) 'volumeM3': volumeM3,
      if (bodyType != null) 'bodyType': bodyType,
      if (loadingDate != null) 'loadingDate': loadingDate!.toIso8601String(),
      if (loadingType != null) 'loadingType': loadingType,
      if (paymentType != null) 'paymentType': paymentType,
      if (lengthM != null) 'lengthM': lengthM,
      if (heightM != null) 'heightM': heightM,
      if (widthM != null) 'widthM': widthM,
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (price != null) 'price': price,
      'currency': currency,
      'isUrgent': isUrgent,
      'isHumanitarian': isHumanitarian,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      'carCount': carCount,
      if (truckType != null) 'truckType': truckType,
      'shipmentType': shipmentType,
      'isReady': isReady,
      if (cargoType != null) 'cargoType': cargoType,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CargoModel &&
        other.id == id &&
        other.title == title &&
        other.from == from &&
        other.to == to &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        from.hashCode ^
        to.hashCode ^
        status.hashCode;
  }

  @override
  String toString() {
    return 'CargoModel(id: $id, title: $title, from: $from, to: $to, status: $status)';
  }
}
