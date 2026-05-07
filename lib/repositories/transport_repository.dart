import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/transport_model.dart';

class TransportRepository {
  TransportRepository._();
  static final TransportRepository instance = TransportRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transports =>
      _firestore.collection('transports');

  Stream<List<TransportModel>> watchAvailableTransport({
    String? type,
    String? bodyType,
    double? minCapacity,
    double? minVolume,
    String? loadingPoint,
    String? unloadingPoint,
    String? paymentType,
    bool? hasHydrolift,
    bool? hasConics,
    bool? hasAdr,
    DateTime? availableFrom,
    bool? allowsReload,
  }) {
    Query<Map<String, dynamic>> query =
        _transports.where('status', isEqualTo: 'available');

    if (type != null) query = query.where('type', isEqualTo: type);
    if (bodyType != null) query = query.where('bodyType', isEqualTo: bodyType);
    if (paymentType != null)
      query = query.where('paymentType', isEqualTo: paymentType);
    if (hasHydrolift == true)
      query = query.where('hasHydrolift', isEqualTo: true);
    if (hasConics == true) query = query.where('hasConics', isEqualTo: true);
    if (hasAdr == true) query = query.where('hasAdr', isEqualTo: true);
    if (allowsReload == true)
      query = query.where('allowsReload', isEqualTo: true);

    return query.snapshots().map((snap) {
      var list = snap.docs.map(TransportModel.fromFirestore).toList();

      // Client-side filtering for fields that Firestore doesn't support well in combination
      if (minCapacity != null) {
        list = list.where((t) => t.capacityTons >= minCapacity).toList();
      }
      if (minVolume != null) {
        list = list.where((t) => t.volumeM3 >= minVolume).toList();
      }
      if (loadingPoint != null && loadingPoint.isNotEmpty) {
        list = list
            .where((t) => t.loadingPoints.any(
                (p) => p.toLowerCase().contains(loadingPoint.toLowerCase())))
            .toList();
      }
      if (unloadingPoint != null && unloadingPoint.isNotEmpty) {
        list = list
            .where((t) => t.unloadingPoints.any(
                (p) => p.toLowerCase().contains(unloadingPoint.toLowerCase())))
            .toList();
      }
      if (availableFrom != null) {
        list = list
            .where((t) =>
                t.availableFrom == null ||
                t.availableFrom!.isAfter(availableFrom) ||
                t.availableFrom!.isAtSameMomentAs(availableFrom))
            .toList();
      }

      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  Stream<List<TransportModel>> watchUserTransport(String userId) {
    return _transports
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(TransportModel.fromFirestore).toList());
  }

  Future<void> createTransport(TransportModel transport) async {
    try {
      if (transport.id.isEmpty) {
        await _transports.add(transport.toMap());
      } else {
        await _transports.doc(transport.id).set(transport.toMap());
      }
    } catch (e) {
      debugPrint('Error creating transport: $e');
      rethrow;
    }
  }

  Future<void> updateTransport(String id, Map<String, dynamic> data) async {
    try {
      await _transports.doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating transport: $e');
      rethrow;
    }
  }

  Future<void> deleteTransport(String id) async {
    try {
      await _transports.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting transport: $e');
      rethrow;
    }
  }

  Future<void> setTransportStatus(String id, String status) async {
    try {
      await _transports.doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting transport status: $e');
      rethrow;
    }
  }
}
