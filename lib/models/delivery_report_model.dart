import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryReportModel {
  final String id;
  final String cargoId;
  final String driverId;
  final List<String> photos;
  final String? signatureBase64;
  final String? notes;
  final DateTime createdAt;
  final DeliveryStatus status;

  const DeliveryReportModel({
    required this.id,
    required this.cargoId,
    required this.driverId,
    this.photos = const [],
    this.signatureBase64,
    this.notes,
    required this.createdAt,
    required this.status,
  });

  factory DeliveryReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryReportModel(
      id: doc.id,
      cargoId: data['cargoId'] as String,
      driverId: data['driverId'] as String,
      photos: List<String>.from(data['photos'] as List<dynamic>? ?? []),
      signatureBase64: data['signatureBase64'] as String?,
      notes: data['notes'] as String?,
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      status: DeliveryStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DeliveryStatus.pending,
      ),
    );
  }

  factory DeliveryReportModel.fromMap(Map<String, dynamic> map) {
    return DeliveryReportModel(
      id: map['id'] as String,
      cargoId: map['cargoId'] as String,
      driverId: map['driverId'] as String,
      photos: List<String>.from(map['photos'] as List? ?? []),
      signatureBase64: map['signatureBase64'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      status: map['status'] != null
          ? DeliveryStatus.values.firstWhere((e) => e.name == map['status'])
          : DeliveryStatus.pending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cargoId': cargoId,
      'driverId': driverId,
      'photos': photos,
      'signatureBase64': signatureBase64,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'cargoId': cargoId,
      'driverId': driverId,
      'photos': photos,
      'signatureBase64': signatureBase64,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status.name,
    };
  }

  DeliveryReportModel copyWith({
    String? cargoId,
    String? driverId,
    List<String>? photos,
    String? signatureBase64,
    String? notes,
    DateTime? createdAt,
    DeliveryStatus? status,
  }) {
    return DeliveryReportModel(
      id: id,
      cargoId: cargoId ?? this.cargoId,
      driverId: driverId ?? this.driverId,
      photos: photos ?? this.photos,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

enum DeliveryStatus { pending, confirmed, rejected }

extension DeliveryStatusExtension on DeliveryStatus {
  String get displayName {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Ожидает подтверждения';
      case DeliveryStatus.confirmed:
        return 'Подтвержден';
      case DeliveryStatus.rejected:
        return 'Отклонен';
    }
  }

  String get russianName {
    switch (this) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.confirmed:
        return 'confirmed';
      case DeliveryStatus.rejected:
        return 'rejected';
    }
  }
}
