import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/truck_body_types.dart';
import '../core/config/loading_types.dart';

class TransportModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;
  final String? companyId;

  final String type; // hitch, solo
  final String? brand;
  final String? model;
  final int? year;
  final String? plateNumber;

  final double capacityTons;
  final double volumeM3;
  final String bodyType;
  final List<String> loadingTypes;
  final List<String> unloadingTypes;

  final bool hasHydrolift;
  final bool hasConics;
  final bool hasRefrigerator;
  final bool hasPneumaticSuspension;
  final bool hasGps;
  final bool hasAdr;
  final bool hasTir;
  final bool hasCmr;
  final bool hasEkmt;

  final double? bodyLengthM;
  final double? bodyWidthM;
  final double? bodyHeightM;

  final List<String> loadingPoints;
  final List<String> unloadingPoints;
  final List<String> preferredDirections;

  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool isPermanent;

  final String paymentType; // cash, cashless, to_card, etc.
  final String? paymentMethod;
  final double? pricePerKm;
  final bool canBargain;
  final bool allowsReload;

  final String status; // available, busy, repair, inactive
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransportModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoUrl,
    this.companyId,
    required this.type,
    this.brand,
    this.model,
    this.year,
    this.plateNumber,
    required this.capacityTons,
    required this.volumeM3,
    required this.bodyType,
    this.loadingTypes = const [],
    this.unloadingTypes = const [],
    this.hasHydrolift = false,
    this.hasConics = false,
    this.hasRefrigerator = false,
    this.hasPneumaticSuspension = false,
    this.hasGps = false,
    this.hasAdr = false,
    this.hasTir = false,
    this.hasCmr = false,
    this.hasEkmt = false,
    this.bodyLengthM,
    this.bodyWidthM,
    this.bodyHeightM,
    this.loadingPoints = const [],
    this.unloadingPoints = const [],
    this.preferredDirections = const [],
    this.availableFrom,
    this.availableTo,
    this.isPermanent = false,
    required this.paymentType,
    this.paymentMethod,
    this.pricePerKm,
    this.canBargain = false,
    this.allowsReload = false,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  String get bodyTypeLabel => TruckBodyTypes.getLabel(bodyType);
  List<String> get loadingTypeLabels => LoadingTypes.getLabels(loadingTypes);
  
  String get dimensionsLabel {
    if (bodyLengthM == null || bodyWidthM == null || bodyHeightM == null) return '';
    return '${bodyLengthM}x${bodyWidthM}x$bodyHeightM м';
  }

  TransportModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? ownerPhotoUrl,
    String? companyId,
    String? type,
    String? brand,
    String? model,
    int? year,
    String? plateNumber,
    double? capacityTons,
    double? volumeM3,
    String? bodyType,
    List<String>? loadingTypes,
    List<String>? unloadingTypes,
    bool? hasHydrolift,
    bool? hasConics,
    bool? hasRefrigerator,
    bool? hasPneumaticSuspension,
    bool? hasGps,
    bool? hasAdr,
    bool? hasTir,
    bool? hasCmr,
    bool? hasEkmt,
    double? bodyLengthM,
    double? bodyWidthM,
    double? bodyHeightM,
    List<String>? loadingPoints,
    List<String>? unloadingPoints,
    List<String>? preferredDirections,
    DateTime? availableFrom,
    DateTime? availableTo,
    bool? isPermanent,
    String? paymentType,
    String? paymentMethod,
    double? pricePerKm,
    bool? canBargain,
    bool? allowsReload,
    String? status,
    DateTime? updatedAt,
  }) {
    return TransportModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      companyId: companyId ?? this.companyId,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      capacityTons: capacityTons ?? this.capacityTons,
      volumeM3: volumeM3 ?? this.volumeM3,
      bodyType: bodyType ?? this.bodyType,
      loadingTypes: loadingTypes ?? this.loadingTypes,
      unloadingTypes: unloadingTypes ?? this.unloadingTypes,
      hasHydrolift: hasHydrolift ?? this.hasHydrolift,
      hasConics: hasConics ?? this.hasConics,
      hasRefrigerator: hasRefrigerator ?? this.hasRefrigerator,
      hasPneumaticSuspension: hasPneumaticSuspension ?? this.hasPneumaticSuspension,
      hasGps: hasGps ?? this.hasGps,
      hasAdr: hasAdr ?? this.hasAdr,
      hasTir: hasTir ?? this.hasTir,
      hasCmr: hasCmr ?? this.hasCmr,
      hasEkmt: hasEkmt ?? this.hasEkmt,
      bodyLengthM: bodyLengthM ?? this.bodyLengthM,
      bodyWidthM: bodyWidthM ?? this.bodyWidthM,
      bodyHeightM: bodyHeightM ?? this.bodyHeightM,
      loadingPoints: loadingPoints ?? this.loadingPoints,
      unloadingPoints: unloadingPoints ?? this.unloadingPoints,
      preferredDirections: preferredDirections ?? this.preferredDirections,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      isPermanent: isPermanent ?? this.isPermanent,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      canBargain: canBargain ?? this.canBargain,
      allowsReload: allowsReload ?? this.allowsReload,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TransportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransportModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Неизвестно',
      ownerPhotoUrl: data['ownerPhotoUrl'],
      companyId: data['companyId'],
      type: data['type'] ?? 'hitch',
      brand: data['brand'],
      model: data['model'],
      year: data['year'],
      plateNumber: data['plateNumber'],
      capacityTons: (data['capacityTons'] as num?)?.toDouble() ?? 0.0,
      volumeM3: (data['volumeM3'] as num?)?.toDouble() ?? 0.0,
      bodyType: data['bodyType'] ?? TruckBodyTypes.truck,
      loadingTypes: List<String>.from(data['loadingTypes'] ?? []),
      unloadingTypes: List<String>.from(data['unloadingTypes'] ?? []),
      hasHydrolift: data['hasHydrolift'] ?? false,
      hasConics: data['hasConics'] ?? false,
      hasRefrigerator: data['hasRefrigerator'] ?? false,
      hasPneumaticSuspension: data['hasPneumaticSuspension'] ?? false,
      hasGps: data['hasGps'] ?? false,
      hasAdr: data['hasAdr'] ?? false,
      hasTir: data['hasTir'] ?? false,
      hasCmr: data['hasCmr'] ?? false,
      hasEkmt: data['hasEkmt'] ?? false,
      bodyLengthM: (data['bodyLengthM'] as num?)?.toDouble(),
      bodyWidthM: (data['bodyWidthM'] as num?)?.toDouble(),
      bodyHeightM: (data['bodyHeightM'] as num?)?.toDouble(),
      loadingPoints: List<String>.from(data['loadingPoints'] ?? []),
      unloadingPoints: List<String>.from(data['unloadingPoints'] ?? []),
      preferredDirections: List<String>.from(data['preferredDirections'] ?? []),
      availableFrom: (data['availableFrom'] as Timestamp?)?.toDate(),
      availableTo: (data['availableTo'] as Timestamp?)?.toDate(),
      isPermanent: data['isPermanent'] ?? false,
      paymentType: data['paymentType'] ?? 'cash',
      paymentMethod: data['paymentMethod'],
      pricePerKm: (data['pricePerKm'] as num?)?.toDouble(),
      canBargain: data['canBargain'] ?? false,
      allowsReload: data['allowsReload'] ?? false,
      status: data['status'] ?? 'available',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'companyId': companyId,
      'type': type,
      'brand': brand,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'capacityTons': capacityTons,
      'volumeM3': volumeM3,
      'bodyType': bodyType,
      'loadingTypes': loadingTypes,
      'unloadingTypes': unloadingTypes,
      'hasHydrolift': hasHydrolift,
      'hasConics': hasConics,
      'hasRefrigerator': hasRefrigerator,
      'hasPneumaticSuspension': hasPneumaticSuspension,
      'hasGps': hasGps,
      'hasAdr': hasAdr,
      'hasTir': hasTir,
      'hasCmr': hasCmr,
      'hasEkmt': hasEkmt,
      'bodyLengthM': bodyLengthM,
      'bodyWidthM': bodyWidthM,
      'bodyHeightM': bodyHeightM,
      'loadingPoints': loadingPoints,
      'unloadingPoints': unloadingPoints,
      'preferredDirections': preferredDirections,
      'availableFrom': availableFrom != null ? Timestamp.fromDate(availableFrom!) : null,
      'availableTo': availableTo != null ? Timestamp.fromDate(availableTo!) : null,
      'isPermanent': isPermanent,
      'paymentType': paymentType,
      'paymentMethod': paymentMethod,
      'pricePerKm': pricePerKm,
      'canBargain': canBargain,
      'allowsReload': allowsReload,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
