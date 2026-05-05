import 'package:cloud_firestore/cloud_firestore.dart';

class CargoTrackingModel {
  final String id;
  final String cargoId;
  final String driverId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final TrackingStatus status;
  final String? notes;
  final double? speed; // km/h
  final double? heading; // направление в градусах

  const CargoTrackingModel({
    required this.id,
    required this.cargoId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
    this.notes,
    this.speed,
    this.heading,
  });

  factory CargoTrackingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CargoTrackingModel(
      id: doc.id,
      cargoId: data['cargoId'] as String,
      driverId: data['driverId'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: TrackingStatus.values.firstWhere(
        (e) => e.toString() == 'TrackingStatus.${data['status']}',
        orElse: () => TrackingStatus.inTransit,
      ),
      notes: data['notes'] as String?,
      speed: data['speed'] != null ? (data['speed'] as num).toDouble() : null,
      heading: data['heading'] != null ? (data['heading'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'cargoId': cargoId,
      'driverId': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.toString().split('.').last,
      'notes': notes,
      'speed': speed,
      'heading': heading,
    };
  }

  CargoTrackingModel copyWith({
    String? id,
    String? cargoId,
    String? driverId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    TrackingStatus? status,
    String? notes,
    double? speed,
    double? heading,
  }) {
    return CargoTrackingModel(
      id: id ?? this.id,
      cargoId: cargoId ?? this.cargoId,
      driverId: driverId ?? this.driverId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }
}

enum TrackingStatus {
  inTransit, // В пути
  stopped,   // Остановлен
  loading,   // Загрузка
  unloading, // Разгрузка
  delayed,   // Задержка
  arrived,   // Прибыл
}

class TrackingHistoryPoint {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final TrackingStatus status;

  TrackingHistoryPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory TrackingHistoryPoint.fromMap(Map<String, dynamic> data) {
    return TrackingHistoryPoint(
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      status: TrackingStatus.values.firstWhere(
        (e) => e.toString() == 'TrackingStatus.${data['status']}',
        orElse: () => TrackingStatus.inTransit,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toString().split('.').last,
    };
  }
}
