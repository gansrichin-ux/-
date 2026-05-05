import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../../models/cargo_tracking_model.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _trackingCollection = 
      FirebaseFirestore.instance.collection('cargo_tracking');

  /// Получить текущее местоположение груза
  Stream<CargoTrackingModel?> getCurrentLocation(String cargoId) {
    return _trackingCollection
        .where('cargoId', isEqualTo: cargoId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CargoTrackingModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Получить историю местоположений груза
  Stream<List<TrackingHistoryPoint>> getTrackingHistory(String cargoId) {
    return _trackingCollection
        .where('cargoId', isEqualTo: cargoId)
        .orderBy('timestamp', descending: true)
        .limit(100) // Последние 100 точек
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TrackingHistoryPoint.fromMap(data);
      }).toList();
    });
  }

  /// Обновить местоположение груза
  Future<void> updateLocation({
    required String cargoId,
    required String driverId,
    required double latitude,
    required double longitude,
    required TrackingStatus status,
    String? notes,
    double? speed,
    double? heading,
  }) async {
    final tracking = CargoTrackingModel(
      id: _firestore.collection('cargo_tracking').doc().id,
      cargoId: cargoId,
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      status: status,
      notes: notes,
      speed: speed,
      heading: heading,
    );

    await _trackingCollection.add(tracking.toFirestoreMap());
  }

  /// Получить все активные отслеживания для водителя
  Stream<List<CargoTrackingModel>> getDriverActiveTracking(String driverId) {
    return _trackingCollection
        .where('driverId', isEqualTo: driverId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CargoTrackingModel.fromFirestore(doc);
      }).toList();
    });
  }

  /// Получить все активные отслеживания для логиста
  Stream<List<CargoTrackingModel>> getAllActiveTracking() {
    return _trackingCollection
        .orderBy('timestamp', descending: true)
        .limit(50) // Последние 50 обновлений
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CargoTrackingModel.fromFirestore(doc);
      }).toList();
    });
  }

  /// Рассчитать расстояние между двумя точками (в км)
  double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2
  ) {
    const double earthRadius = 6371; // Радиус Земли в км
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.toRadians().cos() * lat2.toRadians().cos() *
        (dLon / 2).sin() * (dLon / 2).sin();
    
    final double c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }

  /// Рассчитать примерное время прибытия
  DateTime? calculateETA({
    required double currentLat,
    required double currentLon,
    required double destinationLat,
    required double destinationLon,
    required double averageSpeed, // км/ч
  }) {
    final double distance = calculateDistance(
      currentLat, currentLon, 
      destinationLat, destinationLon
    );
    
    if (averageSpeed <= 0) return null;
    
    final double hours = distance / averageSpeed;
    return DateTime.now().add(Duration(hours: hours.round()));
  }

  /// Получить статистику по отслеживанию для груза
  Future<Map<String, dynamic>> getCargoTrackingStats(String cargoId) async {
    final snapshot = await _trackingCollection
        .where('cargoId', isEqualTo: cargoId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();
    
    if (snapshot.docs.isEmpty) {
      return {
        'totalDistance': 0.0,
        'averageSpeed': 0.0,
        'totalTime': Duration.zero,
        'stopCount': 0,
        'lastUpdate': null,
      };
    }

    final points = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return TrackingHistoryPoint.fromMap(data);
    }).toList();

    double totalDistance = 0.0;
    double totalSpeed = 0.0;
    int speedCount = 0;
    int stopCount = 0;
    DateTime? lastUpdate;

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      
      totalDistance += calculateDistance(
        current.latitude, current.longitude,
        next.latitude, next.longitude,
      );
      
      if (current.status == TrackingStatus.stopped) {
        stopCount++;
      }
    }

    // Рассчитываем среднюю скорость
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final speed = data['speed'] as double?;
      if (speed != null && speed > 0) {
        totalSpeed += speed;
        speedCount++;
      }
    }

    final double averageSpeed = speedCount > 0 ? totalSpeed / speedCount : 0.0;
    final Duration totalTime = points.isNotEmpty 
        ? DateTime.now().difference(points.last.timestamp)
        : Duration.zero;
    
    lastUpdate = points.isNotEmpty ? points.first.timestamp : null;

    return {
      'totalDistance': totalDistance,
      'averageSpeed': averageSpeed,
      'totalTime': totalTime,
      'stopCount': stopCount,
      'lastUpdate': lastUpdate,
    };
  }

  /// Очистить старые данные отслеживания (старше 30 дней)
  Future<void> cleanupOldTrackingData() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    final oldDocs = await _trackingCollection
        .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
        .get();
    
    final batch = _firestore.batch();
    for (final doc in oldDocs.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}

extension on double {
  double toRadians() => this * (3.14159265359 / 180);
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double asin() => math.asin(this);
  double sqrt() => math.sqrt(this);
}
