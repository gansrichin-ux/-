import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cargo_model.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<UserModel>> watchAllUsers() {
    return _firestore.collection('users').snapshots().map((snap) {
      final users = snap.docs.map(UserModel.fromFirestore).toList();
      users.sort((a, b) => a.displayName.compareTo(b.displayName));
      return users;
    });
  }

  Stream<List<UserModel>> watchDrivers() {
    return _firestore
        .collection('drivers')
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  Stream<List<UserModel>> watchLogisticians() {
    return _firestore
        .collection('logisticians')
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<Set<String>> watchFavoriteCargoIds(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favoriteCargos')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  Future<void> toggleFavoriteCargo({
    required String uid,
    required CargoModel cargo,
    required bool favorite,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('favoriteCargos')
        .doc(cargo.id);

    if (!favorite) {
      await ref.delete();
      return;
    }

    await ref.set({
      'cargoId': cargo.id,
      'title': cargo.title,
      'from': cargo.from,
      'to': cargo.to,
      'status': cargo.status,
      'ownerId': cargo.ownerId,
      'driverId': cargo.driverId,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> uploadProfilePhoto({
    required UserModel user,
    required XFile file,
  }) async {
    final fileName = _safeFileName(file.name);
    final detectedMimeType = file.mimeType ?? _guessImageMimeType(fileName);
    final mimeType = detectedMimeType.startsWith('image/')
        ? detectedMimeType
        : _guessImageMimeType(fileName);
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Файл пустой или не удалось прочитать изображение');
    }
    final ref = _storage.ref().child(
          'users/${user.uid}/avatar_${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );
    final snapshot = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: mimeType,
        cacheControl: 'public,max-age=60',
        customMetadata: {'ownerId': user.uid, 'kind': 'profile-avatar'},
      ),
    );
    return snapshot.ref.getDownloadURL();
  }

  Future<String?> updateProfile({
    required UserModel user,
    required String name,
    required String aboutMe,
    String? car,
    XFile? avatar,
  }) async {
    final avatarUrl = avatar == null
        ? null
        : await uploadProfilePhoto(user: user, file: avatar);
    final updatedUser = user.copyWith(
      name: name.trim(),
      aboutMe: aboutMe.trim(),
      car: user.isDriver ? (car ?? '').trim() : user.car,
      avatarUrl: avatarUrl ?? user.avatarUrl,
    );
    final completeness = updatedUser.calculatedProfileCompletenessPercent;
    final nextProfileStatus = user.profileStatus == 'verified'
        ? 'verified'
        : completeness >= 90
            ? 'pending_review'
            : 'profile_incomplete';
    final updates = {
      'name': name.trim(),
      'aboutMe': aboutMe.trim(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (avatarUrl != null) 'photoURL': avatarUrl,
      if (avatarUrl != null) 'avatarUpdatedAt': FieldValue.serverTimestamp(),
      if (user.isDriver) 'car': (car ?? '').trim(),
      'profileCompletenessPercent': completeness,
      'profileStatus': nextProfileStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final roleData = {
      ...updates,
      'uid': user.uid,
      'email': user.email,
      'role': user.role,
      'roles': user.roles.isEmpty ? [user.role] : user.roles,
    };

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('users').doc(user.uid),
      updates,
      SetOptions(merge: true),
    );
    batch.set(
      _firestore
          .collection(user.isDriver ? 'drivers' : 'logisticians')
          .doc(user.uid),
      roleData,
      SetOptions(merge: true),
    );

    await batch.commit();

    final authUser = FirebaseAuth.instance.currentUser;
    if (avatarUrl != null && authUser?.uid == user.uid) {
      await authUser!.updatePhotoURL(avatarUrl);
    }

    return avatarUrl;
  }

  Future<void> updateOnboarding({
    required String uid,
    required bool completed,
    required int step,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'onboardingCompleted': completed,
      'onboardingStep': step.clamp(0, 4),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> rateUser({
    required UserModel target,
    required String raterId,
    required int score,
  }) async {
    final safeScore = score.clamp(1, 5);
    final userRef = _firestore.collection('users').doc(target.uid);
    final ratingRef = userRef.collection('ratings').doc(raterId);
    final roleCollection = target.isDriver ? 'drivers' : 'logisticians';
    final roleRef = _firestore.collection(roleCollection).doc(target.uid);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      final ratingDoc = await transaction.get(ratingRef);
      final current = UserModel.fromFirestore(userDoc);
      final previousScore = ratingDoc.exists
          ? ((ratingDoc.data()?['score'] as num?)?.toInt() ?? 0)
          : 0;

      final nextCount = current.ratingCount + (ratingDoc.exists ? 0 : 1);
      final nextSum = current.ratingSum - previousScore + safeScore;
      final ratingData = {
        'score': safeScore,
        'raterId': raterId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final aggregateData = {'ratingCount': nextCount, 'ratingSum': nextSum};

      transaction.set(ratingRef, ratingData, SetOptions(merge: true));
      transaction.set(userRef, aggregateData, SetOptions(merge: true));
      transaction.set(roleRef, aggregateData, SetOptions(merge: true));
      transaction.set(_firestore.collection('siteNotifications').doc(), {
        'userId': target.uid,
        'title': 'Новая оценка',
        'body': 'Вам поставили $safeScore из 5',
        'type': 'rating',
        'relatedId': raterId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  String _safeFileName(String value) {
    final name = value.trim().isEmpty ? 'avatar.jpg' : value.trim();
    return name
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  String _guessImageMimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
