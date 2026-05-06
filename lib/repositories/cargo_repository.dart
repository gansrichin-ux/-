import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/config/cargo_statuses.dart';
import '../core/config/role_permissions.dart';
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
    // Write new canonical status; CargoModel.fromFirestore will normalise any legacy values on read
    await _cargos.doc(cargoId).update({
      'driverId': driverId,
      'driverName': driverName,
      'status': CargoStatus.executorSelected,
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

  /// Returns a real-time stream of active cargos visible to [user].
  /// Role matrix:
  ///   admin            – all cargos (no uid filter)
  ///   logistician      – ownerId == uid (manages own/corporate cargos)
  ///   cargo_owner      – ownerId == uid
  ///   driver/forwarder – driverId == uid
  ///   dual roles (driver+cargo_owner) – both sets merged client-side
  Stream<List<CargoModel>> watchActiveCargosForUser(UserModel user) {
    // Admin sees everything – no uid restriction
    if (RolePermissions.hasRole(user, RolePermissions.admin)) {
      return _cargos.snapshots().map(_toSortedActiveCargos);
    }

    final isDriver = RolePermissions.hasRole(user, RolePermissions.driver) ||
        RolePermissions.hasRole(user, RolePermissions.forwarder);
    final isOwner = RolePermissions.hasRole(user, RolePermissions.cargoOwner) ||
        RolePermissions.hasRole(user, RolePermissions.logistician);

    // Dual role: merge two streams client-side
    if (isDriver && isOwner) {
      final byDriver = _cargos
          .where('driverId', isEqualTo: user.uid)
          .snapshots()
          .map(_toSortedActiveCargos);
      final byOwner = _cargos
          .where('ownerId', isEqualTo: user.uid)
          .snapshots()
          .map(_toSortedActiveCargos);
      return byDriver.asyncExpand((driverCargos) {
        return byOwner.map((ownerCargos) {
          final merged = {...driverCargos, ...ownerCargos}.toList();
          merged.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return merged;
        });
      });
    }

    // Single role
    final Query<Map<String, dynamic>> query = isDriver
        ? _cargos.where('driverId', isEqualTo: user.uid)
        : _cargos.where('ownerId', isEqualTo: user.uid);

    return query.snapshots().map(_toSortedActiveCargos);
  }

  List<CargoModel> _toSortedActiveCargos(
      QuerySnapshot<Map<String, dynamic>> snap) {
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
  }

  Future<void> addPhotoUrl(String cargoId, String photoUrl) async {
    await _cargos.doc(cargoId).update({
      'photos': FieldValue.arrayUnion([photoUrl]),
    });
  }
}
