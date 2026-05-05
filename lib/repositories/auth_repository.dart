import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/services/notification_service.dart';
import '../core/services/otp_service.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// True when the user has confirmed their email via our 6-digit OTP code.
  Future<bool> isOtpVerified(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['emailCodeVerified'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Stream<UserModel?> watchCurrentUser() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield null;
        return;
      }

      await Future.delayed(const Duration(milliseconds: 800));

      yield* _firestore.collection('users').doc(user.uid).snapshots().asyncMap((
        doc,
      ) async {
        try {
          if (doc.exists) {
            final model = await _ensureUsername(
              UserModel.fromFirestore(doc),
              user,
            );
            return _withAdminAccess(model);
          }
          final model =
              await _loadUserModel(user).timeout(const Duration(seconds: 5));
          if (model != null) {
            return _withAdminAccess(model);
          }
          return null;
        } catch (_) {
          return null;
        }
      });
    });
  }

  Future<UserModel> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = cred.user!.uid;

    // Получаем данные пользователя асинхронно, но с таймаутом
    try {
      final userModel = await _loadUserModel(
        cred.user!,
      ).timeout(const Duration(seconds: 10));

      // Fire-and-forget: не блокируем вход ожиданием FCM-токена
      NotificationService.instance.saveToken(uid);

      return _withAdminAccess(
        userModel ?? _fallbackUser(cred.user!, emailFallback: email),
      );
    } catch (e) {
      return _withAdminAccess(_fallbackUser(cred.user!, emailFallback: email));
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String role,
    required String username,
    String? name,
    String? car,
  }) async {
    const validRoles = [
      'logistician', 'driver', 'forwarder', 'cargo_owner',
      'driver_forwarder', 'driver_cargo_owner'
    ];
    if (!validRoles.contains(role)) {
      throw ArgumentError('Недопустимая роль для регистрации');
    }

    final normalizedUsername = _normalizeUsername(username);

    // Проверяем имя пользователя до создания аккаунта
    final usernameRef = _firestore.collection('usernames').doc(normalizedUsername);
    final usernameDoc = await usernameRef.get();
    if (usernameDoc.exists) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'Имя пользователя @$normalizedUsername уже занято.',
      );
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final uid = cred.user!.uid;

    // Workaround for Firebase Web Race Condition where Firestore doesn't have the token yet.
    await cred.user?.getIdToken(true);
    await Future.delayed(const Duration(milliseconds: 1500));

    final user = UserModel(
      uid: uid,
      email: cred.user!.email ?? email,
      role: role,
      username: normalizedUsername,
      name: name?.trim(),
      car: car?.trim(),
    );

    try {
      int retries = 4;
      bool success = false;
      
      while (retries > 0 && !success) {
        try {
          final batch = _firestore.batch();

          batch.set(usernameRef, {
            'uid': uid,
            'username': normalizedUsername,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          batch.set(_firestore.collection('users').doc(uid), {
            'uid': uid,
            'role': role,
            'email': user.email,
            'username': normalizedUsername,
            'usernameLower': normalizedUsername,
            if (user.name?.isNotEmpty == true) 'name': user.name,
            if (user.car?.isNotEmpty == true) 'car': user.car,
            'ratingCount': 0,
            'ratingSum': 0,
            'emailCodeVerified': false,
          });

          await batch.commit().timeout(const Duration(seconds: 8));
          success = true;
        } catch (e) {
          if (e.toString().contains('permission-denied') && retries > 1) {
            retries--;
            await Future.delayed(const Duration(milliseconds: 1500));
            continue;
          }
          rethrow;
        }
      }
    } catch (error) {
      await cred.user?.delete();
      rethrow;
    }

    // 2. Распределяем по специальным коллекциям
    final collectionName = user.isDriver ? 'drivers' : 'logisticians';
    
    int collectionRetries = 3;
    while (collectionRetries > 0) {
      try {
        await _firestore
            .collection(collectionName)
            .doc(uid)
            .set(user.toMap())
            .timeout(const Duration(seconds: 5));
        break;
      } catch (e) {
        if (e.toString().contains('permission-denied') && collectionRetries > 1) {
          collectionRetries--;
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }

    NotificationService.instance.saveToken(uid);
    return user;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    await user.reload();
    final freshUser = _auth.currentUser;
    if (freshUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    if (freshUser.emailVerified) return;
    await freshUser.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      throw Exception('E-mail не указан');
    }
    await _auth.sendPasswordResetEmail(email: normalized);
  }

  Future<bool> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ── OTP verification ──────────────────────────────────────────────────────

  /// Generates a 6-digit code, stores in Firestore, and sends via Resend email.
  /// Returns null on success, or an error string.
  Future<String?> sendOtpCode(String uid, String email) async {
    return OtpService.instance.sendCode(uid, email);
  }

  /// Validates the entered code. Returns null on success, error string on fail.
  Future<String?> verifyOtpCode(String uid, String code) async {
    return OtpService.instance.verifyCode(uid, code);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _loadUserModel(user);
  }

  Future<UserModel?> _loadUserModel(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data() as Map<String, dynamic>;
    final role = data['role'] as String? ?? 'logistician';

    // Совместимость: если старый формат (все данные в 'users')
    if (data.containsKey('email') && data.length > 3) {
      final model =
          await _ensureUsername(UserModel.fromFirestore(userDoc), user);
      return _withAdminAccess(model);
    }

    final collectionName = role == 'driver' ? 'drivers' : 'logisticians';
    final doc = await _firestore.collection(collectionName).doc(user.uid).get();

    if (doc.exists) {
      final model = UserModel.fromFirestore(doc);
      final username = model.username?.isNotEmpty == true
          ? model.username!
          : _legacyUsername(user);
      await _firestore.collection('users').doc(user.uid).set({
        'uid': model.uid,
        'role': model.role,
        'email': model.email.isEmpty ? user.email ?? '' : model.email,
        'username': username,
        'usernameLower': username.toLowerCase(),
        if (model.name?.isNotEmpty == true) 'name': model.name,
        if (model.car?.isNotEmpty == true) 'car': model.car,
        'ratingCount': model.ratingCount,
        'ratingSum': model.ratingSum,
      }, SetOptions(merge: true));
      await _reserveUsername(username, user.uid);
      return _withAdminAccess(model.copyWith(username: username));
    }

    // Если в новой папке нет, берем из старой
    final model = await _ensureUsername(UserModel.fromFirestore(userDoc), user);
    return _withAdminAccess(model);
  }

  UserModel _fallbackUser(User user, {String? emailFallback}) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? emailFallback ?? '',
      role: 'logistician',
      username: _normalizeUsername(user.email ?? emailFallback ?? user.uid),
      name: user.displayName,
    );
  }

  String _normalizeUsername(String value) {
    final source = value.contains('@') ? value.split('@').first : value;
    final normalized = source
        .trim()
        .replaceFirst('@', '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_.]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    if (normalized.length >= 3) {
      return normalized.substring(
        0,
        normalized.length > 24 ? 24 : normalized.length,
      );
    }
    return '${normalized}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  Future<UserModel> _ensureUsername(UserModel model, User user) async {
    if (model.username?.isNotEmpty == true) return model;

    final username = _legacyUsername(user);
    final roleCollection = model.isDriver ? 'drivers' : 'logisticians';
    final updates = {
      'username': username,
      'usernameLower': username.toLowerCase(),
    };

    await _firestore.collection('users').doc(user.uid).set(
          updates,
          SetOptions(merge: true),
        );
    await _firestore.collection(roleCollection).doc(user.uid).set(
          updates,
          SetOptions(merge: true),
        );
    await _reserveUsername(username, user.uid);

    return model.copyWith(username: username);
  }

  Future<UserModel> _withAdminAccess(UserModel model) async {
    try {
      final doc = await _firestore
          .collection('adminAccounts')
          .doc(model.uid)
          .get()
          .timeout(const Duration(seconds: 4));
      final data = doc.data();
      if (doc.exists && data?['active'] == true) {
        return model.copyWith(role: 'admin');
      }
    } catch (_) {
      // Если проверка админ-доступа временно недоступна, оставляем обычную роль.
    }
    return model;
  }

  Future<void> _reserveUsername(String username, String uid) async {
    final ref = _firestore.collection('usernames').doc(username);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      final ownerId = doc.data()?['uid'] as String?;
      if (doc.exists && ownerId != uid) return;

      transaction.set(
          ref,
          {
            'uid': uid,
            'username': username,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    });
  }

  String _legacyUsername(User user) {
    return _normalizeUsername('u_${user.uid}');
  }
}
