import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/config/cargo_statuses.dart';
import '../core/services/cargo_photo_uploader.dart';
import '../models/cargo_model.dart';
import '../models/user_model.dart';
class CargoRepository {
  CargoRepository._();
  static final CargoRepository instance = CargoRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _cargos =>
      _firestore.collection('cargos');

  // --- Streams ---

  Stream<List<CargoModel>> watchAllCargos({String? ownerId}) {
    Query<Map<String, dynamic>> query = _cargos;
    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    return query.limit(80).snapshots().map((snap) {
      final cargos = snap.docs.map(CargoModel.fromFirestore).toList();
      cargos.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return cargos;
    });
  }

  Stream<List<CargoModel>> watchDriverCargos(String driverId) {
    return _cargos
        .where('driverId', isEqualTo: driverId)
        .limit(80)
        .snapshots()
        .map((snap) {
      final cargos = snap.docs.map(CargoModel.fromFirestore).toList();
      cargos.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return cargos;
    });
  }

  Stream<List<CargoModel>> watchNewCargos({String? ownerId}) {
    Query<Map<String, dynamic>> query = _cargos;
    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    return query.limit(80).snapshots().map((snap) {
      final cargos = snap.docs
          .map(CargoModel.fromFirestore)
          .where((cargo) => cargo.status == CargoStatus.published)
          .toList();
      cargos.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return cargos;
    });
  }

  /// Свободные грузы — статус 'Новый' и без назначенного водителя.
  Stream<List<CargoModel>> watchAvailableCargos({String? ownerId}) {
    Query<Map<String, dynamic>> query = _cargos;
    if (ownerId != null) {
      query = query.where('ownerId', isEqualTo: ownerId);
    }

    return query.limit(80).snapshots().map((snap) {
      final cargos = snap.docs
          .map(CargoModel.fromFirestore)
          .where((cargo) => cargo.status == CargoStatus.published && cargo.driverId == null)
          .toList();
      cargos.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return cargos;
    });
  }

  Stream<CargoModel?> watchCargo(String cargoId) {
    return _cargos.doc(cargoId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CargoModel.fromFirestore(doc);
    });
  }

  // --- Queries ---

  Future<CargoModel?> getCargo(String cargoId) async {
    final doc = await _cargos.doc(cargoId).get();
    if (!doc.exists) return null;
    return CargoModel.fromFirestore(doc);
  }

  // --- Mutations ---

  Future<void> addCargo(CargoModel cargo) async {
    await _cargos.add(cargo.toFirestoreMap());
  }

  Future<void> assignDriver({
    required String cargoId,
    required String driverId,
    required String driverName,
  }) async {
    await _cargos.doc(cargoId).update({
      'driverId': driverId,
      'driverName': driverName,
      'status': 'В работе',
    });
  }

  Future<void> updateStatus(String cargoId, String status) async {
    await _cargos.doc(cargoId).update({'status': status});
  }

  Future<String> uploadPhoto(
    String cargoId,
    Object file,
    String fileName,
  ) async {
    final ref = _storage.ref().child('cargos/$cargoId/$fileName');
    return uploadCargoPhoto(ref, file);
  }

  Stream<List<CargoModel>> watchActiveCargosForUser(UserModel user) {
    Query<Map<String, dynamic>> query = _cargos;

    if (user.role == 'driver') {
      query = query.where('driverId', isEqualTo: user.uid);
    } else {
      query = query.where('ownerId', isEqualTo: user.uid);
    }

    return query.snapshots().map((snap) {
      final cargos = snap.docs
          .map(CargoModel.fromFirestore)
          .where((cargo) => cargo.isActive)
          .toList();
      cargos.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return cargos;
    });
  }

  Future<void> addPhotoUrl(String cargoId, String photoUrl) async {
    await _cargos.doc(cargoId).update({
      'photos': FieldValue.arrayUnion([photoUrl]),
    });
  }
}
